function [constant error FirstI LastI] = find_constant_level(x, do_plot, from_side, min_length)
%> if a single continuous interval in data corresponds to
%> constant level we find it.
%> We go through all values of start and stop of this interval
%> and find minimum error.
%> @param from_side, if 1 assumes that constant interval starts in the beginning
%> if 2 - at the end, if empty - that we have to determine both ends
%> @param min_length - minimal length of the constant interval, sqrt(numel(x))
%> by default


n = numel(x);

if nargin < 2 || isempty(do_plot), do_plot = true; end
if nargin < 3 || isempty(from_side), from_side = 0; end
if nargin < 4 || isempty(min_length), min_length = fix(sqrt(n)); end

Res = [];
switch from_side
  case 0
    for FirstI=1:n
      for LastI=FirstI+min_length:n
        Res = [Res; [FirstI,LastI,...
          mean(x(FirstI:LastI)),std(x(FirstI:LastI))/sqrt(LastI-FirstI)]];
      end
    end
  case 1
    FirstI = 1;
    for LastI=FirstI+min_length:n
      Res = [Res; [FirstI,LastI,...
        mean(x(FirstI:LastI)),std(x(FirstI:LastI))/sqrt(LastI-FirstI)]];
    end
  case 2
    LastI = n;
    for FirstI=1:n-min_length
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




