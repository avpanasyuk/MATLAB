classdef OWON_VDS1022 < handle
  %> before using the class you have to run OWON VDS1022 application, go to
  %> Setting:"SCPI console" and press OK. Commands can run in parallel to
  %> GUI, so you can configure signal in GUI and then run GET_DATA!
  properties
    tcpc
    running = false
  end

  properties(Constant)
    port = 5188;
    timeout = 0.5; % seconds
    num_samples = 1000;
  end

  methods
    function a = OWON_VDS1022()
      a.tcpc=tcpclient('localhost', a.port);
      % a.tcpc.ByteOrder = 'big-endian';
      % configureTerminator(a.tcpc,'CR/LF');

      flush(a.tcpc);
      fprintf('Connected to device "%s"!',...
        a.cmd_read_str('*IDN?'));
      a.cmd_and_check('*RST');
    end % constructor

    function delete(a)
      a.stop();
    end

    function run(a)
      if ~a.running
        if ~strcmpi(a.cmd_read_str('*RUNS'), 'SET RUN')
          error('Failed to run!');
        else 
          a.running = true;
        end
      end
    end % run

    function stop(a)
      if a.running
        if ~strcmpi(a.cmd_read_str('*RUNS'), 'SET STOP')
          error('Failed to stop!');
        else
          a.running = false;
        end
      end
    end % stop

    function auto_tune(a)
      a.cmd_and_check('*AUT');
    end

    function [data, timemarks] = get_data(a, ch)
      [adc dt] = a.get_adc(ch);
      data = adc/2^32*a.get_scale(ch);
      timemarks = [1:numel(data)]*dt*20/numel(data);
    end % get_data

    % following functions are for measuring signal parameters
    function meas_channel(a,ch)
      a.cmd_and_check([':MEAS:SOUR CH' num2str(ch)]);
    end

    function out = measure(a,param_str,ch)
      %> parameter units - volts, seconds, hz or part
      %> @param ch - set's cnahhel, default otherwise, optional
      %> @param_str -  one of PERiod |FREQuency| AVERage |MAX| MIN 
      %>    |VTOP |VBASe |VAMP |PKPK |CYCRms 
      %>    |RTime |FTime |PDUTy |NDUTy |PWIDth| 
      %>    NWIDth |OVERshoot |PREShoot| RDELay| FDELay
      if exist('ch','var')
        cmd_str = [':MEAS' num2str(ch) ':'];
      else
        cmd_str = ':MEAS:';
      end
      out = str2num(a.cmd_read_str([cmd_str param_str '?']));
    end % measure

    function set_coupling(a,coupling_str,ch)
      %> @param coupling_str "AC", "DC" or "GND"
       a.cmd_and_check([':CHAN' num2str(ch) ':COUP' coupling_str]);
    end
  end % methods

  methods (Access = public)
    function wait_for_data(a, timeout, num_bytes)
      if ~exist('timeout','var')
        timeout = a.timeout;
      end
      
      if ~exist('num_bytes','var')
        num_bytes = 1;
      end

      t = tic();
      while a.tcpc.NumBytesAvailable < num_bytes
        if toc(t) > timeout
          error('Response timeouted!')
        end
      end
    end % wait_for_data

    function str = cmd_read_str(a, cmd)
      a.tcpc.flush();
      a.tcpc.writeline(cmd);
      a.wait_for_data();
      str = char(a.tcpc.readline());
      if str(1) == char(13)
        str(1) = [];
      end
    end % cmd_read_str

    function cmd_and_check(a, cmd)
      if ~strncmpi(a.cmd_read_str(cmd),'SUCCESS',7)
        error(['Command "' cmd '" failed!']);
      end
    end % cmd_check

    function [adc dt] = get_adc(a, ch)
      dt = a.get_dt();
      a.tcpc.writeline(['*ADC? CH' num2str(ch)]);
      a.wait_for_data(dt*a.num_samples*3 + 0.01, 6); % at least 6 bytes
      adc = read(a.tcpc);
      sz = fix(numel(adc)/1000)*1000;
      adc = double(typecast(adc(end-sz+1:end),'int32'));
    end % get_data

    function dt = get_dt(a) 
      dt = a.cmd_read_str(':TIM:SCAL?');
      dt = sscanf(dt,'%d%s');
      switch char(dt(2:end).')
        case 'ns', mult = 1e-9;
        case 'us', mult = 1e-6;
        case 'ms', mult = 1e-3;
        case 's', mult = 1;
        otherwise, error('Unknown scale!');
      end
      dt = dt(1)*mult;
    end % get_dt

    function ds = get_scale(a,ch)
      ds = a.cmd_read_str([':CHAN' num2str(ch) ':SCAL?']);
      ds = str2num(ds);
    end % get_scale
  end % protected methods
end % classdef
