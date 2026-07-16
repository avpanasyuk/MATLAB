function cell_struct_varargin()
  %> I have following VARARGIN convention when it is used to pass optional
  %> parameters:
  %> VARARGIN may be a cell array of
  %>     - ['param name', param value] pairs - just as typical
  %>       MATLAB convention
  %>     - a cell array followed by ['param name', param value] pairs. The
  %>       cell array should contain ['param name', param value]
  %>       pairs which get prependent to the rest of VARARGIN
  %>     - a structure  followed by ['param name', param value] pairs. The
  %>       structure gets converted to ['field name', field value] pairs which
  %>       get prependent to the rest of VARARGIN
  Varargin = evalin('caller','varargin');
  if ~isempty(Varargin)
    first = Varargin{1};
    if iscell(first)
      Varargin = {first{:},Varargin(2:end)};
    else
      if isstruct(first)
        fn = fieldnames(first);
        if isempty(fn), return; end
        x = [fn,struct2cell(first)].';
        Varargin = {x{:},Varargin(2:end)};
      end
    end
    if ~all(cellfun(@isstr,(Varargin(1:2:end))))
      error('VARARGIN breaks convention!')
    end
    assignin('caller','varargin',Varargin);
  end
end
