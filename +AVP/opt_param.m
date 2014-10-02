%+ 
% function value=opt_param(name,default,varargin)
% parses varargin which should be in shpae 'par_name',param pairs and 
% returns value of specified by name parameter 
% USE: function myfunc(positional_params,varargin)
% named_param = opt_param('param_name',0,varargin{:})
%-
function value=opt_param(name,default,varargin)
    par_i = find(strcmp(varargin,name));
    if ~isempty(par_i), value=varargin{par_i(1)+1}; else value=default; end
end
