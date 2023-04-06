classdef RedPitaya < handle
  %> before using the class you have to login into Pitaya and start 'SCPI
  %> server'' http://rp-f04769/scpi_manager/
  %> reference is https://redpitaya.readthedocs.io/en/latest/appsFeatures/remoteControl/remoteControl.html#list-of-supported-scpi-commands
  properties
    port = 5000
    tcpc
    SampleRateDividerLog2 = 0
  end

  properties(Constant)
    BufferSize = 16384
  end

  methods
    function a = RedPitaya(ip_name)
      if ~exist('ip_name','var'), ip_name = 'rp-f04769'; end

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
      writeline(RP,'ACQ:TRIG:DLY 0');
    end % GenerateWave

    function StopWave(a)
      writeline(a.tcpc,'OUTPUT1:STATE OFF');      % Set output to ON
    end % StopWave

    function StartAcq(a,varargin)
      AVP.opt_param('SampleRateDividerLog2_',0);
      if SampleRateDividerLog2_ > 16
        error('Divider is too high!');
      end
      AVP.opt_param('Channel',1);

      if SampleRateDividerLog2_ ~= a.SampleRateDividerLog2
        a.SampleRateDividerLog2 = SampleRateDividerLog2_;
        writeline(a.tcpc,['ACQ:DEC ' num2str(a.SampleRateDividerLog2)]);
      end
      writeline(a.tcpc,'ACQ:DATA:UNITS VOLTS');
      writeline(a.tcpc,'ACQ:DATA:FORMAT BIN');
      writeline(a.tcpc,'ACQ:AVG ON'); % averaging samples to get SampleRateDividerLog2 instread of picking one
      % to communication buffer
    end % StartAcq

    function out = writeread(a, text)
      writeline(a.tcpc,text);
      while a.tcpc.NumBytesAvailable == 0, end;
      out = readline(a.tcpc);
    end

    function out = writereadbin(a, text, varargin)
      writeline(a.tcpc,text);
      while a.tcpc.NumBytesAvailable == 65543, end;
      out = read(a.tcpc,65543,varargin{:});
    end

    %!
    % The buffer length is always 16384 samples

    function x = GetAcqBuffer(a,varargin)
      writeline(a.tcpc,'ACQ:START')
      writeline(a.tcpc,'ACQ:TRIG NOW')

      % % wait for fill adc buffer
      while 1
        fill_state = writeread(a,'ACQ:TRIG:FILL?');
        if '1' ==  fill_state(1:1), break; end
      end

      read(a.tcpc);
      % Read data from buffer
      x = writereadbin(a,'ACQ:SOUR1:DATA?');
      signal_str = typecast(swapbytes(typecast(x(8:end),'uint32')),'single');
      x = writereadbin(a,'ACQ:SOUR2:DATA?');
      signal_str_2 = typecast(swapbytes(typecast(x(8:end),'uint32')),'single');

      x = [signal_str; signal_str_2].';
    end % GetAcqBuffer
  end % methods
end % classdef
