classdef scrolling_plot < handle
  properties
  period
  figure
  end
  methods
    function a=scrolling_plot(func,period,options)
      % ok, we can set things up only after we know what func returns, and
      % it may start returning something only later. So, we postpone
      % setting things up until the last moment
       if ishandle(a.monitor_figure), % delete the old one
        close(a.monitor_figure); % will execute our custom CloseRequestFcn
        % and clean everything up
      end
     
      % rows are samples
      plot_names = 
      x = [1:size(
      % names are just port numbers
      if exist('options','var')
        if isfield(options,'plot_names'), plot_names = options.plot_names; end
        if isfield(options,'update_period'), update_period = options.update_period; end
      end
   end
  end
  
end % classdef scrolling_plot

% one SAMPLE_PERIOD unit is 64 microseconds
    % OPTIONS
    % UPDATE_PERIOD is in seconds
    % NUM_PERIODS is the number of update periods visible on the plot
    function scrolling_plot(a,ports,sample_period,options)
      plot_names = regexp(num2str(ports),'(\d+)','tokens'); % default plot
      update_period = sample_period*64e-6*5;
      
      % names are just port numbers
      if exist('options','var')
        if isfield(options,'plot_names'), plot_names = options.plot_names; end
        if isfield(options,'update_period'), update_period = options.update_period; end
      end
      
      if ishandle(a.monitor_figure), % delete the old one
        close(a.monitor_figure); % will execute our custom CloseRequestFcn
        % and clean everything up
      end
      % build a window of scrolling plots
      a.monitor_figure = figure('DeleteFcn',@delete_mf,'BusyAction','cancel',...
        'Interruptible','off');
      % got to build plots for the first time
      % to avoid headache with resize we make DataArray as big as
      % possible from the beginning
      scnsize = get(0,'ScreenSize');
      a.monitor_data = NaN([scnsize(3),numel(ports)]);
      for pli=1:numel(ports)
        subplot(numel(ports),1,pli);
        a.monitor_plots(pli) = plot(a.monitor_data(:,pli));
        % set(a.monitor_plots(pli),'YDataSource','a.monitor_data')
        ylabel(plot_names{pli});
      end
      % Now add just read data
      
      % create a timer to update it
      a.monitor_timer = timer('ExecutionMode','fixedRate',...
        'Period',update_period,...
        'TimerFcn',@mf_timer_func,...
        'BusyMode','drop');
      
      %%
      function mf_timer_func(varargin)
        % the first thing is try to read something
        try
          [Vals Times] = a.an_bg_read();
        catch ME
          if strcmp(ME.identifier,'teensy:command_locked'),
            return
          else
            rethrow(ME)
          end
        end
        if isempty(Vals), return; end
        old_gcf = gcf;
        set(0,'CurrentFigure',a.monitor_figure);
        num_just_read = size(Vals,1);
        a.monitor_data(1:end-num_just_read,:) = ...
          a.monitor_data(num_just_read+1:end,:);
        a.monitor_data(end-num_just_read+1:end,:) = Vals;
        % refreshdata(a.monitor_plots);
        for pli=1:numel(a.monitor_plots),
          set(a.monitor_plots(pli),'YData',a.monitor_data(:,pli))
        end
        % refreshdata(a.monitor_figure);
        set(0,'CurrentFigure',old_gcf);
      end
      
      % start background data acquisition
      a.an_bg_read_start(ports,sample_period);
      a.start_monitor
      %%
      function delete_mf(varargin)
        a.an_bg_read_stop();
        % if isa(a.monitor_timer,'timer'),
        a.stop_monitor;
        delete(a.monitor_timer);
        % end
        a.monitor_figure = -1;
      end
    end
    
    function start_monitor(a)
      start(a.monitor_timer);
    end
    
    function was_running = stop_monitor(a)
      was_running = a.monitor_is_running;
      if was_running,
        stop(a.monitor_timer);
        % wait(a.monitor_timer); % if turned on we get error message
        % 'Can't wait with a timer that has an infinite TasksToExecute.'
      end
    end
    
    function is_running = monitor_is_running(a)
      is_running =  isa(a.monitor_timer,'timer') && isvalid(a.monitor_timer) && ...
        strcmp(get(a.monitor_timer,'Running'),'on');
    end
