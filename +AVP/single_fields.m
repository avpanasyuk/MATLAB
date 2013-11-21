% recursively extract all the single fields from the structure S and returns
% their values, names and positions

function [names, vals]=single_fields(s)
names={}; vals = {}; 
fnames = fieldnames(s);
for fni=1:numel(fnames),
  Field = getfield(s,fnames{fni});
  if numel(Field) == 1 || ischar(Field),
    if isstruct(Field),
      [SubFields Subvals] = AVP.single_fields(Field);
      if ~isempty(SubFields), 
        names=[names,strcat(fnames{fni},'.',SubFields)]; 
        vals=[vals,Subvals];
      end
    else
      names = [names,fnames{fni}]; 
      vals = [vals,{Field}];
    end
  end % we are ignoring array fields
end
end




