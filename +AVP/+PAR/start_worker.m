function start_worker(func, period)
% One variable should be an
% alias of function @func which takes a single parameter - job number and
% return a single variable which gets stored in the file with the name
% '%d.out' or '%d.err' if there is an error
while(1)
  lst = dir('.');
  job_file = lst(find(~cellfun(@isempty,regexpi({lst.name},'^[0-9]+$')),1,'first'));
  if ~isempty(job_file)
    %% try to delete file. If succesful then it is our job
    % idiocy. "delete" does not return status, but if there is no file
    % returns warning that this file name is directory. Jeez
    lastwarn('');
    delete(job_file.name);
    if isempty(lastwarn)
      % Ok, we successfully deleted file, we do the job...
      try
        fprintf(1,'Took on %s...\n',job_file.name)
        out = func(str2num(job_file.name));
        save([job_file.name '.out'],'out')
      catch ME
        save([job_file.name '.err'],'ME')
        rethrow(ME)
      end
    end
  else
    % fclose(fopen([getenv('COMPUTERNAME'),'.done'], 'w'));
    break
  end
  pause(period)
end
end

