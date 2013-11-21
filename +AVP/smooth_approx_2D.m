function [Zgrid, Ngrid] = smooth_approx_2D(P,Z,options)
%% one of the series of N-dimentional approximation functions with very 
% smooth surface defined on the uniform grid to approximate cloud Z = f(P),
% where P is (number of
% points, number of parameters/dimensions) matrix. It uses iterations to
% balance between tension force trying to keep surface smooth and
% attraction force from the data points

%% PARSE OPTIONS
% DEFAULTS
Ngrid = 50;
Mins = min(P,1); Maxs = max(P,1);
Margin = 2; % number of grid point around data points as a margin
if exist('options','var') && ~isempty(options)
  if isfield(options,'Ngrid'), Ngrid = options.Ngrid; end
  if isfield(options,'Mins'), Mins = options.Mins; end
  if isfield(options,'Maxs'), Maxs = options.Maxs; end  
  if isfield(options,'Margin'), Margin = options.Margin; end  
end

if numel(Ngrid) == 1, Ngrid(2) = Ngrid; end
Ndp = size(P,1); % number of data points
%% Build grid
for di=1:2, % dimensions. By default we add MARGIN points margin aroung data points.
  d(:,di) = [-Margin:Ngrid(di)+Margin-1]/(Ngrid(di)-1); % 
  % grid scale is changing from 0 to 1 inside margins
  d(:,di) = (Maxs(di)-Mins(di))*d(:,di) + Mins(di);
  GridStep(di) = d(2,di)-d(1,di);
end
[Xgrid,Ygrid] = meshgrid(d(:,1),d(:,2));

%% Transform point coordinates from data unit into grid indices
Ginds = (P - repmat(Mins,[Ndp 1]))./repmat(GridStep,[Ndp 1]);

%% iterations. Two steps:
% 1) Calculate force. Two conponents:
% a) Each data point pulls grid rectangle it corresponds to with force
% proportional to the distance and inversely proportional to the error
% b) neiboring points are trying to make surface smooth, so each point is
% pulled to the average of the neibouring points (usually half way)
% 2) all points move on distance proportional to the force. 

Force = zeros(size(Xgrid)); Zgrid = zeros(size(Xgrid));

while 1,
  % go through all data points and assign the force
  for dpi=1:Ndp,
    %% CALCULATE FORCE
    %% DATA FORCE
    % distribute force for all four corners of the rectangle the dp belongs
    % to. Each corner has contribution coefficient CornCoeffs proportional
    % to the area of opposing rectangle. Grid value is calculated as corner
    % values weighted with CornCoeffs, and force on the corners is weighed
    % with CornCoeffs as well.
    Gint = fix(Ginds(dpi,:)); DeltInds = Ginds(dpi,:) - Gint;
    Corns = [[0 0];[0 1];[1 0]; [1 1]];
    CornInds = repmat(Gint,[4 1])+Corns;
    CornDists = (1-Corns*2).*repmat(DeltInds,[4 1])+Corns;
    CornCoeffs =  prod(1-CornDists,2);
    CornLinInds = sub2ind(size(Force),Gint(1)+Corns(:,1),Gint(2)+Corns(:,2));
    Zdev = Z(dpi) - sum(Zgrid(CornLinInds).*CornCoeffs);
    Force(CornLinInds)=CornCoeffs*Zdev;
    
