% ok, let's find project root directory which should be somewhere up the tree. 
global PROJECT_DIR REP_ROOT 
PROJECT_DIR = pwd; PROJECT_DIR(1) = upper(PROJECT_DIR(1)); 
REP_ROOT = PROJECT_DIR; % looking for the root of git repository

while ~isempty(REP_ROOT)
	if exist([REP_ROOT '\.git'],'dir'), break; end
  REP_ROOT = fileparts(REP_ROOT);
end

if isempty(REP_ROOT)
  error('Can not find repository root which has .git subdirectory!')
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

run('..\mystartup.m')




  
  
  
  
