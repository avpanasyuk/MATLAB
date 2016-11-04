
function [Value, out_varargin]=opt_param(name,default,varargin)
  %> check varargin on presence of a given variable
  %> USAGE:
  %> function some_function(varargin)
  %>       RelErrMin = AVP.opt_param('RelErrMin',{},varargin{:});
  
  %> @retval Value in varargin if present, default if absent
  %> @retval out_varargin if base varargin with added default value
  Place = find([strcmp(varargin(1:2:end),name)],1,'last');
  
  if isempty(Place)
    Value = default;
    out_varargin = [varargin,name,default];
  else
    Value = varargin{2*Place};
    out_varargin = varargin;
  end
end