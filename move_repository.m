function move_repository
  %> if we go to another repository MATLAB opens the files it remembers
  %> from the old repository which may be a source for confusion. This
  %> function closes all open in editor files and opens identical files in
  %> the current repository (if exist)
  
  global PROJECT_DIR REP_ROOT DATA_DIR
  
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
      if ~isempty(files{fi})
        if exist([REP_ROOT '\' files{fi}],'file') == 2
          matlab.desktop.editor.openDocument([REP_ROOT '\' files{fi}]);
        else if exist(files{fi},'file') == 2
            matlab.desktop.editor.openDocument(files{fi});
          end
        end
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
end