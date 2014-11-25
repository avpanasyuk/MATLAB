function [constant error FirstI LastI] = find_constant_level(x, do_plot)
% if a single continuous interval in data corresponds to
% constant level we find it.  We go through all values of start and stop of this interval
% and find minimum error. We assume that its size is > sqrt(numel(x))

if nargin < 2 || isempty(do_plot), do_plot = true; end

n = numel(x);
Res = [];
for FirstI=1:n
  for LastI=FirstI+fix(sqrt(n)):n
    Res = [Res; [FirstI,LastI,...
      mean(x(FirstI:LastI)),std(x(FirstI:LastI))/sqrt(LastI-FirstI)]];
  end
end

% finding min error
[error, minI] = min(Res(:,4));
constant = Res(minI,3);
FirstI = Res(minI,1);
LastI = Res(minI,2);

if do_plot
  plot(x,'.'); hold on
  plot([LastI,FirstI],[constant,constant],'r'); hold off 
end
end




