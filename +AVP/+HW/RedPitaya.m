classdef RedPitaya < handle
  %> before using the class you have to login into Pitaya and start 'SCPI
  %> server'' http://rp-f04769/scpi_manager/
  %> reference is https://redpitaya.readthedocs.io/en/latest/appsFeatures/remoteControl/remoteControl.html#list-of-supported-scpi-commands
  properties
    port = 5000;
    tcpip
  end
  
  methods
    function a = RedPitaya(ip_name)
      if ~exist('ip_name','var'), ip_name = 'rp-f04769'; end
      
      a.tcpip=tcpip(ip_name, a.port);
      fopen(a.tcpip);
      a.tcpip.Terminator = 'CR/LF';
    end
    
    function delete(a)
      fclose(a.tcpip);      
    end
    
    function GenerateWave(a, freq, ampl, shape)
      %> @param shape - one of {sine, square, triangle, sawu,sawd, pwm}
      
      if ~exist('shape','var'), shape = 'sine'; end;
      
      fprintf(a.tcpip,'GEN:RST');
      fprintf(a.tcpip,['SOUR1:FUNC ' shape]);       % Set function of output signal
      fprintf(a.tcpip,['SOUR1:FREQ:FIX ' num2str(freq)]);   % Set frequency of output signal
      fprintf(a.tcpip,['SOUR1:VOLT ' num2str(ampl)]);          % Set amplitude of output signal
      fprintf(a.tcpip,'OUTPUT1:STATE ON');      % Set output to ON
    end
    
    function StopWave(a)
      fprintf(a.tcpip,'OUTPUT1:STATE OFF');      % Set output to ON      
    end
  end
end % classdef
