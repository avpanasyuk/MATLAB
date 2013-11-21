function theyare = arefields(s,fields),
%+ same as AVP.isfield except that it work on a cell array of fields
%-
if ischar(fields), % just a signle field
  theyare = AVP.isfield(s,fields);
else
  for fi=1:numel(fields),
    theyare(fi) = AVP.isfield(s,fields{fi});
  end
end
end
