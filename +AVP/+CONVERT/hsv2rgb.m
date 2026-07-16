function rgb = hsv2rgb(hsv)
%+
% MATLAB built-in function sucks badly.
% We will try taking my approach. We take main diagonal of RGB cube and
% perpendicular to this diagonal from the point on the diagonal
% corresponding to V and with angle counting from R equal H*360. Then we
% see where this diagonal crosses RGB cube and returning point at
% S*distance from diagonal to crossing.
%- 
Diag = [1,1,1];
AlongDiag = hsv(:,3)*Diag;
% now we need to vectors perpendicular to diag and each other so we can
% turn H between them
Perp1 = AVP.norm_vect(cross(Diag,[1,0,0]));
Perp2 = AVP.norm_vect(cross(Diag,Perp1));
Direction = sind(hsv(:,1)*360)*Perp1+cosd(hsv(:,1)*360)*Perp2;
% Now we have to find where Direction crosses RGB cube. We check all sides
% and then find closest point
Planes = [0.001,0,0;0,0.001,0;0,0,0.001;1,0,0;0,1,0;0,0,1];
Lines = struct('R',AlongDiag,'D',Direction);

A = AVP.line_x_plane(Lines,Planes);
% OK, now select minimal positive finite A for each line
A(find(A<0))=2;
A(find(~isfinite(A)))=2;
minA = min(A,[],1);
% scale eit with saturation
minA = minA.*hsv(:,2).';
% calculating resulting map
rgb = max(AlongDiag + Direction.*repmat(minA.',[1,3]),0);
end
