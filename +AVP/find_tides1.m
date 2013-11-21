function [bot_inds top_inds tides_down tides_up mean_down mean_up]=find_tides1(X,options)
% the function finds all maximims and minimums positions 
% in the nearly-periodic function x. FIND_TIDES is not very robust when
% waves are a bit irregular, trying to do better (and simpler) - Just find
% all places where smoothed plot derivative crosses 0
%% OPTIONS
% FILTER should be two-element vector which specifies golay filter
% parameters. This filter is used only to smooth curve to determine rough
% position of maximums and minimums. Precise position and value of maximums
% and minimums is determined by initial curve X, but number of them comes 
% from rough determination!!!
%% RETURNS
% [bot_inds top_inds tides_down tides_up] 

do_plot = false;
min_dist = 0; % minimal distance between extremums. Should be probably filter(2)/2

if exist('options','var'),
  if isfield(options,'filter'), filter = options.filter; end
  if isfield(options,'do_plot'), do_plot = options.do_plot; end
  if isfield(options,'min_dist'), min_dist = options.min_dist; end
else options = []; end

[bot_inds top_inds tides_down tides_up mean_down mean_up] =  deal([]); % to have something to return;

if exist('filter','var'), Xsm = sgolayfilt(X,filter(1),filter(2)); else Xsm = X; end% smoothed X
Xdiff = diff(Xsm); 

% find "smoothed" maximum positions
top_inds = find(Xdiff(1:end-1) > 0 & Xdiff(2:end) <= 0);
bot_inds = find(Xdiff(1:end-1) <= 0 & Xdiff(2:end) > 0);

% a lot of following operation depend on whether first goes maximum or
% minimum. To avoid a bunch of IF statement we convert the first case to
% the second by negating X and calling nested function

  function [bot_inds,top_inds,tides_down,tides_up,mean_down,mean_up] = ...
      exact_solution(X,top_inds,bot_inds) 
    [tides_down,tides_up,mean_down,mean_up] = deal([]);
    
    % in this function the first is always minimum
    nt = numel(top_inds); nb = numel(bot_inds); 
    n = min([nt,nb]); 

    % find tiny twitches where maximum and minimum are too close and remove
    % them
    if min_dist > 0,
      TwitchI = find(abs(top_inds(1:n)-bot_inds(1:n)) <= min_dist);
      if ~isempty(TwitchI), 
        top_inds(TwitchI) = []; bot_inds(TwitchI) = []; 
        nt = numel(top_inds); nb = numel(bot_inds);
      end
    end
    
    % corresponding maximums and minimums may be shifted by one
    n1 =  min([nt,nb-1]); if n1 <= 1, return; end
    TwitchI = find(abs(top_inds(1:n1-1)-bot_inds(2:n1)) <= min_dist);
    if ~isempty(TwitchI), 
      top_inds(TwitchI) = []; bot_inds(TwitchI+1) = []; 
      nt = numel(top_inds); nb = numel(bot_inds); 
    end

    % sizes might have changed
    n = min([nt,nb]); n1 =  min([nt,nb-1]);
    if n1 <= 0, return; end
    
    % find exact minimum positions
    top_inds_ = [1;top_inds(:);numel(X)];
    for ei=1:nb, 
      [mins(ei),bottom] = min(X(top_inds_(ei):top_inds_(ei+1))); 
      bot_inds(ei) = bottom + top_inds_(ei) - 1;
    end
    
    % find exact maximum positions
    bot_inds_ = [bot_inds(:);numel(X)];
    
    for ei=1:nt, 
      [maxs(ei),top] = max(X(bot_inds_(ei):bot_inds_(ei+1))); 
      top_inds(ei) = top + bot_inds_(ei) - 1;
    end
    
    tides_down = maxs(1:n1-1) - mins(2:n1);
    tides_up = maxs(1:n) - mins(1:n);
    mean_down = (maxs(1:n1-1) + mins(2:n1))/2;
    mean_up = (maxs(1:n) + mins(1:n))/2;
  end % function exact_solution ends

  if isempty(top_inds) || isempty(bot_inds), return; end
  if top_inds(1) > bot_inds(1), % first goes minimum, we do not have to negate
    [bot_inds,top_inds,tides_down,tides_up,mean_down,mean_up] = ...
      exact_solution(X,top_inds,bot_inds);
  else
    [top_inds,bot_inds,tides_up,tides_down,mean_up,mean_down] = ...
      exact_solution(-X,bot_inds,top_inds);
    mean_up = - mean_up;
    mean_down = -mean_down;
  end
  
  if do_plot,
    Peaks = sort([top_inds(:);bot_inds(:)]);
    plot(X,'r.'); hold on; plot(Peaks,X(Peaks),'g-'); hold off;
  end
end
