#define BLOWFISH_BLOCKSIZE	8 
#define S_ROWS				4
#define S_COLUMNS			256	

#define GET_UINT32_BE(n,b,i)						\
{													\
    (n) = ( (unsigned int) (b)[(i)    ] << 24 )		\
        | ( (unsigned int) (b)[(i) + 1] << 16 )		\
        | ( (unsigned int) (b)[(i) + 2] <<  8 )		\
        | ( (unsigned int) (b)[(i) + 3]       );	\
}

#define PUT_UINT32_BE(n,b,i)						\
{													\
    (b)[(i)    ] = (unsigned char) ( (n) >> 24 );	\
    (b)[(i) + 1] = (unsigned char) ( (n) >> 16 );	\
    (b)[(i) + 2] = (unsigned char) ( (n) >>  8 );	\
    (b)[(i) + 3] = (unsigned char) ( (n)       );	\
}

static unsigned int F(__global const unsigned int *S, unsigned int x)
{
	unsigned short a, b, c, d;
	unsigned int  y;

	d = (unsigned short)(x & 0xFF);
	x >>= 8;
	c = (unsigned short)(x & 0xFF);
	x >>= 8;
	b = (unsigned short)(x & 0xFF);
	x >>= 8;
	a = (unsigned short)(x & 0xFF);
	y = S[0 * S_COLUMNS + a] + S[1 * S_COLUMNS + b];
	y = y ^ S[2 * S_COLUMNS + c];
	y = y + S[3 * S_COLUMNS + d];

	return(y);
}


__kernel void blowfish_encrypt(__global const unsigned char* inputText, __global const unsigned int* P, __global const unsigned int* S,
	__global unsigned char* outputText, unsigned long int fileLength, unsigned long int numberOfThreads)
{
	unsigned long int id = get_global_id(0);

	uchar inputBlock[8] = { ' ' };
	uchar outputBlock[8] = { ' ' };

	if (id < fileLength / 8)
	{
		unsigned long int block_id = id * 8;

		// input block preparation
		for (int j = 0; j < 8; ++j)
		{
			inputBlock[j] = inputText[block_id + j];
		}

		unsigned int  Xl, Xr, temp;
		short i;
		GET_UINT32_BE(Xl, inputBlock, 0);
		GET_UINT32_BE(Xr, inputBlock, 4);

		for (i = 0; i < BLOWFISH_ROUNDS; ++i)
		{
			Xl = Xl ^ P[i];
			Xr = F(S, Xl) ^ Xr;
			temp = Xl;
			Xl = Xr;
			Xr = temp;
		}

		temp = Xl;
		Xl = Xr;
		Xr = temp;
		Xr = Xr ^ P[BLOWFISH_ROUNDS];
		Xl = Xl ^ P[BLOWFISH_ROUNDS + 1];
		PUT_UINT32_BE(Xl, outputBlock, 0);
		PUT_UINT32_BE(Xr, outputBlock, 4);

		// output text preparation
		for (int j = 0; j < 8; ++j)
		{
			outputText[block_id + j] = outputBlock[j];
		}
	}
}
