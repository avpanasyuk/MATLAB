% ok, let's find project root directory which should be somewhere  up the tree. 
global PROJECT_DIR REP_ROOT DATA_DIR
PROJECT_DIR = pwd; PROJECT_DIR(1) = upper(PROJECT_DIR(1)); 
REP_ROOT = PROJECT_DIR; % looking for the root of git repository
DATA_DIR = 'c:\Dropbox\JEF Core\Sasha\DATA\';

while ~isempty(REP_ROOT)
	if exist([REP_ROOT '\MATLAB'],'dir'), break; end
  REP_ROOT = fileparts(REP_ROOT);
end

if isempty(REP_ROOT)
  error('Can not find repository root which has MATLAB subdirectory!')
end
    
addpath([REP_ROOT '\MATLAB'], [REP_ROOT '\MATLAB\AVP_LIB'],  [REP_ROOT '\MATLAB\AVP_LIB\ARESLab']);


% SET OLD PLOT PALETTE
co = [0 0 1;
      0 0.5 0;
      1 0 0;
      0 0.75 0.75;
      0.75 0 0.75;
      0.75 0.75 0;
      0.25 0.25 0.25];
set(0,'defaultAxesColorOrder',co)

AVP.clearvars()
format compact 
format shortg
set(0,'defaulttextinterpreter','none')
set(0,'DefaultFigureWindowStyle','docked')



  
  
  
  
