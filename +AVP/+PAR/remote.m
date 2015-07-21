% about remote execution

%% USING POWERSHELL
% start PowerShell from "Administrative tools"

on remote computer
DISABLE ALL PUBLIC NETWORKS!
CMD prompt
powershell
enable-psremoting -force
winrm quickconfig
winrm set winrm/config/client '@{TrustedHosts="<local>"}'
% NO, IT IS PAIN

%% USING PsTools
% c:\Program Files\MATLAB\R2014a\bin\win64\MATLAB.exe -r "pm('open_project','uc')
% run('UC.MARCH_2015.test_par')"
 
T = readtable([par_dir 'par_conf.csv'])

for Ci = 1:height(T)
system(['c:\common\PsTools\psexec.exe \\', T.Computer{Ci}, ...
  ' -u ', T.User{Ci}, ' -p ', T.Password{Ci}, ' "'...
  T.MatlabExe{Ci}, '" -r -logfile ', T.Computer{Ci}, '.log ', ...
  '"pm(''open_project'',''uc''); UC.MARCH_2015.test_par"']);
end






 
