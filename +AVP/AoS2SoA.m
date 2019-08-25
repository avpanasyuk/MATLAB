function out = AoS2SoA(x, names)
  %> converts array of structure into structure of [cell] arrays. If field
  %> size is the same for all structures in array it gets stacked into array
  %> along first unitary dimension, otherwise cell array
  if ~AVP.is_defined('names'), names = fieldnames(x); end
  str_sz = size(x);
  for fi=1:numel(names)
    % let's see whether dimensions of this field for every structure is the
    % same, so we can do conversion
    sz = cellfun(@(x) size(x),{x.(names{fi})},'UniformOutput',false);
    sz_arr = cat(1,sz{:});
    sz = size(sz_arr);
    if all(all(sz_arr == repmat(sz_arr(1,:),sz(1),1)))
      c_arr = {x.(names{fi})};
      dims = size(c_arr{1});
      stack_dim = find(dims ~= 1,1,'last') + 1;
      if isempty(stack_dim), stack_dim = 1; end
      dims(stack_dim:stack_dim+ndims(x)-1) = str_sz;
      out.(names{fi}) = reshape(cat(stack_dim,c_arr{:}),dims);
    else
      out.(names{fi}) = reshape({x.(names{fi})},str_sz);
    end
  end
end


