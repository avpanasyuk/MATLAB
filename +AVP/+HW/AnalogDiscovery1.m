classdef AnalogDiscovery1 < handle
  %> daq toolbox version of this sucks!
  properties
    h % handle
    SampleRateRange
    BufferSizeRange
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
    end % constructor

    function delete(a)
      AVP.HW.AnalogDiscovery1.DeviceClose(a.h);
    end

    function varargout = Call(a,varargin)
      %> calls DWF function with the same name as a calling member function
      % determine calling function name
      st = dbstack;
      fname = split(st(2).name,'.'); % previous function in stack
      [status varargout{1:nargout}] = calllib('dwf',['FDwf' fname{end}],a.h,varargin{:});
      if status ~= 1
        error(AVP.HW.AnalogDiscovery1.GetLastErrorMsg());
      end
    end % Call

    function DeviceAutoConfigureSet(AutoConfigure), a.Call(AutoConfigure); end
    function DeviceReset(a), a.Call(); end
    function AnalogInReset(a), a.Call(); end
    function AnalogInConfigure(a), a.Call(false, true); end
    
    function AnalogInFrequencyInfo(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      a.Call(pmin,pmax);
      a.SampleRateRange = [pmin.Value, pmax.Value];
    end % AnalogInFrequencyInfo
    
    function AnalogInBufferSizeInfo(a)
      pmin = libpointer('int32Ptr',0);
      pmax = libpointer('int32Ptr',0);
      a.Call(pmin,pmax);
      a.BufferSizeRange = [pmin.Value, pmax.Value];
    end % AnalogInBufferSizeInfo
    
    function AnalogInFrequencySet(Freq_Hz), a.Call(Freq_Hz); end

    function freq = AnalogInFrequencyGet(a)
      p = libpointer('doublePtr',0);
      a.Call(p);
      freq = p.Value;
    end % AnalogInFrequencyGet

    function modes = AnalogInAcquisitionModeInfo(a)
      p = libpointer('int32Ptr',0);
      a.Call(p);
      bitField = p.Value;
      modes = '';
      if bitand(bitField, 1), modes = [modes 'Single ']; end
      if bitand(bitField, bitshift(1,1)), modes = [modes 'ScanShift ']; end
      if bitand(bitField, bitshift(1,2)), modes = [modes 'ScanScreen ']; end
      if bitand(bitField, bitshift(1,3)), modes = [modes 'Record ']; end
      if bitand(bitField, bitshift(1,5)), modes = [modes 'Single1 ']; end
    end % AnalogInAcquisitionModeInfo

    %% AnalogInStatus FUNCTIONS
    function status = AnalogInStatus(doReadData)
      p = libpointer('uint8Ptr',0);
      a.Call(doReadData,p);
      status = p.Value;
    end % AnalogInFrequencyGet

    % Note:  To ensure consistency between device status and measured data, the following AnalogInStatus*functions 
    % do not communicate with the device. These functions only return information and data from the last 
    % AnalogInStatus call. 
    function Num = AnalogInStatusSamplesLeft(a)
      p = libpointer('int32Ptr',0);
      a.Call(p);
      Num = p.Value;
    end % AnalogInStatusSamplesLeft

  end % methods

  methods(Static)
    
    function varargout = StaticCall(varargin)
      %> calls DWF function with the same name as a calling member function
      % determine calling function name
      st = dbstack;
      fname = split(st(2).name,'.'); % previous function in stack
      [status varargout{1:nargout}] = calllib('dwf',['FDwf' fname{end}],varargin{:});
      if status ~= 1
        error(AVP.HW.AnalogDiscovery1.GetLastErrorMsg());
      end
    end % Call

    function str = GetVersion()
      p = libpointer('int8Ptr',zeros(32,1));
      AVP.HW.AnalogDiscovery1.Call(p);
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

    function DeviceClose(h)
      AVP.HW.AnalogDiscovery1.StaticCall(h)
    end % DeviceClose
  end % static methods

end % AnalogDiscovery1
