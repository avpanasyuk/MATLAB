function CellOut = mesh_cell(varargin)
  %> universal meshgrid, takes a arbitrary number of arrays of different
  %> shape, combines all their dimensions and expands each sings to all the
  %> dimensions. All one-sized dimensions are discarded
  sz = cellfun(@size,varargin,'UniformOutput',false);
  for nin=nargin:-1:1
    predims = [sz{1:nin-1}];
    CellOut{nin} = AVP.squeeze(repmat(shiftdim(varargin{nin},-numel(predims)),...
      [predims,ones(1,numel(sz{nin})),sz{nin+1:end}]));
  end
end