classdef AnalogDiscovery < handle
  %> Digilent USB oscilliscope
  properties
    s % daq.di.Session
  end
  methods
    function a = AnalogDiscovery()
      a.s = daq.createSession('digilent')
      a.s.addAnalogInputChannel('AD1', 1, 'Voltage')
      a.s.addAnalogInputChannel('AD1', 2, 'Voltage')
      a.s.addAnalogOutputChannel('AD1', 1, 'Voltage')
    end
    
    function delete(a)
      delete(a.s)
    end
    
    function SetTiming(a,rate,duration)
      if nargin > 1 
        if numel(rate) ~= 0, a.s.Rate = rate; end
      else
        if nargin > 2 
          if numel(duration) ~= 0, a.s.DurationInSeconds = duration; end
        end
      end
    end
      
    
    function [data, timestamps, triggerTime] = get_data(a,tune,display)
      if nargin < 2 || numel(tune) == 0, tune = 0; end
      if nargin < 3 || numel(display) == 0, display = 0; end
            
      if tune
        a.SetRange([-25 25],1);
        a.SetRange([-25 25],2);
      end
      [data, timestamps, triggerTime] = a.s.startForeground;

      if tune
        Mins = min(data); Maxs = max(data);
        Range = Maxs - Mins; 
        Mins = Mins - Range*0.1;
        Maxs = Maxs + Range*0.1;
        a.SetRange([Mins(1) Maxs(1)],1);
        a.SetRange([Mins(2) Maxs(2)],2);
        [data, timestamps, triggerTime] = a.s.startForeground;
      end
      
      if display
        old = gcf;
        set(0,'CurrentFigure',a.fig);
        plot(timestamps,data)
        set(0,'CurrentFigure',old);
        % disp('Press any key...')
        % pause
      end
    end
    
    function SetRange(a,Range,Index)
      a.s.Channels(Index).Range = Range;
    end      
  end
end

  
