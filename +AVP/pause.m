% pause with drawnow
function pause(t)
  start = cputime;
  while cputime - start < t, drawnow; end
end

 