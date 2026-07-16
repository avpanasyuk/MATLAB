function Place = opt_param_present(name,Varargin)
  if ~exist('Varargin','var')
    Varargin = evalin('caller','varargin');
  end
  Place = find([strcmp(Varargin(1:2:end),name)],1,'last');
end
