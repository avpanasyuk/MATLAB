function a = line_x_plane(line,P),
%+ finds at what distance line(s) cross the plane(s)
% LINE(s) are defined by source point R and direction D. It passes through
% points R+a*D with any a. 
% PLANE(s) are defined by perpendicular P to the center of coordinates. 
% if plane passes through COC make this vector very small but not 0.
% if R+a*D is in the plane then dot(R + a*D - P,P) = 0, or dot(R,P) +
% a*dot(D,P) - dot(P,P) = 0, or a = (dot(P,P)-dot(R,P))/dot(D,P)
%-

a = (repmat(sum(P.*P,2),[1,size(line.R,1)]) - P*line.R.')./(P*line.D.');
end
