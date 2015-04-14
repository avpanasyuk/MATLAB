function start(par_dir, check_period)
%> all directories in par_dir are jobs
%> there is a func.mat file in each directory which contains all necessary
%> info and variable func which aliases work function which takes a single argument
%> - job number, and returns a single variable which will be stored in .out
%> file. All necessary data are imbedded into the function alias
cd(par_dir)
par_dir = pwd; % get fill path
while(1), % waiting for new jobs
  lst = dir('.');
  %    job_file = lst(find(~cellfun(@isempty,regexpi({lst.name},'^WORK[0-9]+$')),1,'first'));
  for di=3:numel(lst)
    if lst(di).isdir
      cd(lst(di).name)
      s=load('func.mat');
      AVP.PAR.start_worker(s.func, check_period);
      cd(par_dir)
    end
    pause(check_period)
  end
end
end
