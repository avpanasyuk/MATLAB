#include "mex.h"
#include "matrix.h"

typedef unsigned char uint8_t ;

void mexFunction(
int nlhs, mxArray *plhs[],
int nrhs, const mxArray *prhs[]) {
	if (nrhs != 1) mexErrMsgTxt("One input argument - uint8 array - is required!");
	const mxArray *A = prhs[0];
	mwSize OutSize[2] = {1,1};
	plhs[0] = mxCreateNumericArray(2, OutSize, mxUINT8_CLASS, 0);
	if(mxGetClassID(A) != mxUINT8_CLASS) mexErrMsgTxt("Array should be uint8");
	uint8_t *pData = (uint8_t *)mxGetData(A);
	mwSize Sz = mxGetNumberOfElements(A);

    uint8_t XORvalue = 0;
    while(Sz--) XORvalue ^= *(pData++);
    *((uint8_t *)mxGetData(plhs[0])) = XORvalue;
  } // checksum
	
