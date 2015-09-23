% ok, let's find project root directory which should be somewhere  up the tree. 
PROJECT_DIR = pwd;
REP_ROOT = PROJECT_DIR; % looking for the root of git repository
while ~isempty(REP_ROOT)
	if exist([REP_ROOT '\MATLAB'],'dir'), break; end
  REP_ROOT = fileparts(REP_ROOT);
end

if isempty(REP_ROOT)
  error('Can not find repository root which has MATLAB subdirectory!')
end
    
addpath([REP_ROOT '\MATLAB'], [REP_ROOT '\MATLAB\AVP_LIB'],  [REP_ROOT '\MATLAB\AVP_LIB\ARESLab']);

h = matlab.desktop.editor.getAll;
% if there is matlab.files file in directory use it
if exist('matlab.files','file') == 2
  % close all opened files
  for doci=1:numel(h)
    h(doci).close;
  end
  f = fopen('matlab.files','rt');
  files = textscan(f,'%s\n');
  files = files{1};
  for fi = 1:numel(files)    
    if ~isempty(files{fi}) && exist(files{fi},'file') == 2
      matlab.desktop.editor.openDocument(files{fi});
    end
  end
  fclose(f);
else
  %% In directory JefOre there may be several subdirectories with different
  % repositories. If we switch between them try to switch files too.
  files = {h.Filename};
  
  if numel(files)
    JefCoreDir = fileparts(REP_ROOT);
    
    BelongsToJefCore = strncmpi(JefCoreDir,files,length(JefCoreDir));
    NotInCurrentRep = find(BelongsToJefCore & ...
      ~strncmpi(REP_ROOT,files,length(REP_ROOT)));
    
    for doci=1:numel(NotInCurrentRep)
      h(doci).close;
      % cut out old repository dir 
      [~, remain] = strtok(files{doci}(length(JefCoreDir)+2:end),'\'); 
      FileInCurrentRep = [REP_ROOT remain];
      
      if exist(FileInCurrentRep,'file') == 2
        matlab.desktop.editor.openDocument(FileInCurrentRep);
      end
    end
  end
end

clearvars -except  PROJECT_DIR

  
  
  
  
