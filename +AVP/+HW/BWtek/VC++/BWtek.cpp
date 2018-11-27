/*************************************************************************
 *
 * Project:     OxyVu
 * Module:		q:/panas/Programs/C++/General/Lib/
 * File:        SMX150.cpp
 * Created:     panasyuk - Jul 05, 1999: 
 * Author:      Alexander Panasyuk
 ************************************************************************/

#include <mex.h>
#include <matrix.h>
#include "bwtekusb.h"
#include <AVP/General.hpp>
#include <AVP/Matlab.hpp>
#include <AVP/Error.hpp>

using AVP::Error;

static void ExitFunction(void) { bwtekCloseUSB(0); }

void mexFunction (int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) {
	if(nrhs == 0) {
		mexPrintf("BWtek spectrometer module v0.0.2 by Alexander Panasyuk\n"
			"CALL: [spectrum exposure wavelengths] = %s([exposure]).\n"
			"\t If exposure is not specified it is the same as in previous call.\n",
			mexFunctionName()); 
		return;
	}

	try {
		const double wl_coeffs[4] = {-2.67724383431954E-10,-3.93006004601459E-5,
			0.295499074046802,342.712719439995}; // from para.ini file
		const int PIXNUM = 2048;
		static bool Initiated = false;
		static double wl[PIXNUM];
		static long Exposure; // to preserve value between calls
		
		if(!Initiated) {
			AVP_ASSERT(bwtekTestUSB(1,PIXNUM,1,0,0)>0);
			mexAtExit(ExitFunction); 
			for(int i=0; i < PIXNUM; i++) {
				double x=i;
				for(int c=0; c < N_ELEMENTS(wl_coeffs);c++)
					wl[i] = wl[i]*x + wl_coeffs[c];
			}
			AVP_ASSERT((Exposure = bwtekSetTimeUSB(9,0)) > 0); // set minimal exposure
			Initiated = true;
		}

		plhs[0] = mxCreateNumericMatrix(PIXNUM,1,mxUINT16_CLASS,mxREAL); // we always need array
		double Param;

		if(nlhs != 0 && AVP::mxGetDouble(prhs[0],&Param)) { // see if first Exposureeter is a exposure
			AVP_ASSERT((Exposure = bwtekSetTimeUSB(long(Param),0)) > 0);
		}
		AVP_ASSERT(bwtekDataReadUSB(0,(u_short *)mxGetData(plhs[0]),0) == PIXNUM);
		if(nlhs > 1) {
			plhs[1] = mxCreateNumericMatrix(1,1,mxUINT16_CLASS,mxREAL);
			*(u_short *)mxGetData(plhs[1]) = u_short(Exposure);
		}
		if(nlhs > 2) {
			plhs[2] = mxCreateNumericMatrix(PIXNUM,1,mxDOUBLE_CLASS,mxREAL);
			memcpy(mxGetData(plhs[2]),wl,sizeof(wl));
		}


	} catch (Error Err) { mexErrMsgTxt(Err); }
}



#if 0
		const int CMD_NAME_LEN = 50;
		char CurCmdName[CMD_NAME_LEN+1];

		if(mxGetString(prhs[0],CurCmdName,CMD_NAME_LEN) == 0) { // first Exposureeter is a command
			if(stricmp(CurCmdName,"auto") == 0) {
				while(1) {
					AVP_ASSERT(bwtekDataReadUSB(0,Buffer,0) == PIXNUM);
					u_short MaxCount = *AVP::FindPositiveMax(Buffer,PIXNUM);
					if(MaxCount == 65535) 
						AVP_ASSERT((Exposure = bwtekSetTimeUSB(Exposure/4,0)) > 0)
					else if(MaxCount < 32000)
						AVP_ASSERT((Exposure = bwtekSetTimeUSB(Exposure*48000/MaxCount,0)) > 0)
					else break;
				}
			} else AVP_ERRORF("Command '%s' is not recognized!", CurCmdName);
		} else { // FIRST Exposureeter is not string, probably DeviceID
			double Param;

			if(AVP::mxGetDouble(prhs[0],&Param)) { // see if first Exposureeter is a exposure
				AVP_ASSERT((Exposure = bwtekSetTimeUSB(long(Param),0)) > 0);
			}
		}

		AVP_ASSERT(bwtekDataReadUSB(0,(u_short *)mxGetData(plhs[0]),0) == PIXNUM);
		if(nlhs > 1) {
			plhs[1] = mxCreateNumericMatrix(1,1,mxUINT16_CLASS,mxREAL);
			*(u_short *)mxGetData(plhs[1]) = u_short(Exposure);
		}
		if(nlhs > 2) {
			plhs[2] = mxCreateNumericMatrix(PIXNUM,1,mxDOUBLE_CLASS,mxREAL);
			memcpy(mxGetData(plhs[2]),wl,sizeof(wl));
		}
#endif			
#if 0
		if(mxGetString(prhs[0],CurCmdName,CMD_NAME_LEN) == 0) { // first Exposureeter is a command
			if(stricmp(CurCmdName,"auto") == 0) {
			} else AVP_ERRORF("Command '%s' is not recognized!", CurCmdName);
		} else { // FIRST Exposureeter is not string, probably DeviceID
			double Exposure;

			if(AVP::mxGetDouble(prhs[0],&Exposure)) { // see if first Exposureeter is a
				// number, then second should be a command
				if((nrhs < 2) || (mxGetString(prhs[1],CurCmdName,CMD_NAME_LEN) != 0)) 
				AVP_ERROR("Second Exposureeter should be a command string!");

				// close is a special case
				if(stricmp(CurCmdName,"close") == 0) delete Camera::Find((int)Exposure);
				else Camera::Find((int)Exposure)->Process(CurCmdName,nlhs,plhs,nrhs-1,prhs+1);
			} else AVP_ERROR("What is it with the first Exposureeter?");
		}
#endif	
