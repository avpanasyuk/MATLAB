function Zad = AnalogDiscovery_Z(AD_data)
% Z calculated from Analog Discovery sampling. There should be two channels in data
% first is V and second ~ to current.

% data are prepared something like this:
% s = daq.createSession('digilent')
% ch1 = s.addAnalogInputChannel('AD1', 1, 'Voltage')
% ch2 = s.addAnalogInputChannel('AD1', 2, 'Voltage')
% s.Rate = 1e6;
% s.Channels(1).Range = [-2.5 2.5];
% s.Channels(2).Range = [-2.5 2.5];
% s.DurationInSeconds = 1/30/7;
% data = s.startForeground;

  AD_data = AVP.zero_mean(AD_data);
  Carrier = AD_data(:,2);
  Frs = AVP.realfft(Carrier);
  Carrier90 = AVP.realifft(Frs*(-i));
  CarSqr = mean(Carrier.^2);  
  Zad = complex(mean(AD_data(:,1).*Carrier),mean(AD_data(:,1).*Carrier90))/...
    CarSqr;
end
  
