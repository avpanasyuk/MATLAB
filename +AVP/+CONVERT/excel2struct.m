%% converts excel datasheet FILE which has first row as a header into struct 
% with corresponding fields
%% OPTIONAL PARAMETERS:
% SHEET - string, name of excel sheet to load, 'Sheet1' default
%% RETURNS
% S - struct
% C - intermediate cell array

function [S C] = excel2struct(file,options)
sheet = 'Sheet1';
if exist('options','var'),
  if isfield(options,'sheet'), sheet = options.sheet; end
else options = []; end

[~,~,C] = xlsread(file,sheet,'','basic');
S = AVP.CONVERT.cell2struct(C);
end


