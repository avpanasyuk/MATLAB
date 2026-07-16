% if we have a cloud of points to plot it is difficult to see what's going
% one. the function split x azis on segments, calculates std and mean per
% segment and plots mean, mean +std, mean-std.
% or calculates median and means of positive and negative errors and plots
% median+pos_mean*sqrt(2*pi) and median+neg_mean*sqrt(2*pi)
% or does both
function [mx,my,errs,neg_errs] = cloud(x,y,varargin)
  % check for options
  if nargin > 2 && isstruct(varargin{1})
    options = varargin{1}; varargin = varargin(2:end); 
  end
  options = struct(varargin{:});
  
  
  % possibly convert varargin into options structure
  N = numel(x);

  %% default values
  points_in_bin = fix(N^0.33); % number of points in the bin
  do_mean = 1;
  do_median = 0;
  do_spread = 1;

  if exist('options','var'),
      if isfield(options,'points_in_bin'), points_in_bin = options.points_in_bin; end
      if isfield(options,'do_mean'), do_mean = options.do_mean; end
      if isfield(options,'do_median'), do_median = options.do_median; end
      if isfield(options,'do_spread'), do_spread = options.do_spread; end
  else options = []; end

  Nbins = fix(N/points_in_bin);

  [x_sorted Ids] = sort(x);

  x_binned = repmat(0,points_in_bin,Nbins);
  y_binned = x_binned; % set size
  x_binned(:) = x_sorted(1:numel(x_binned));
  y_binned(:) = y(Ids(1:numel(x_binned)));

  % now, what to plot
  hold_is_on = ishold;
  
  mx = median(x_binned); % we always use median for x
  if do_mean,
    my = mean(y_binned); 
    plot(mx,my,'Marker','.',varargin{:}); 
    if ~hold_is_on, hold on; end
    if do_spread,
      errs = std(y_binned);
      plot(mx,my+errs,'LineStyle',':',varargin{:}); plot(mx,my-errs,'LineStyle',':',varargin{:});
    end
  end
  if do_median,
    my = median(y_binned); 
    plot(mx,my,'Marker','o','markersize',3,varargin{:});
    if ~hold_is_on, hold on; end
    if do_spread,
      errs = mx; neg_errs = mx; % set size
      for I=1:Nbins
        pos_i = find(y_binned(:,I) >= 0);
        neg_i = find(y_binned(:,I) <= 0);
        errs(I) = mean(y_binned(pos_i,I) - my(I));
        neg_errs(I) = mean(y_binned(neg_i,I) - my(I));
      end
      plot(mx,my+errs*sqrt(2*pi),'LineStyle','-.',varargin{:}); 
      plot(mx,my+neg_errs*sqrt(2*pi),'LineStyle','-.',varargin{:});
    end
  end
  if ~hold_is_on, hold off; end
end







  

