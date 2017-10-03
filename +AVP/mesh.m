function varargout = mesh(varargin)
  sz = cellfun(@numel,varargin,'UniformOutput',false);
  sz = [sz{:}]; %keyboard
  for dim=1:min([nargin,nargout])
    varargout{dim} = repmat(shiftdim(varargin{dim}(:),1-dim),...
      [sz(1:dim-1) 1 sz(dim+1:end)]);    
  end
end