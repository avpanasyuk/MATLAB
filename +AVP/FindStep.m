%+ function StepValue = AVP_FindStep(x,y,JumpI)
% PURPOSE: we have vector y which has discontinuity at some point as a jump
% in offset. We want to calculate it. For this we fit both sides with the
% same polynomial except that offsets are different. See EliminateStep.odt 
% for formulas
% POSITIONAL PARAMETERS:
% y - vector of y-values
% JumpI - index after which jump happens
% NAMED:
% 'x' - vector of X values, default index of y
% 'poly_order' - order of fit polynomial, default = 2
% 'around_jump' - ignore that many points around jump
% RETURNS:
% StepValue - value of step in offset
% GoodY - Y vector with AROUND_JUMP points around jump interpolated using polynomial
%-

function [StepValue GoodY]= AVP_FindStep(y,JumpI,varargin)
N = length(y);
x = opt_param('x',1:N,varargin{:});
aj = opt_param('around_jump',0,varargin{:});
if aj > 0,
    from = max([JumpI - aj+1,1]);
    to = min([JumpI + aj,N]);
    y(from:to) = [];
    BadX = x(from:to);
    x(from:to) = [];
    JumpI = JumpI - aj;
    N = length(y);
end

poly_order = opt_param('poly_order',2,varargin{:});

if nargin == 3, poly_order = 2; end
% arrays of power coefficients
[K, M] = meshgrid(1:poly_order,1:poly_order);
Xarr = permute(repmat(x(:),[1,poly_order,poly_order]),[2,3,1]);
% now we can build matrix we have to solve to get a
Xk3D = Xarr.^repmat(K,[1,1,N]); Xm3D = Xarr.^repmat(M,[1,1,N]);
MatA = sum(Xk3D.*Xm3D,3)-...
    sum(Xk3D(:,:,1:JumpI),3).*sum(Xm3D(:,:,1:JumpI),3)/JumpI - ...
    sum(Xk3D(:,:,JumpI+1:end),3).*sum(Xm3D(:,:,JumpI+1:end),3)/(N-JumpI);
Xk2D = repmat(x(:),1,poly_order).^repmat(1:poly_order,N,1);
VecY = sum(Xk2D.*repmat(y(:),1,poly_order),1)-...
    sum(y(1:JumpI))*sum(Xk2D(1:JumpI,:),1)/JumpI-...
    sum(y(JumpI+1:end))*sum(Xk2D(JumpI+1:end,:),1)/(N-JumpI);
A = VecY*inv(MatA); % polynomial coefficients, except offset
Al = (sum(y(1:JumpI))-sum(A.*sum(Xk2D(1:JumpI,:),1)))/JumpI;
Ar = (sum(y(JumpI+1:end))-sum(A.*sum(Xk2D(JumpI+1:end,:),1)))/(N-JumpI);
StepValue = Ar - Al;
% fill "bad points" with polynomial
if aj > 0 && nargout > 1,
    [Xarr, K] = meshgrid(BadX,1:poly_order);
     GoodY = [y(1:JumpI) A*(Xarr.^K)+Al y(JumpI+1:end)-StepValue];
end
end











