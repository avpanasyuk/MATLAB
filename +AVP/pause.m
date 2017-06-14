% pause with drawnow
function pause(t)
  start = tic;
  while toc(start) < t, drawnow; end
end

 