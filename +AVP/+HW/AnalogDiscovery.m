classdef AnalogDiscovery < handle
  %> The object of this class corresponds to a single channel on one of the Digilent
  %> Analog Discoveries attached
  properties
    s % daq.di.Session
    fig % figure handle
  end
  methods
    function a = AnalogDiscovery()
      a.s = daq.createSession('digilent')
      a.fig = figure;
    end
    
    function delete(a)
    end
    
    function AddInputChannels(a,ID)
      %> @param ID - defines device, 'AD?' for the first one. etc
      if ~exist('ID','var'), ID = 'AD1'; end
      
      a.s.addAnalogInputChannel(ID, [1,2], 'Voltage')
    end
    
    function AddOutputChannel(a,ID)
      if ~exist('ID','var'), ID = 'AD1'; end
      a.s.addAnalogOutputChannel(ID, 1, 'Voltage')
    end
    
    function disp(a)
      disp(a.s)
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
    
    function oscilloscope(a,channel)
      s2h = s1.addlistener('DataAvailable',@(src,event) plot(event.TimeStamps, event.Data));
    end
    
    function [data, timestamps, triggerTime] = get_data(a,channel,varargin)
      AVP.opt_param('tune',0);
      AVP.opt_param('show',0);
      if tune
        a.SetRange([-25 25],channel);
      end
      [data, timestamps, triggerTime] = a.s.startForeground;
      
      if tune
        Mins = min(data); Maxs = max(data);
        Range = Maxs - Mins;
        Mins = Mins - Range*0.1;
        Maxs = Maxs + Range*0.1;
        a.SetRange([Mins(1) Maxs(1)],channel);
        [data, timestamps, triggerTime] = a.s.startForeground;
      end
      
      if show
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
    
    function StartContinuousOutput(a,Samples,Rate)
      if exist('Rate','var'), a.s.Rate = Rate; end
      a.s.IsContinuos = true;
      a.listener = addlistener(a.s,'DataRequired', @(src,event) src.queueOutputData(Samples(:)));
      queueOutputData(a.s,Samples(:));
      startForeground(a.s);
    end
  end
end


