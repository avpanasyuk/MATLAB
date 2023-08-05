classdef AnalogDiscovery1 < handle
  %> daq toolbox version of this sucks!
  %> that's my version based on DIGILENT's DLL library
  %> everything is from "C:\Program Files (x86)\Digilent\WaveFormsSDK\WaveForms SDK Reference Manual.pdf"
  %> but not everything from there is implemented
  properties
    h % handle
    SampleFreqRange
    BufferSizeRange
    VoltsRange
    VoltsSteps
    RangeSets
    OffsetRange
    OffsetSteps
    TrigPosRange_s
    TrigPosSteps
    TrigTOrange_s
    TrigTOsteps
    TrigHO_s
    TrigHOsteps
    TrigLevelRange
    TrigLevelSteps
  end

  methods
    function a = AnalogDiscovery1()
      if ~libisloaded('dwf')
        hfile = 'C:\Program Files (x86)\Digilent\WaveFormsSDK\inc\dwf.h';
        addpath('c:\Program Files (x86)\Digilent\WaveFormsSDK\lib\x64\');
        loadlibrary('dwf', hfile);
      end

      if ~libisloaded('dwf'), error('Library failed to load!'); end

      display(['Version: ' AVP.HW.AnalogDiscovery1.GetVersion()]);

      a.h = AVP.HW.AnalogDiscovery1.DeviceOpen();
      a.DeviceAutoConfigureSet(3);
      a.DeviceReset();
      a.AnalogInFrequencyInfo();
      a.AnalogInBufferSizeInfo();
      a.AnalogInChannelRangeInfo();
      a.AnalogInChannelRangeSteps();
      a.AnalogInChannelOffsetInfo();
      a.AnalogInTriggerPositionInfo();
      a.AnalogInTriggerAutoTimeoutInfo();
      a.AnalogInTriggerHoldOffInfo();
      a.AnalogInTriggerLevelInfo();
    end % constructor

    function delete(a), a.DeviceClose(); end

    function DeviceAutoConfigureSet(a,AutoConfigure), a.Call(AutoConfigure); end
    function DeviceReset(a), a.Call(); end
    function AnalogInReset(a), a.Call(); end
    function AnalogInConfigure(a), a.Call(false, true); end

    %% sample frequency functions
    function AnalogInFrequencyInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      a.Call(pmin,pmax);
      a.SampleFreqRange = [pmin.Value, pmax.Value];
    end % AnalogInFrequencyInfo
    function AnalogInFrequencySet(a,Freq_Hz), a.Call(Freq_Hz); end
    function freq = AnalogInFrequencyGet(a), freq = a.GetValue('double'); end

    function AnalogInBufferSizeInfo(a)
      pmin = libpointer('int32Ptr',0);
      pmax = libpointer('int32Ptr',0);
      a.Call(pmin,pmax);
      a.BufferSizeRange = [pmin.Value, pmax.Value];
    end % AnalogInBufferSizeInfo
    function AnalogInBufferSizeSet(a,sz), a.Call(sz); end

    function modes = AnalogInAcquisitionModeInfo(a)
      bitField =  a.GetValue('int32');
      modes = '';
      if bitand(bitField, bitshift(1,a.acqmodeSingle)), modes = [modes 'Single ']; end
      if bitand(bitField, bitshift(1,a.acqmodeScanShift)), modes = [modes 'ScanShift ']; end
      if bitand(bitField, bitshift(1,a.acqmodeScanScreen)), modes = [modes 'ScanScreen ']; end
      if bitand(bitField, bitshift(1,a.acqmodeRecord)), modes = [modes 'Record ']; end
      if bitand(bitField, bitshift(1,a.acqmodeSingle1)), modes = [modes 'Single1 ']; end
    end % AnalogInAcquisitionModeInfo
    function AnalogInAcquisitionModeSet(a,mode), a.Call(mode); end %> @param mode from acqmode

    function Nbits = AnalogInBitsInfo(a), Nbits = a.GetValue('int32'); end

    %% AnalogInStatus FUNCTIONS
    function status = AnalogInStatus(doReadData)
      p = libpointer('uint8Ptr',0);
      a.Call(doReadData,p);
      status = p.Value;
    end % AnalogInFrequencyGet

    % Note:  To ensure consistency between device status and measured data, the following AnalogInStatus*functions
    % do not communicate with the device. These functions only return information and data from the last
    % AnalogInStatus call.
    function Num = AnalogInStatusSamplesLeft(a), Num = a.GetValue('int32'); end
    function Num = AnalogInStatusSamplesValid(a), Num = a.GetValue('int32'); end
    function index = AnalogInStatusIndexWrite(a), Index = a.GetValue('int32'); end

    function data = AnalogInStatusData2(a,ChI,sz,FromIndex)
      %> geta data in volts
      if ~exist('FromIndex','var'), FromIndex = 0; end
      p = libpointer('doublePtr',zeros(sz,1));
      a.Call(ChI,p,sz);
      data = p.Value;
    end % AnalogInStatusData

    function data = AnalogInStatusData16(a,ChI,sz,FromIndex)
      %> gets raw data
      if ~exist('FromIndex','var'), FromIndex = 0; end
      p = libpointer('int16Ptr',zeros(sz,1));
      a.Call(ChI,p,sz);
      data = p.Value;
    end % AnalogInStatusData16

    %% RECORD functions
    function [Available, Lost, Corrupt] = AnalogInStatusRecord(a)
      %> Retrieves information about the recording process. The data loss occurs when the device acquisition
      %> is faster than the read process to PC. In this case, the device recording buffer is filled and data
      %> samples are overwritten. Corrupt samples indicate that the samples have been overwritten by the
      %> acquisition process during the previous read. In this case, try optimizing the loop process for faster
      %> execution or reduce the acquisition frequency or record length to be less than or equal to the device
      %> buffer size (record length <= buffer size/frequency).
      pAvailable = libpointer('int32Ptr',0);
      pLost = libpointer('int32Ptr',0);
      pCorrupt = libpointer('int32Ptr',0);
      a.Call(pAvailable, pLost, pCorrupt);
      Available = pAvailable.Value;
      Lost = pList.Value;
      Corrupt = pCorrupt.Value;
    end
    function AnalogInRecordLengthSet(a,l_seconds), a.Call(l_seconds); end
    function l_seconds = AnalogInRecordLengthGet(a), l_seconds = a.GetValue('double'); end

    %% SAMPLING functions
    function AnalogInSamplingSourceSet(a,trigsrc), a.Call(trigsrc); end
    function AnalogInSamplingSlopeSet(a,TriggerSlope), a.Call(TriggerSlope); end
    function AnalogInSamplingDelaySet(a, sec), a.Call(sec); end

    %% CHANNELS functions
    function Num = AnalogInChannelCount(a), Num = a.GetValue('int32'); end
    function AnalogInChannelEnableSet(a,ChI,doEnable), a.Call(ChI,doEnable); end
    function filters = AnalogInChannelFilterInfo(a)
      bitField =  a.GetValue('int32');
      filters = '';
      if bitand(bitField, bitshift(1,a.filterDecimate)), filters = [filters 'Decimate ']; end
      if bitand(bitField, bitshift(1,a.filterAverage)), filters = [filters 'Average ']; end
      if bitand(bitField, bitshift(1,a.filterMinMax)), filters = [filters 'MinMax ']; end
    end % AnalogInChannelFilterInfo
    function AnalogInChannelFilterSet(a,ChI,filter)
      %> if ChI = -1 works on all enabled channels
      a.Call(ChI,filter);
    end % AnalogInChannelFilterSet

    function AnalogInChannelRangeInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.VoltsRange(1) = pmin.Value;
      a.VoltsRange(2) = pmax.Value;
      a.VoltsSteps = psteps.Value;
    end % AnalogInChannelRangeInfo

    function AnalogInChannelRangeSteps(a)
      p = libpointer('doublePtr',zeros(32,1));
      psteps = libpointer('int32Ptr',0);
      a.Call(p, psteps);
      a.VoltsSteps = psteps.Value;
      a.RangeSets = p.Value(1:a.VoltsSteps);
    end

    function AnalogInChannelRangeSet(a, ChI, RangeSet), a.Call(ChI, RangeSet); end
    function Range = AnalogInChannelRangeGet(a,ChI)
      p = libpointer('doublePtr',0);
      a.Call(ChI,p);
      Range = p.Value;
    end % AnalogInChannelRangeGet

    function AnalogInChannelOffsetInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.OffsetRange(1) = pmin.Value;
      a.OffsetRange(2) = pmax.Value;
      a.OffsetSteps = psteps.Value;
    end % FDwfAnalogInChannelOffsetInfo

    function AnalogInChannelOffsetSet(a, ChI, Offset), a.Call(ChI, Offset); end
    function Offset = AnalogInChannelOffsetGet(a, ChI)
      p = libpointer('doublePtr',0);
      a.Call(ChI,p);
      Offset = p.Value;
    end % AnalogInChannelOffsetGet

    %% ANALOG I/O - internal measurements
    function Num = AnalogIOChannelCount(a), Num = a.GetValue('int32'); end
    function [Name, Label] = AnalogIOChannelName(a, ChI)
      pName = libpointer('int8Ptr',zeros(32,1));
      pLabel = libpointer('int8Ptr',zeros(32,1));
      a.Call(ChI, pName, pLabel);
      Name = char(pName.Value.');
      Label = char(pLabel.Value.');
    end % AnalogIOChannelName

    %% TRIGGER functions
    %     The trigger is used for Single and Record acquisitions. For ScanScreen and ScanShift, the trigger is ignored.
    % To achieve the classical trigger types:
    % - None: Set FDwfAnalogInTriggerSourceSet to trigsrcNone.
    % - Auto: Set FDwfAnalogInTriggerSourceSet to something other than trigsrcNone, such as
    % trigsrcDetectorAnalogIn and FDwfAnalogInTriggerAutoTimeoutSet to other than zero.
    % - Normal: Set FDwfAnalogInTriggerSourceSet to something other than trigsrcNone, such as
    % trigsrcDetectorAnalogIn or FDwfAnalogInTriggerAutoTimeoutSet to zero.
    function AnalogInTriggerSourceSet(a,trigsrc), a.Call(trigsrc); end
    
    function AnalogInTriggerPositionInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.TrigPosRange_s(1) = pmin.Value;
      a.TrigPosRange_s(2) = pmax.Value;
      a.TrigPosSteps = psteps.Value;      
    end % AnalogInTriggerPositionInfo
    function AnalogInTriggerPositionSet(a, TrigPos_s), a.Call(TrigPos_s); end
    
    function AnalogInTriggerAutoTimeoutInfo(a)
      %> Returns the minimum and maximum auto trigger timeout values, and the number of adjustable steps.
      %> The acquisition is auto triggered when the specified time elapses. With zero value the timeout is
      %> disabled, performing "Normal” acquisitions.
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.TrigTOrange_s(1) = pmin.Value;
      a.TrigTOrange_s(2) = pmax.Value;
      a.TrigTOsteps = psteps.Value;      
    end % AnalogInTriggerAutoTimeoutInfo
    function AnalogInTriggerAutoTimeoutSet(a, TO_s), a.Call(TO_s); end

    function AnalogInTriggerHoldOffInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.TrigHO_s(1) = pmin.Value;
      a.TrigHO_s(2) = pmax.Value;
      a.TrigHOsteps = psteps.Value;      
    end % AnalogInTriggerHoldOffInfo
    function AnalogInTriggerHoldOffSet(a, HO_s), a.Call(HO_s); end

    %% TRIGGER DETECTOR functions
    function trigtype = AnalogInTriggerTypeInfo(a)
      %>  Returns the supported trigger type options for the instrument. They are returned (by reference) as a
      %> bit field. This bit field can be parsed using the IsBitSet Macro. Individual bits are defined using the
      %> TRIGTYPE constants in dwf.h.  These trigger type options are:
      %> • trigtypeEdge: trigger on rising or falling edge. This is the default setting.
      %> • trigtypePulse: trigger on positive or negative; less, timeout, or more pulse lengths.
      %> • trigtypeTransition: trigger on rising or falling; less, timeout, or more transition times.
      bitField =  a.GetValue('int32');
      trigtype = '';
      if bitand(bitField, bitshift(1,a.trigtypeEdge)), trigtype = [trigtype 'Edge ']; end
      if bitand(bitField, bitshift(1,a.trigtypePulse)), trigtype = [trigtype 'Pulse ']; end
      if bitand(bitField, bitshift(1,a.trigtypeTransition)), trigtype = [trigtype 'Transition ']; end
    end % AnalogInTriggerTypeInfo
    function AnalogInTriggerTypeSet(a, trigtype), a.Call(trigtype); end
    function AnalogInTriggerChannelSet(a, ChI), a.Call(ChI); end
    function AnalogInTriggerFilterSet(a, filter), a.Call(filter); end % filterDecimate or  filterAverage
    function AnalogInTriggerConditionSet(a, cond), a.Call(Cond); end % TriggerSlopeRise, TriggerSlopeFall, TriggerSlopeEither

    function AnalogInTriggerLevelInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.Call(pmin, pmax, psteps);
      a.TrigLevelRange(1) = pmin.Value;
      a.TrigLevelRange(2) = pmax.Value;
      a.TrigLevelSteps = psteps.Value;      
    end % AnalogInTriggerLevelInfo
    function AnalogInTriggerLevelSet(a, Level), a.Call(Level); end

    %% DESTRUCTOR
    function DeviceClose(a), a.Call(); end
  end % methods

  methods (Access = protected)
    function varargout = Call(a,varargin)
      %> calls DWF function with the same name as a calling member function
      [varargout{1:nargout}] = ...
        AVP.HW.AnalogDiscovery1.StaticCall_level(3,a.h,varargin{:});
    end % Call

    function value = GetValue(a, type)
      %> calls function which takes pointer to type and returns a single value
      p = libpointer([type 'Ptr'],0);
      AVP.HW.AnalogDiscovery1.StaticCall_level(3,a.h,p);
      value = p.Value;
    end
  end % protected methods

  methods(Static)
    function str = GetVersion()
      p = libpointer('int8Ptr',zeros(32,1));
      AVP.HW.AnalogDiscovery1.StaticCall(p);
      str = char(p.Value');
    end

    function str = GetLastErrorMsg()
      pBuffer = libpointer('int8Ptr',zeros(512,1));
      [Code, StrPtr] = AVP.HW.AnalogDiscovery1.StaticCall(pBuffer);
      str = char(StrPtr.');
      % str = char(pBuffer.Value.');
    end % GetLastErrorMsg

    function Num = Enum()
      p = libpointer('int32Ptr',0);
      AVP.HW.AnalogDiscovery1.StaticCall(2,p)
      Num = p.Value;
    end

    function h = DeviceOpen()
      p = libpointer('int32Ptr',0);
      AVP.HW.AnalogDiscovery1.StaticCall(-1,p);
      h = p.Value;
    end % DeviceOpen
  end % static methods

  methods(Static, Access = protected)
    function varargout = StaticCall(varargin)
      [varargout{1:nargout}] = ...
        AVP.HW.AnalogDiscovery1.StaticCall_level(3,varargin{:});
    end % StaticCall

    function varargout = StaticCall_level(level,varargin)
      %> calls DWF function with the same name as a calling member function
      %> form stack level LEVEL, e.g. level == 2 is immediate calling
      %> function
      % determine calling function name
      st = dbstack;
      fname = split(st(level).name,'.'); % function numbel LEVEL in stack
      [status varargout{1:nargout}] = calllib('dwf',['FDwf' fname{end}],varargin{:});
      if status ~= 1
        error(AVP.HW.AnalogDiscovery1.GetLastErrorMsg());
      end
    end % StaticCall_level
  end % methods protected static

  properties(Constant,Hidden)
    enumfilterAll          = 0;
    enumfilterEExplorer    = 1;
    enumfilterDiscovery    = 2;
    enumfilterDiscovery2   = 3;
    enumfilterDDiscovery   = 4;

    % device ID
    devidEExplorer  = 1;
    devidDiscovery  = 2;
    devidDiscovery2 = 3;
    devidDDiscovery = 4;

    % device version
    devverEExplorerC   = 2;
    devverEExplorerE   = 4;
    devverEExplorerF   = 5;
    devverDiscoveryA   = 1;
    devverDiscoveryB   = 2;
    devverDiscoveryC   = 3;

    % trigger source
    trigsrcNone               = 0;
    trigsrcPC                 = 1;
    trigsrcDetectorAnalogIn   = 2;
    trigsrcDetectorDigitalIn  = 3;
    trigsrcAnalogIn           = 4;
    trigsrcDigitalIn          = 5;
    trigsrcDigitalOut         = 6;
    trigsrcAnalogOut1         = 7;
    trigsrcAnalogOut2         = 8;
    trigsrcAnalogOut3         = 9;
    trigsrcAnalogOut4         = 10;
    trigsrcExternal1          = 11;
    trigsrcExternal2          = 12;
    trigsrcExternal3          = 13;
    trigsrcExternal4          = 14;
    trigsrcHigh               = 15;
    trigsrcLow                = 16;

    % instrument states:
    StateReady        = 0;
    StateConfig       = 4;
    StatePrefill      = 5;
    StateArmed        = 1;
    StateWait         = 7;
    StateTriggered    = 3;
    StateRunning      = 3;
    StateDone         = 2;

    DECIAnalogInChannelCount = 1;
    DECIAnalogOutChannelCount = 2;
    DECIAnalogIOChannelCount = 3;
    DECIDigitalInChannelCount = 4;
    DECIDigitalOutChannelCount = 5;
    DECIDigitalIOChannelCount = 6;
    DECIAnalogInBufferSize = 7;
    DECIAnalogOutBufferSize = 8;
    DECIDigitalInBufferSize = 9;
    DECIDigitalOutBufferSize = 10;

    % acquisition modes:
    acqmodeSingle     = 0;
    acqmodeScanShift  = 1;
    acqmodeScanScreen = 2;
    acqmodeRecord     = 3;
    acqmodeOvers      = 4;
    acqmodeSingle1    = 5;

    % analog acquisition filter:
    filterDecimate = 0;
    filterAverage  = 1;
    filterMinMax   = 2;

    % analog in trigger mode:
    trigtypeEdge         = 0;
    trigtypePulse        = 1;
    trigtypeTransition   = 2;

    % trigger slope:
    TriggerSlopeRise   = 0;
    TriggerSlopeFall   = 1;
    TriggerSlopeEither = 2;

    % trigger length condition
    triglenLess       = 0;
    triglenTimeout    = 1;
    triglenMore       = 2;

    % error codes for the functions:
    ercNoErc                  = 0;        %  No error occurred
    ercUnknownError           = 1;        %  API waiting on pending API timed out
    ercApiLockTimeout         = 2;        %  API waiting on pending API timed out
    ercAlreadyOpened          = 3;        %  Device already opened
    ercNotSupported           = 4;        %  Device not supported
    ercInvalidParameter0      = 0x10;     %  Invalid parameter sent in API call
    ercInvalidParameter1      = 0x11;     %  Invalid parameter sent in API call
    ercInvalidParameter2      = 0x12;     %  Invalid parameter sent in API call
    ercInvalidParameter3      = 0x13;     %  Invalid parameter sent in API call
    ercInvalidParameter4      = 0x14;     %  Invalid parameter sent in API call

    % analog out signal types
    funcDC       = 0;
    funcSine     = 1;
    funcSquare   = 2;
    funcTriangle = 3;
    funcRampUp   = 4;
    funcRampDown = 5;
    funcNoise    = 6;
    funcPulse    = 7;
    funcTrapezium= 8;
    funcSinePower= 9;
    funcCustom   = 30;
    funcPlay     = 31;

    % analog io channel node types
    analogioEnable       = 1;
    analogioVoltage      = 2;
    analogioCurrent      = 3;
    analogioPower        = 4;
    analogioTemperature  = 5;
    analogioDmm          = 6;
    analogioRange        = 7;
    analogioMeasure      = 8;
    analogioTime         = 9;
    analogioFrequency    = 10;

    AnalogOutNodeCarrier  = 0;
    AnalogOutNodeFM       = 1;
    AnalogOutNodeAM       = 2;

    AnalogOutModeVoltage  = 0;
    AnalogOutModeCurrent  = 1;

    AnalogOutIdleDisable  = 0;
    AnalogOutIdleOffset   = 1;
    AnalogOutIdleInitial  = 2;

    DigitalInClockSourceInternal = 0;
    DigitalInClockSourceExternal = 1;

    DigitalInSampleModeSimple   = 0;
    % alternate samples: noise|sample|noise|sample|...
    % where noise is more than 1 transition between 2 samples
    DigitalInSampleModeNoise    = 1;

    DigitalOutOutputPushPull   = 0;
    DigitalOutOutputOpenDrain  = 1;
    DigitalOutOutputOpenSource = 2;
    DigitalOutOutputThreeState = 3; % for custom and random

    DigitalOutTypePulse      = 0;
    DigitalOutTypeCustom     = 1;
    DigitalOutTypeRandom     = 2;
    DigitalOutTypeROM        = 3;
    DigitalOutTypeState      = 4;
    DigitalOutTypePlay       = 5;

    DigitalOutIdleInit     = 0;
    DigitalOutIdleLow      = 1;
    DigitalOutIdleHigh     = 2;
    DigitalOutIdleZet      = 3;

    AnalogImpedanceImpedance = 0; % Ohms
    AnalogImpedanceImpedancePhase = 1; % Radians
    AnalogImpedanceResistance = 2; % Ohms
    AnalogImpedanceReactance = 3; % Ohms
    AnalogImpedanceAdmittance = 4; % Siemen
    AnalogImpedanceAdmittancePhase = 5; % Radians
    AnalogImpedanceConductance = 6; % Siemen
    AnalogImpedanceSusceptance = 7; % Siemen
    AnalogImpedanceSeriesCapactance = 8; % Farad
    AnalogImpedanceParallelCapacitance = 9; % Farad
    AnalogImpedanceSeriesInductance = 10; % Henry
    AnalogImpedanceParallelInductance = 11; % Henry
    AnalogImpedanceDissipation = 12; % factor
    AnalogImpedanceQuality = 13; % factor

    ParamUsbPower        = 2; % 1 keep the USB power enabled even when AUX is connected, Analog Discovery 2
    ParamLedBrightness   = 3; % LED brightness 0 ... 100%, Digital Discovery
    ParamOnClose         = 4; % 0 continue, 1 stop, 2 shutdown
    ParamAudioOut        = 5; % 0 disable / 1 enable audio output, Analog Discovery 1, 2
    ParamUsbLimit        = 6; % 0..1000 mA USB power limit, -1 no limit, Analog Discovery 1, 2
    ParamFrequency       = 7; %
  end % constant Properties

end % AnalogDiscovery1
