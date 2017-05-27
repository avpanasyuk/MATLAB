
function [Value, out_varargin]=opt_param(name,default)
  %> check varargin on presence of a given variable
  %> USAGE:
  %> function some_function(varargin)
  %>       RelErrMin = AVP.opt_param('RelErrMin',{});
  
  %> @retval Value in varargin if present, default if absent
  %> @retval out_varargin if base varargin with added default value
  Varargin = evalin('caller','varargin');
  Place = find([strcmp(Varargin(1:2:end),name)],1,'last');
  
  
  if isempty(Place)
    Value = default;
    out_varargin = [Varargin,name,default];
  else
    Value = Varargin{2*Place};
    out_varargin = Varargin;
  end
end