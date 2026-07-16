// CAboutDlg dialog used for App About
#define DLLIMPORT extern "C" __declspec(dllimport)
#define CALLINGWAY __stdcall

struct RS232Params
{unsigned short nPort; //1 for Com1, 2 for com2 ,…
unsigned short nBautRate; //9600, 38400 or 115200
unsigned short nAverage; //number of data to be averaged
unsigned short nTimeDelay; //time delay for a scan
unsigned short nReserve; //reserved for future use
double fCoefficient[4]; //coefficient for wavelength calibration
};

DLLIMPORT int CALLINGWAY bwtekTestUSB
(int nUSBTiming, // USB Interface timing option
int nPixelNo, // number of pixels of a detector to be readout
int nInputMode, // signal conditioning stage gain value
int nchannel, // channel to get data from
double *pParam // extra setting parameters only for RS232
);

DLLIMPORT int CALLINGWAY bwtekSetTimeUSB(long  lTime, int nChannel);
DLLIMPORT int CALLINGWAY bwtekDataReadUSB(int  nTriggerMode, unsigned short* pArray, int nChannel);
DLLIMPORT int CALLINGWAY bwtekCloseUSB(int nChannel);

DLLIMPORT int CALLINGWAY bwtekReadEEPROMUSB
(char *OutFileName, // The filename in which data from EEPROM would be saved
int nChannel // channel number to get data from
);

DLLIMPORT int CALLINGWAY bwtekSetTimingsUSB
(long lTriggerExit,// Setting external trigger timeout
int nMultiple, // A multifly factor for long integration time
int nChannel //channel number to get data from
);

DLLIMPORT int CALLINGWAY bwtekPolyFit
(double * x, // Array of independent variables
double * y, // Array of dependent variables
int const numPts, // Number of points in independent and dependent arrays
double * coefs, // Pointer to array containing calculated coefficients [index from 0 to order]
int const order // Desired order of polynomial fit
);

DLLIMPORT void CALLINGWAY bwtekPolyCalc
(double * coefs,
int const order,
int const x,
double * y);


