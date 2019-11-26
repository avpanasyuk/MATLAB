% differs from "vars2struct" in that if variables are similar array collects
% them in an array of structures and not a single structure like "vars2struct"
function out = arrays2AoS(varargin)
  %> given list of variable names wtih variables being either numerical
  %> arrays of the same dimensions or scalars returns array of structures
  %> of the same dimensions with structure fields having the same names and
  %> content as variables
  %> @param varargin - names of variables
  parstr = cat(1,strcat('),''',{varargin{:}},''',num2cell('),{varargin{:}});
  parstr = strcat(parstr{:});
  out = evalin('caller',['struct(',parstr(3:end),'))']);
end