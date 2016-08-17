function [Value, out_varargin] = CheckOptionalVar(VarName,default,varargin)
  %> check varargin on presence of a given variable
  %> USAGE:
  %> function some_function(varargin) 
  %>       RelErrMin = AVP.CheckOptionalVar('RelErrMin',{},varargin{:}); 

  %> @retval Value in varargin if present, default if absent
  %> @retval out_varargin if basent varargin with added default value
  Place = find([strcmp(varargin(1:2:end),VarName)],1,'last');
  
  if isempty(Place)
    Value = default;
    out_varargin = [varargin,VarName,default];
  else
    Value = varargin{Place+1};
    out_varargin = varargin;
  end  
end