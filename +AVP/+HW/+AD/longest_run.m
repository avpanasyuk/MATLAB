function n = longest_run(mask)
%> @file longest_run.m
%> @brief Longest run of consecutive true values in a logical vector, in samples.
%>
%> The useful statistic when asking whether a supply dip was a transient or something held down:
%> total time below a threshold conflates one long excursion with many short ones, and only the
%> longest single run tells you whether a reservoir capacitor could have covered it.
%>
%> Divide by the sample rate for seconds: longest_run(y < 2.8)/Fs.
mask = logical(mask(:));
d = diff([false; mask; false]);
st = find(d == 1);
en = find(d == -1);
if isempty(st)
    n = 0;
else
    n = max(en - st);
end
end
