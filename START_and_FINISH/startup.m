% ok, let's find project root directory which should be somewhere up the tree.
global PROJECT_DIR MATLAB_DIR
INIT_DIR = pwd; INIT_DIR(1) = upper(INIT_DIR(1));
PROJECT_DIR = INIT_DIR;
CurDir = INIT_DIR;

while ~isempty(CurDir)
  if exist([CurDir '\MATLAB'],'dir')
    MATLAB_DIR = [CurDir '\MATLAB'];
    PROJECT_DIR = CurDir;
    break
  end
  if exist([CurDir '\.git'],'dir')
    MATLAB_DIR = CurDir;
    PROJECT_DIR = CurDir;
    break
  end
  CurDir = fileparts(CurDir);
end

addpath(MATLAB_DIR)
if exist([MATLAB_DIR '\AVP_LIB'],'dir'), addpath([MATLAB_DIR '\AVP_LIB']); end

try
run mystartup.m
catch
end

%% let's open  files from the last visit. 
%% Try current directory
% I do not want to close and open the same file
if  exist([INIT_DIR '\matlab.files'],'file')
  MfileDir = INIT_DIR;
elseif ~strcmpi(MATLAB_DIR, INIT_DIR) && exist([MATLAB_DIR '\matlab.files'],'file')
  MfileDir = MATLAB_DIR;
end

if exist('MfileDir','var')
  h = matlab.desktop.editor.getAll;
  Filenames = {h.Filename};
  KeepI = zeros(1,numel(h));
  
  f = fopen([MfileDir '\matlab.files']);
  while 1
    l = fgetl(f);
    if ~ischar(l), break; end
    
    if exist(l,'file')    
    OpenI = strcmp(l,Filenames);
    if ~any(OpenI)
      eval(['edit ''' l '''']);
    else
      KeepI(OpenI) = true;
    end
    end
  end
  
  % now we have to close files we do not need
  h(~KeepI).close;
  fclose(f);
end

%% SET OLD PLOT PALETTE,BUT WITH CLEAR SEQUENCE RGBCMYKG
co = [1.00 0.00 0.00;
  0.00 0.50 0.00;
  0.00 0.00 1.00;
  0.00 0.75 0.75;
  0.75 0.00 0.75;
  0.50 0.50 0.25;
  0.00 0.00 0.00;
  0.50 0.50 0.50;
  0.75 0.25 0.25;
  0.25 0.75 0.25;
  0.40 0.40 0.75;
  0.25 0.50 0.50;
  0.50 0.25 0.50;
  0.75 0.50 0.00;
  0.00 0.75 0.50;
  0.50 0.00 0.75;
  0.75 0.00 0.50;
  0.50 1.00 0.00;
  0.00 0.50 1.00];

% SET IMPROVED COLORS
% co = CONTRIB.brewermap(8,'Accent');
set(0,'defaultAxesColorOrder',co)

try, AVP.clearvars(); catch; end
format compact
format shortg
set(0, 'DefaultTextInterpreter', 'none')
set(0, 'DefaultLegendInterpreter', 'none')
set(0, 'DefaultAxesTickLabelInterpreter', 'none')
set(0,'DefaultFigureWindowStyle','docked')








