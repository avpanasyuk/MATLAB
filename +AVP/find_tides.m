function [bottoms tops vol_downs vol_ups]=find_tides(X,options)
% the function finds all maximims and minimums positions 
% in the nearly-periodic function x.
%% OPTIONS
% FILTER should be two-element vector which specifies golay filter
% parameters
%% RETURNS
% VOLUMES are both ups and downs, all positive

filter = [];
do_plot = false;
min_waves = 2; % minimum number of waves in the plot

if exist('options','var'),
  if isfield(options,'filter'), filter = options.filter; end
  if isfield(options,'do_plot'), do_plot = options.do_plot; end
  if isfield(options,'min_waves'), min_waves = options.min_waves; end
else options = []; end

bottoms = []; tops = []; vol_ups =[]; vol_downs =[]; % to have something to return;

%% the first thing to do is to determine an average period  
XSz = numel(X);
if XSz < min_waves*16, return; end % data are too short 
XFFT = fft(X);
Pwr = abs(XFFT(min_waves:fix(XSz/8)));
[MaxPwr,MaxHrm] = max(Pwr.'.*sqrt([1:numel(Pwr)]));
%, OK, we know primary period
Period = fix(XSz/(MaxHrm+min_waves-1));

%% Now we have to determine whether it is up or down at the beginning. 
% For this we got to smooth it a lot to be sure there is no noise. Reliable
% way to do it is FFT. Let's just kill everything which has smaller than 
% Period*3/4.
GoodRange = round(MaxHrm*3/2);
XFFT(min_waves+GoodRange+1:end-min_waves-GoodRange+1) = 0;
XSmooth = ifft(XFFT);
% let determine whether first is maximum or minimum
Starts_up = (XSmooth(2)-XSmooth(1)) > 0;
Ends_up = (XSmooth(end)-XSmooth(end-1)) > 0;

% FFT filtering is too harsh, SGOLAY is better
if isempty(filter), XSmooth = X;
else XSmooth = sgolayfilt(X,filter(1),filter(2)); end

if  ~Starts_up,  
  XSmooth = -XSmooth; Ends_up = ~Ends_up;
end % make sure it starts up, so the first thing is maximim. %otherwise turn
% it upside down

if Period*0.75 > XSz, return; end

[~,MaxI(1)] = max(XSmooth(1:fix(Period*0.75-1))); % we now that we 
% have first maximum, so it should happen somewhere is 0.75 of the Period
wI = 1; % wave number
while 1,
  if ~Ends_up && MaxI(wI)+Period*0.75 > XSz, break; end % XSmooth ends with 
  % maximum and there is no space for another one
  [~,MinI(wI)] = min(XSmooth(MaxI(wI):min([MaxI(wI)+Period-1,XSz])));
  MinI(wI) = MinI(wI) + MaxI(wI) - 1;
  wI = wI + 1;
  if Ends_up && MinI(wI-1)+Period*0.75 > XSz, break; end % XSmooth ends with 
  % minimum and there is no space for another one
  [~,MaxI(wI)] = max(XSmooth(MinI(wI-1):min([MinI(wI-1)+Period-1,XSz])));
  MaxI(wI) = MaxI(wI) + MinI(wI-1) - 1;
end

if ~Starts_up, % we overturned the vector
  bottoms = MaxI; tops = MinI; XSmooth = -XSmooth; 
else
  bottoms = MinI; tops = MaxI;
end
bn = numel(bottoms); tn = numel(tops);
if nargout > 2 && bn ~= 0 && tn ~= 0 % we need to return volumes
  if bottoms(1) < tops(1),
    vol_ups = XSmooth(tops(1:min([bn,tn])))-XSmooth(bottoms(1:min([bn,tn])));
    if bn > 1, 
      vol_downs = XSmooth(tops(1:min([bn-1,tn])))-XSmooth(bottoms(2:min([bn-1,tn])+1));
    end
  else
    if tn > 1,
      vol_ups = XSmooth(tops(2:min([bn,tn-1])+1))-XSmooth(bottoms(1:min([bn,tn-1])));   
    end
    vol_downs = XSmooth(tops(1:min([bn,tn])))-XSmooth(bottoms(1:min([bn,tn])));
  end
end
if do_plot,
  Peaks = sort([tops,bottoms]);
  plot(X,'r.'); hold on; plot(Peaks,XSmooth(Peaks),'g-'); hold off; 
end

end
