function varargout = mesh(varargin)
  %> universal meshgrid, takes a arbitrary number of arrays of different
  %> shape, combines all their dimensions and expands each sings to all the
  %> dimensions. All one-sized dimensions are discarded
  sz = cellfun(@size,varargin,'UniformOutput',false);
  if nargout > nargin, error('Too many output arguments!'); end
  for nin=1:min([nargin,nargout])
    predims = [sz{1:nin-1}];
    varargout{nin} = AVP.squeeze(repmat(shiftdim(varargin{nin},-numel(predims)),...
      [predims,ones(1,numel(sz{nin})),sz{nin+1:end}]));
  end
end