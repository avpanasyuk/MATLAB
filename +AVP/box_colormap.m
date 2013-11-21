function map = box_colormap(N,min_lum)
%+
% uniformly distributes N points in RGB cube, avoiding too bright colors
% MIN_LUM (optional) defines minimum luminocity is scale where white is 1 
% and black is 1. We should use 1/sqrt(27) at most (it is limited internally). 
% because our volume calculation does not work with bigger values
% we can use it as a default value.
%-
if exist('min_lum','var'),
  min_lum=min([1/sqrt(27),min_lum]);
else min_lum = 1/sqrt(27); end

% let calculate the volume of piramid we can not use. (L,L,L) is coord of 
% MIN_LUM point. L = sqrt(3)*min_lum. Piramid side is A. (L,L,L)-(A,0,0)
% is perpend to (L,L,L), 3*L^2-A*L=0   A = 3*L. Side of the base of the piramid
% B = sqrt(2)*A = 3*sqrt(2)*L. Size of the height H = sqrt(B^2-(B/2)^2) =
% B*sqrt(3)/2. Base area = S = B*H/2 = B^2*sqrt(3)/4=sqrt(243)/2*L^2.
% Piramid volume = sqrt(27)/2*L^3 = 27/2*min_lum^3. Wow.
% so we gotta encrease N proportionally
N1 = ceil(N/(1-27/2*min_lum^3));
% OK, let distribute
nr = max([round(N1.^(1/3)),1]);
ng = max([round(sqrt(N1/nr)),1]);
nb = ceil(N1/nr/ng);
[R,G,B] = meshgrid([0:nr-1]/max([nr-1,1]),...
  [0:ng-1]/max([ng-1,1]),[0:nb-1]/max([nb-1,1]));
map = [R(:),G(:),B(:)];
% we got to filter out ones with high min_lum
map = map(find(sum(map,2) < 3*(1-min_lum)),:);
map = map(1:N,:); % return precisely N colors
end

