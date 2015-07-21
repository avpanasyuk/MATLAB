function start_work(par_dir,num_jobs)
% base workspace should contain function func which takes a single argument
% - job number, and returns a single variable which will be stored
for fi=1:num_jobs
  fclose(fopen(num2str(fi,'%05d'), 'w'));
end
end


