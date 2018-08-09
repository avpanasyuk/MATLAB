% ok, let's find project root directory which should be somewhere up the tree. 
global PROJECT_DIR REP_ROOT 
PROJECT_DIR = pwd; PROJECT_DIR = upper(PROJECT_DIR(1)); 
CurDir = PROJECT_DIR;

while ~isempty(CurDir)
  if exist([CurDir '\MATLAB'],'dir')
    PROJECT_DIR = CurDir;
  end
	if exist([CurDir '\.git'],'dir')
      REP_ROOT = CurDir;
      break
  end
  CurDir = fileparts(CurDir)
end

if exist([PROJECT_DIR '\MATLAB\mystartup.m'],'file')
  run([PROJECT_DIR '\MATLAB\mystartup.m'])
end

if exist([PROJECT_DIR '\mystartup.m'],'file')
  run([PROJECT_DIR '\mystartup.m'])
end
    
% SET OLD PLOT PALETTE,BUT WITH CLEAR SEQUENCE RGBCMYKG
co = [1.00 0.00 0.00;
  0.00 0.50 0.00;
  0.00 0.00 1.00;
  0.00 0.75 0.75;
  0.75 0.00 0.75;
  0.50 0.50 0.00;
  0.00 0.00 0.00;
  0.75 0.75 0.75];
% SET IMPROVED COLORS
% co = CONTRIB.brewermap(8,'Accent');
set(0,'defaultAxesColorOrder',co)

AVP.clearvars()
format compact 
format shortg
% set(0,'defaulttextinterpreter','none')
set(0,'DefaultFigureWindowStyle','docked')





  
  
  
  
