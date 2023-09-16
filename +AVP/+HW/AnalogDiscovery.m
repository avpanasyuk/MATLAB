classdef AnalogDiscovery < handle
  properties
    s % daq.di.Session
    fig % figure handle
  end
  methods
    function a = AnalogDiscovery()
      a.s = daq('digilent')
      a.fig = figure;
    end

    function delete(a)
    end

    function AddInputChannels(a,ID)
      %> @param ID - defines device, 'AD?' for the first one. etc
      if ~exist('ID','var'), ID = 'AD1'; end

      a.s.addinput(ID, [1,2], 'Voltage')
    end

    function AddOutputChannel(a,ID)
      if ~exist('ID','var'), ID = 'AD1'; end
      a.s.addoutput(ID, 1, 'Voltage')
    end

    function disp(a)
      disp(a.s)
    end

    function SetRate(a,rate)
      if rate < a.s.RateLimit(1)
        error('Rate too low!');
      end
      if rate > a.s.RateLimit(2)
        error('Rate too high!');
      end
      a.s.Rate = rate;
    end

    function oscilloscope(a)
      function plot_(obj,evt)
        data = read(obj,obj.ScansAvailableFcnCount,'OutputFormat','Matrix');
        plot(data)
      end

      a.s.ScansAvailableFcn = @plot_;
      a.s.start('Duration',180);
    end

    function [data, timestamps] = get_data(a,channel,varargin)
      AVP.opt_param('tune',0);
      AVP.opt_param('show',0);
      if tune
        a.SetRange([-25 25],channel);
      end
      [data, timestamps] = a.s.read(1000,"OutputFormat","Matrix");

      if tune
        Mins = min(data); Maxs = max(data);
        Range = Maxs - Mins;
        Mins = Mins - Range*0.1;
        Maxs = Maxs + Range*0.1;
        a.SetRange([Mins(1) Maxs(1)],channel);
        [data, timestamps] = a.s.read(1000,"OutputFormat","Matrix");
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


