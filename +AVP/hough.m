% for pixel(I,J) all lines passing through it are given by formula:
%
function [out,norm_out,Ang,k,l]=hough(in,steps_in_angle),
 I=[1:size(in,1)];
 J=[1:size(in,2)];
 Ang = [1:steps_in_angle]/steps_in_angle*pi;
 TgA = tan(Ang);
 [Jg,Ig,TgAg] = meshgrid(J,I,TgA);
 a = 1./(Jg -Ig./TgAg);
 b = 1./(Ig-Jg.*TgAg);
 d = 1./sqrt(a.^2+b.^2);
 % d1 = reshape(d,numel(I)*numel(J),steps_in_angle);
 maxd = max(d(:));
 edges = [0:fix(maxd)];
 out = zeros(numel(edges)-1,steps_in_angle);
 norm_out = out;
 for sI=1:steps_in_angle,
   for eI=1:numel(edges)-1,
     InBin = find(d(:,:,sI) >= edges(eI) & d(:,:,sI) < edges(eI+1));
     out(eI,sI) = sum(in(InBin));
     norm_out(eI,sI) = numel(InBin);
   end
 end
 % immediately show the result
r = out./norm_out;
imagesc(out)
[~,M] = max(r(:));
[k,l] = ind2sub(size(r),M)
end

 
 
 
 
      