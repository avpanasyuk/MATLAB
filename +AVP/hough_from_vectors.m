function [a,b] = hough_from_vectors(p,varargin)
  %> @param p - vector(Npoints,2) of points
  %> @param varargin
  %>         - N - this size of image to build, default 200
  %>         - Rblur - N/Rblur is the size of the blur, default 20
  %>         - R, p(i) are normalized to be in +- R range, default 2
  % from the simmetry point of view it is better to parametrize the line as
  % a*p1 + b*p2 = 1; To map a nd b infinite range we can do
  % tan(a)*p1 + tan(b)*p2 = 1, and image becomes  periodoc, so it is easy
  % to do FFT for blur.
  
  AVP.opt_param('N',200);
  AVP.opt_param('Rblur',6);
  AVP.opt_param('R',2);
  AVP.opt_param('do_plot',false);

  % We can build a single angle vector and Tgs vector for both A and B
  Angs = linspace(-pi/2,pi/2,2*N+1); Angs = Angs(2:2:end-1);

  Tgs = tan(Angs);
  
  % it seems like a good idea to normalize p points to +- R range, where R
  % will be optimized later. pnorm = p(:,1)*NormScale(1) + NormOff(1)
  NormOff = []; NormScale = [];
  for cI=1:size(p,2)
    [p_n(:,cI),NormOff(cI),NormScale(cI)] = AVP.scale_to_range(p(:,cI),[-R,R]);
  end

  % plot(p_n(:,1),p_n(:,2),'x')

  % go through cycle for all p points
  A = zeros(N,N);

  for pI = 1:size(p,1)
    % to keep lines continuous we do it twice - once for every column index and
    % once for every row index. We have to use TempA to avoid some pixels
    % added twice.
    % as tan(a)*p1 + tan(b)*p2 = 1, so a = atan((1 - P2*Tgs)/P1) for one
    % line and b = atan((1 - P1*Tgs)/P2);
    % introducing scaling factors, which is 1/deriv
    t1a = 1 - p_n(pI,2)*Tgs;
    t2a = t1a.^2 + p_n(pI,1).^2;
    AderSqr = (t1a.^2 + (p_n(pI,1)*Tgs).^2)./t2a;
    aI = ceil((2/pi*atan(t1a./p_n(pI,1)) + 1)*N/2); % vertical

    t1b = 1 - p_n(pI,1)*Tgs;
    t2b = t1b.^2 + p_n(pI,2).^2;
    BderSqr = (t1b.^2 + (p_n(pI,2)*Tgs).^2)./t2b;
    bI = ceil((2/pi*atan(t1b./p_n(pI,2)) + 1)*N/2); % vertical

    Scale = sqrt(1./AderSqr+1./BderSqr);
    A(([1:N] - 1)*N + aI) = A(([1:N] - 1)*N + aI) + Scale;
    A((bI - 1)*N + [1:N]) = A((bI - 1)*N + [1:N]) + Scale;
    % plot(1:steps_in_angle,Yinds,'+'); hold on
    % plot(Xinds,1:steps_in_angle,'x'); hold off
    % pause
  end

  % let's try to blur to make a single peak. A is periodic, so FFT is good
  if Rblur ~= 0
    BlurKern = repmat(exp(-(([1:N/2]-1)/N*Rblur).^2),N,1).';
    F = AVP.realfft(A);
    F = F.*BlurKern;
    A1 = AVP.realifft(F);
    F = AVP.realfft(A1.');
    F = F.*BlurKern;
    Ablur = AVP.realifft(F).';
    [~, aI, bI] = AVP.max(Ablur);
  else
    [~, aI, bI] = AVP.max(A);
  end
  % imagesc(Ablur)
  % A(aI,bI);
  % Ok, what line in normalized p space these indexes correspond to
  a_n = Tgs(aI);
  b_n = Tgs(bI);
  % plot(p_n(:,1),p_n(:,2),'x'); hold on
  % plot(p_n(:,1),(1 - p_n(:,1)*a_n)/b_n,'+'); hold off

  % now we have to convert a and b in normalized p space to original p
  % space. As p_n1 = p1*NormScale(1) + NormOff(1) and p_n2 = p2*NormScale(2) + NormOff(2)
  % a_n*(p1*NormScale(1) + NormOff(1)) + b_n*(p2*NormScale(2) + NormOff(2)) = 1;
  % a = a_n*NormScale(1)/(1 - a_n*NormOff(1) - b_n*NormOff(2))
  % b = b_n*NormScale(2)/(1 - a_n*NormOff(1) - b_n*NormOff(2))

  Denom = 1 - a_n*NormOff(1) - b_n*NormOff(2);
  a = a_n*NormScale(1)/Denom;
  b = b_n*NormScale(2)/Denom;
  % let's take a look whether it is really linear and what is an error
  if do_plot
    plot(p(:,1),p(:,2),'x'); hold on
    plot(p(:,1),(1 - p(:,1)*a)/b,'+'); hold off
  end
end

 
 
      