function [out,norm_out,Ang,k,l]=hough_from_vectors(p,varargin)
  %> @param p - vector(Npoints,2) of points
  %> @param varargin
  %>         - N - this size of image to build, default 200
  %>         - Rblur - N/Rblur is the size of the blur, default 20
  %>         - R, p(i) are normalized to be in +- R range, default 2
  % I am building an image of line parameters and finding maximum
  % the first parameter is line angle and it changes from 0 to pi and is
  % periodic
  % the second parameter is offset. It can be +- inf, so we have to map
  % this range to a finite range. CTG does the mapping beautifully, and
  % is periodic
  % The fact that trhey are both periodic is important, as we helps this
  % edges in blur (we can just repeat image)

  AVP.opt_param('N',200);
  AVP.opt_param('Rblur',10);
  AVP.opt_param('R',2);

  BlurKern = repmat(exp(-(([1:N/2]-1)/N*Rblur).^2),N,1).';

  % say line parameters are 'Al' for angle (-Pi/2,Pi/2) and 'Ofa' for offset 'angle' (-Pi/2,Pi/2). So, every line 
  % is defined as Y = X*tg(Al) + tg(Ofa). I do not use CTG as ACOT has
  % discont in the middle
  % Intervals are opened, so we do
  % not get infinities.
  % We can build a single angle vector and Tgs vector for both Al ond Ofa
  Angs = linspace(-pi/2,pi/2,2*N+1); Angs = Angs(2:2:end-1);

  % to make anfles periodic we need a trick
  Tgs = tan(Angs);
  
  %[p1,p2] = AVP.mesh([1:N],[1:N]);
  %p = [p1(:),p2(:)];

  % it seems like a good idea to normalize p points to +- R range, where R
  % will be optimized later
  NormOff = []; NormScale = [];
  for cI=1:size(p,2)
    [p(:,cI),NormOff(cI),NormScale(cI)] = AVP.scale_to_range(p(:,cI),[-R,R]);
  end

  plot(p(:,1),p(:,2),'x')

  % go through cycle for all p points
  A = zeros(N,N);

  for pI = 1:size(p,1)
    % to keep lines continuous we do it twice - once for every column index and
    % once for every row index. We have to use TempA to avoid some pixels
    % added twice.
    % as P2 = P1*tg(Al) + tg(Ofa), so Al = atan((P2 - Tgs)/P1) for one
    % line and Ofa = atan(P2 - P1*Tgs);
    TempA(:) = 0;
    % introducing scaling factors
    q = (p(pI,2) - Tgs)/p(pI,1);
    AlScale = 1./sqrt(1+q.^2)/abs(p(pI,1));
    AlI = ceil((2/pi*atan(q) + 1)*N/2); % vertical
    q = p(pI,2) - Tgs*p(pI,1);
    OfScale = 1./(q.^2+1).*sqrt(1+Tgs.^2);
    OfI = ceil((2/pi*atan(q) + 1)*N/2); % horizontal
    Scale = 1./sqrt(1./AlScale.^2+1./OfScale.^2);
    A(([1:N] - 1)*N + AlI) = A(([1:N] - 1)*N + AlI) + Scale;
    A((OfI - 1)*N + [1:N]) = A((OfI - 1)*N + [1:N]) + Scale;
    % plot(1:steps_in_angle,Yinds,'+'); hold on
    % plot(Xinds,1:steps_in_angle,'x'); hold off
    % pause
  end

  imagesc(A)

  % all lines crosses in infinity, let's remove infinite point
  % let's try to blur to make a single peak. A is periodic, so FFT is good
  F = AVP.realfft(A);
  F = F.*BlurKern;
  A1 = AVP.realifft(F);
  F = AVP.realfft(A1.');
  F = F.*BlurKern;
  Ablur = AVP.realifft(F).';
  
  imagesc(Ablur)
  [~, AlI, OfI] = AVP.max(Ablur);
  % [~, AlI, OfI] = AVP.max(A);
  
  A(AlI,OfI);
  % Ok, what line in normalized p space these indexes correspond to
  Al = Angs(AlI);
  Of = Tgs(OfI);
  plot(p(:,1),p(:,2),'x'); hold on
  plot(p(:,1),p(:,1)*tan(Al) + Of,'+'); hold off
  



 

 I=[1:size(in,1)];
 J=[1:size(in,2)];
 Ang = [1:N]/N*pi;
 TgA = tan(Ang);
 [Jg,Ig,TgAg] = meshgrid(J,I,TgA);
 a = 1./(Jg -Ig./TgAg);
 b = 1./(Ig-Jg.*TgAg);
 d = 1./sqrt(a.^2+b.^2);
 % d1 = reshape(d,numel(I)*numel(J),steps_in_angle);
 maxd = max(d(:));
 edges = [0:fix(maxd)];
 out = zeros(numel(edges)-1,N);
 norm_out = out;
 for sI=1:N,
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

 
 

  TempA = zeros(N,N);

  for pI = 1:size(p,1)
    % to keep lines continuous we do it twice - once for every column index and
    % once for every row index. We have to use TempA to avoid some pixels
    % added twice.
    % as P2 = P1*tg(Al) + tg(Ofa), so Al = atan((P2 - Tgs)/P1) for one
    % line and Ofa = atan(P2 - P1*Tgs);
    TempA(:) = 0;
    % introducing scaling factors
    q = (p(pI,2) - Tgs)/p(pI,1);
    AlScale = 1./sqrt(1+q.^2)/abs(p(pI,1));
    AlI = ceil((2/pi*atan((p(pI,2) - Tgs)/p(pI,1)) + 1)*N/2); % vertical
    OfI = ceil((2/pi*atan(p(pI,2) - Tgs*p(pI,1)) + 1)*N/2); % horizontal
    TempA(([1:N] - 1)*N + AlI) = TempA(([1:N] - 1)*N + AlI) + 1;
    TempA((OfI - 1)*N + [1:N]) = TempA((OfI - 1)*N + [1:N]) + 1;
    A = A + (TempA ~= 0);
    % plot(1:steps_in_angle,Yinds,'+'); hold on
    % plot(Xinds,1:steps_in_angle,'x'); hold off
    % pause
  end


 
 
      