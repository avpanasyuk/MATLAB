classdef RedPitaya < handle
  %> the board's SCPI server must be running: off in the stock image, enabled at boot on
  %> rp-f04769; otherwise start it at http://<board>/scpi_manager/ or `systemctl start redpitaya_scpi`.
  %> Address the board by hostname - Calib is keyed by it, and an IP gets RAW readings.
  %> reference is https://redpitaya.readthedocs.io/en/latest/appsFeatures/remoteControl/remoteControl.html#list-of-supported-scpi-commands
  properties
    port = 5000;
    tcpc
    SampleRateDividerLog2 = -1; %!< valid range 0 to 16
    Channel = [];
    Range = [20 20]; %!< full scale per channel, V: 20 = HV jumper, 1 = LV jumper
    Host = '';       %!< board hostname, the key into Calib
  end

  properties(Constant)
    Clock_Hz = 125e6
  end

  methods(Static)
    function c = Calib(host)
      %> this board's correction for its broken EEPROM calibration, reading = gain*true + offset,
      %> one [gain offset] row per channel, fitted on the HV jumper only. Same constants and
      %> provenance as avp.hw.rp.CALIB in LIBS/PYTHON. Keyed by hostname, so an IP never matches.
      switch host
        case 'rp-f04769', c = [1.11897 0.94465; 1.16017 -0.01632];
        otherwise, c = [];
      end
    end
  end

  methods
    function a = RedPitaya(ip_name)
      if ~exist('ip_name','var'), ip_name = 'rp-f04769'; end
      a.Host = lower(strtok(ip_name,'.'));
      if isempty(a.Calib(a.Host))
        warning('RedPitaya:nocalib',['No calibration for ''%s'' - readings are RAW, and on a ' ...
          'board with a bad EEPROM calibration may be off by >10%%'], a.Host);
      end

      a.tcpc=tcpclient(ip_name, a.port);
      a.tcpc.ByteOrder = 'big-endian';
      configureTerminator(a.tcpc,'CR/LF');

      flush(a.tcpc);
    end % constructor

    function delete(a)
    end

    function GenerateWave(a, freq, ampl, shape)
      %> @param shape - one of {sine, square, triangle, sawu,sawd, pwm}

      if ~exist('shape','var'), shape = 'SINE'; end;

      writeline(a.tcpc,'GEN:RST');
      writeline(a.tcpc,['SOUR1:FUNC ' shape]);       % Set function of output signal
      writeline(a.tcpc,['SOUR1:FREQ:FIX ' num2str(freq)]);   % Set frequency of output signal
      writeline(a.tcpc,['SOUR1:VOLT ' num2str(ampl)]);          % Set amplitude of output signal
      writeline(a.tcpc,'OUTPUT1:STATE ON');      % Set output to ON
      writeline(a.tcpc,'SOUR1:TRIG:INT');        % Set trigger to internal instant trigger
      writeline(a.tcpc,'ACQ:RST');

      % Set trigger delay to 0 samples delay sets trigger to center of the buffer
      % Signal on your graph will have trigger in the center (symmetrical)
      % Samples from left to the center are samples before the trigger
      % Samples from center to the right are samples after the trigger
      writeline(a.tcpc,'ACQ:TRIG:DLY 0');
    end % GenerateWave

    function StopWave(a)
      writeline(a.tcpc,'OUTPUT1:STATE OFF');      % Set output to ON
    end % StopWave

    %! @param varargin
    %!        - Channel - list of channels to sample
    %!        - Range - full scale, V: 20 for the HV jumper, 1 for LV; a scalar for both channels
    %!          or [ch1 ch2], indexed by channel number. It must match the physical jumpers -
    %!          GetAcqBuffer declares it as GAIN, which switches nothing.
    %!        - SampleRateDividerLog2 - decimation 2^n, n = 0..16. StartAcq only records these;
    %!          GetAcqBuffer sends them.
    %!
    function StartAcq(a,varargin)
      AVP.opt_param('SampleRateDividerLog2',0);
      n = SampleRateDividerLog2;
      if ~isscalar(n) || n < 0 || n > 16 || n ~= fix(n)
        error('SampleRateDividerLog2 must be an integer 0..16'); % the board takes powers of two only
      end
      C = reshape(AVP.opt_param('Channel',[1,2]),1,[]);
      if isempty(C) || ~all(ismember(C,[1 2])) || numel(unique(C)) ~= numel(C)
        error('Channel must be a non-empty subset of [1 2], without repeats');
      end
      R = reshape(AVP.opt_param('Range',[20 20]),1,[]);
      if isscalar(R), R = [R R]; end
      if numel(R) ~= 2 || ~isnumeric(R) || ~isreal(R) || ~all(isfinite(R)) || ~all(R > 0)
        error('Range must be a positive scalar or [ch1 ch2]');
      end
      a.Channel = C;
      a.Range = R;
      a.SampleRateDividerLog2 = n;
    end % StartAcq

    function out = writeread(a, text)
      writeline(a.tcpc,text);
      while a.tcpc.NumBytesAvailable == 0, end;
      out = readline(a.tcpc);
    end

    function out = writereadbin(a, text, varargin)
      writeline(a.tcpc,text);
      while a.tcpc.NumBytesAvailable < 65543, end;
      out = read(a.tcpc,65543,varargin{:});
    end

    %!
    % The buffer length is always 16384 samples: one row per sampled channel, in channel-number
    % order. Values are true volts through Calib on HV channels; LV channels and an unknown board
    % stay RAW (Calib was fitted on HV only).

    function x = GetAcqBuffer(a,varargin)
      % Every acquisition setting is declared here, on every call: any ACQ:RST (GenerateWave sends
      % one) resets at least DEC and GAIN, and both GetDeltaT and the correction below assume what
      % StartAcq recorded.
      if a.SampleRateDividerLog2 < 0 || isempty(a.Channel), error('Call StartAcq first'); end
      writeline(a.tcpc,['ACQ:DEC ' num2str(2^a.SampleRateDividerLog2)]);
      writeline(a.tcpc,'ACQ:DATA:UNITS VOLTS');
      writeline(a.tcpc,'ACQ:DATA:FORMAT BIN');
      writeline(a.tcpc,'ACQ:AVG ON'); % average the decimated samples rather than pick one
      for ChI = a.Channel
        if a.Range(ChI) > 1, Gain = 'HV'; else, Gain = 'LV'; end
        writeline(a.tcpc,['ACQ:SOUR' num2str(ChI) ':GAIN ' Gain]);
      end
      writeline(a.tcpc,'ACQ:START')
      writeline(a.tcpc,'ACQ:TRIG NOW')

      % % wait for fill adc buffer
      while 1
        fill_state = writeread(a,'ACQ:TRIG:FILL?');
        if '1' ==  fill_state(1:1), break; end
      end

      read(a.tcpc);
      % Read data from buffer
      x = [];
      c = a.Calib(a.Host);
      for ChI=1:2
        if any(a.Channel == ChI)
          b = writereadbin(a,['ACQ:SOUR' num2str(ChI) ':DATA?']);
          y = double(typecast(swapbytes(typecast(b(8:end),'uint32')),'single'));
          if a.Range(ChI) > 1 && ~isempty(c)
            y = (y - c(ChI,2))/c(ChI,1);
          elseif a.Range(ChI) <= 1
            warning('RedPitaya:lv','ch%d is on LV, which Calib was never fitted for - RAW',ChI);
          end
          x = [x;y];
        end
      end
    end % GetAcqBuffer

    function dt = GetDeltaT(a)
      dt = 2^a.SampleRateDividerLog2/a.Clock_Hz;
    end
  end % methods
end % classdef
