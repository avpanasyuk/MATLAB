function out = AoS2SoA(x, varargin)
  %> converts array of structure into structure of [cell] arrays. If field
  %> size is the same for all structures in array it gets stacked into array
  %> along first unitary dimension, otherwise cell array
  AVP.opt_param('names', fieldnames(x));
  AVP.opt_param('DoSqueeze',false);

  if numel(x) == 1, out = x; end
  in_sz = size(x);
  % strip leading ones
  % in_sz = in_sz(find(in_sz ~= 1,1,"first"):end);
  for fi=1:numel(names)
    % let's see whether number of rows of this field for every structure is the
    % same, so we can do conversion
    sz1 = size(x(1).(names{fi}));
    if all(cellfun(@(el) isequal(size(el),sz1),{x.(names{fi})})) && ...
        ~isa(x(1).(names{fi}),'function_handle')
      CollectField = [x.(names{fi})]; % they are all the same size, so they should stack
      % CollectField possibly lost some dimensions
      Dims = [sz1,in_sz];
      if DoSqueeze, Dims(Dims == 1) = []; end 
      out.(names{fi}) = reshape([x.(names{fi})],[Dims,1]); % they are all the same size, so they should stack
      % but maybe loose some dimensions, so we restore them
    else
      if DoSqueeze, in_sz(in_sz == 1) = []; end 
      out.(names{fi}) = reshape({x.(names{fi})},[in_sz(:),1]);
    end
  end
end


