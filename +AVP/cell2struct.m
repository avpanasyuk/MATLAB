% convert cell array with top row identifying names of variables (which can be 
% nested field names) into a structure S with corrsponging fields which are 
% vectors. It is different from the built-in CELL2STRUCT in that latter 
% converts into a vector of structures and does not support nested fields
% if a filed can be represented as numerical (e.g. array of numerical
% strings) this function does conversion

function s = cell2struct(c)
  for fi=1:numel(c(1,:))
    % let's see whether we have numbers
    % replace spaces in variable name with inderscores
    if ~isempty(c{1,fi}), 
      field_name = strrep(strtrim(c{1,fi}),' ','_');
      % see whether part (or all) of the row is a string representation of the
      % numeric value (thanks, Mike!)
      CharIs = find(cellfun(@ischar,c(2:end,fi)));
      if ~isempty(CharIs)
        Converted = str2double(c(CharIs+1,fi));
        if any(isnan(Converted)), % there are string we can not convert, 
          % so we write everything as it was (cell array column)
          eval(['s.', field_name, ' = c(2:end,fi);']);
          continue;
        else
          c(CharIs+1,fi) = num2cell(str2double(c(CharIs+1,fi)));
        end
      end
      eval(['s.', field_name, ' = [c{2:end,fi}].'';']);
    end
  end
end  