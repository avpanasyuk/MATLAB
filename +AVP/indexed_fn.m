classdef indexed_fn
  %> this class is not a real class, but collection of related functions
  %> it allows to generate a sequence of file names containing index 
  %> file name has form [Dir Prefix num2str(index) [any part added later]]
  %> when asked to get file with the last index or get file name with new
  %> index functions look in the directory for existing files and find the
  %> file with biggest index
  
  methods(Static)
    
    function last_ind = get_last_idx(Dir, Prefix)
      last_ind = 0;
      
      l = dir([Dir Prefix '*']);
      if ~isempty(l),
        ind_strs = cellfun(@(s) sscanf(s,[Prefix '%d']),{l.name},'UniformOutput',false);
        if ~isempty([ind_strs{:}]), last_ind = max([ind_strs{:}]); end
      end
    end %get_last_idx
    
    function name = get_name(Dir, Prefix, Idx)
      name = [Dir Prefix num2str(Idx)];
    end
    
    function [name last_idx] = get_last(Dir, Prefix, BeforeLast)
      if ~exist('BeforeLast','var'), BeforeLast = 0; end
      last_idx = AVP.indexed_fn.get_last_idx(Dir, Prefix) - BeforeLast;
      if last_idx  <= 0, name = '';
      else
        name = [Dir Prefix num2str(last_idx)];
      end
    end % get_last
    
    function name = get_next_name(Dir, Prefix)
      % keyboard
      name = [Dir Prefix num2str(AVP.indexed_fn.get_last_idx(Dir, Prefix)+1)];
    end % get_next

    function name = get_next(Dir, Prefix)
      name = [Dir AVP.indexed_fn.get_next_name(Dir, Prefix)];
    end % get_next
    
  end % methods
end