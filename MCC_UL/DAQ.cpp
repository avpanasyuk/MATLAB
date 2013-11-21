#include <cbw.h>
#include <mex.h>
#include <matrix.h>
#include <AVP/Matlab.hpp>
#include <AVP/Error.hpp>
#include <AVP/Service.hpp>

using AVP::Error;

#define ASSERT_UL(op) {int Status = (op); if (Status != 0) { \
  char ErrMsg[ERRSTRLEN]; cbGetErrMsg(Status,ErrMsg); \
	AVP_ERRORF("UL error:%s",ErrMsg);}}

static mxArray *pBufArray;
static int Range = BIP10VOLTS; // default
typedef struct TableEntry {char *name; int value; };


void mexFunction(int nlhs, mxArray* plhs[], 
								 int nrhs, const mxArray* prhs[] ) { 
  float    RevLevel = (float)CURRENTREVNUM;
	
  try {
    // Check whether this program is compatible with installed library
    ASSERT_UL(cbDeclareRevision(&RevLevel));

    // Standard thing - help
    if(nrhs == 0) {
      mexPrintf("USAGE: %s(command,parameters....), where COMMAND is one of:\n"
								"\t'FlashLED'. Initiates board, blinks board LED.\n"
								"\t'AIn',channel,range\n"
								"\t'in',channel[,range = 20|10|5|4|2.5|2|1.25|1].\n"
								"\t\tIf RANGE is omitted, input is considered single-ended,\n"
								"\t\t0-10V, available channels 0-7.\n"
								"\t\tIf RANGE is specified, input is differential, channels 0-3\n",
								mexFunctionName());
      return;
    }
    
    const int BoardNum = 0;
# define STR_BUF_LEN 50
    char StrBuffer[STR_BUF_LEN+1];
    
    if(mxGetString(prhs[0],StrBuffer,STR_BUF_LEN) != 0)
      AVP_ERROR("Type of COMMAND parameter is not string");
    nrhs--; prhs++; // parsed COMMAND  

#define GET_PAR(type,name) if(!nrhs) AVP_ERROR("Missing parameter " #name); \
		type name = AVP::mxArrayToType<type>(prhs[0]); nrhs--; prhs++

    if(stricmp(StrBuffer,"FlashLED") == 0) {
      ASSERT_UL(cbFlashLED(BoardNum));
    } else { // for the follwoing command the first parameter is CHANNEL
      if(stricmp(StrBuffer,"SetTrigger") == 0) {
				GET_PAR(double, TriggerType); 
				ASSERT_UL(cbSetTrigger
									(BoardNum,TriggerType > 0?TRIG_POS_EDGE:TRIG_NEG_EDGE,0,0));
      } else if(stricmp(StrBuffer,"SetRange") == 0) { // SetRange command
				if(mxGetString((prhs++)[0],StrBuffer,STR_BUF_LEN) != 0)
					AVP_ERROR("Type of RANGE parameter is not string");
				nrhs--;

				// FOLLOWING SEVERAL MACROS ARE DEALING WITH TABLES 
#define ENTRY(name) {#name,name}
#define SCAN_TABLE(table,OutVar) {																			\
					for(const TableEntry *p = table;															\
							stricmp(StrBuffer,p->name) != 0; ++p)											\
						if(p == table + N_ELEMENTS(table) - 1)											\
							AVP_ERRORF("Can not recognize range %s",StrBuffer);				\
					OutVar = p->value; }
	
				const TableEntry RangeTable[] = {
					ENTRY(BIP10VOLTS), ENTRY(BIP20VOLTS), ENTRY(BIP5VOLTS), 
					ENTRY(BIP4VOLTS), ENTRY(BIP2PT5VOLTS), ENTRY(BIP1PT25VOLTS), 
					ENTRY(BIP1VOLTS), ENTRY(UNI10VOLTS)};
	
				SCAN_TABLE(RangeTable, Range);
			} else if(stricmp(StrBuffer,"GetStatus") == 0) {
				short IOStatus;
				long CurCount, CurIndex;
	      
				ASSERT_UL(cbGetStatus(BoardNum, &IOStatus, &CurCount, &CurIndex, 
															AIFUNCTION));
				plhs[0] = AVP::Create_mxArray(mxINT8_CLASS);
				*(short *)mxGetData(plhs[0])	= (IOStatus == RUNNING);
			} else if(stricmp(StrBuffer,"GetResult") == 0) {
				AVP_ASSERT(pBufArray != NULL);
				plhs[0] = pBufArray;
				pBufArray = NULL;
			} else {// other commands
				GET_PAR(int, Channel);      
				if(stricmp(StrBuffer,"AIn") == 0) {            //// Ain //////
					plhs[0] = AVP::Create_mxArray(mxUINT16_CLASS);
					ASSERT_UL(cbAIn(BoardNum,Channel,Range,
													(u_short *)mxGetData(plhs[0])));
				} else if(stricmp(StrBuffer,"AInScan") == 0) { //// AInScan //////
					// read the rest of parameters
					GET_PAR(int, LastChannel);
					GET_PAR(long, Count);
					GET_PAR(long, Rate);
					// rest of parameters are options
					int Options = 0;

#define CHECK_OPTION(name) if(stricmp(StrBuffer,#name)) Options += name
	  
					while(nrhs--) {
						int CurOption;
						if(mxGetString((prhs++)[0],StrBuffer,STR_BUF_LEN) != 0)
							AVP_ERROR("Type of OPTION parameter is not string"); 
						const TableEntry OptionTable[] = 
							{ENTRY(BACKGROUND), ENTRY(EXTCLOCK), ENTRY(EXTTRIGGER)};
						SCAN_TABLE(OptionTable, CurOption);
						Options |= CurOption;
					} // went through options
					// allocate buffer
					AVP_ASSERT(pBufArray == NULL);
					pBufArray = AVP::Create_mxArray(mxUINT16_CLASS,1,int(Count));
					ASSERT_UL(cbAInScan(BoardNum, Channel, LastChannel, Count, &Rate, 
															Range, (HGLOBAL)mxGetData(pBufArray), 
															Options | BACKGROUND));
					// we always specify BACKGROUND, so MATLAB never hangs for long
					if((Options & BACKGROUND) == 0) { // will wait for data
						while(1) {
							short IOStatus;
							long CurCount, CurIndex;
	      
							ASSERT_UL(cbGetStatus(BoardNum, &IOStatus, &CurCount, &CurIndex, 
																		AIFUNCTION));
							if(IOStatus == IDLE) break;
							AVP_ASSERT(mexCallMATLAB(0,NULL,0, NULL, "drawnow") == 0);
						}
						// got data
						plhs[0] = pBufArray;
						pBufArray = NULL;
					} // exit without returning data
				} // AinScan
      }
    }
  } catch (Error Err) { mexErrMsgTxt(Err); }
  return;
}

  
