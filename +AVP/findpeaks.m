
function [xs,ws,ys] = findpeaks(d,varargin)
  %> FINDPEAKS is robust 1D peak finding in uniformly spaced vector x
  %> @param d: source data
  %> @param varargin
  %>        - wmin: minimum width in pixels to search
  %>        - wmax: maximum width in pixels to search
  %>        - Gamma: width has gamma distribution
  %> @retval xs - x positions of the peaks
  %> @retval ws - widths of the peaks
  %> @retval ys - amplitude of the peaks

  %% let's try a "gaussian - twice as wide gaussian" kernel
  Np = numel(d);
  
  %% let's distribute the width of the kernel using gamma 

  AVP.opt_param('wmin',2/sqrt(-4/3*log(1/8))); % default is when minimums sit on +- 2 pixel.
  AVP.opt_param('wmax', (Np/4)*wmin);
  % AVP.opt_param('Gamma',3); % gamma value for the width curve
  % W_vect = linspace(wmin^(1/Gamma),wmax^(1/Gamma),Np/2).^Gamma;
  W_vect = 10.^linspace(log10(wmin),log10(wmax),Np/2);
  
  KernMat = [];
  for wI = 1:numel(W_vect)
    w = W_vect(wI);
    kern = exp(-(([1:Np] - Np/2)/w).^2).' - ...
      0.5*exp(-(([1:Np] - Np/2)/w/2).^2).';
    kern = circshift(kern,Np/2+1)/w;
    kern = kern - mean(kern);
    % kern = kern / std(kern);
    KernMat = [KernMat,kern];
  end
  
  % imagesc(KernMat)
  % plot(KernMat(:,32))
  
  kern_fft = AVP.realfft(KernMat);
  %imagesc(abs(f))
  
  
  d_fft = repmat(AVP.realfft(d(:)),1,Np/2);
  Amat = AVP.realifft(d_fft.*kern_fft);
  %imagesc(Amat);
  
  C = contour(Amat,Np/2);
  
  Cs = CONTRIB.contourdata(C);
  % It looks like contour lines a split on segmane, let's combine them
  Cs([Cs.isopen] | [Cs.level] <= 0) = [];
  
  [Cs.IsIn] = deal(false);
  
  %% let's do peak by peak
  % [~,maxI] = max(Amat(:));
  % [xI,yI] = ind2sub(size(Amat),maxI);
  [~, cI] = max([Cs.level]);
  Peaks = [];
  pI = 1;
  [yy,xx] = AVP.mesh(1:size(Amat,1), 1:size(Amat,2));
  while ~isempty(cI)
    hold on; plot(Cs(cI).xdata,Cs(cI).ydata,'r'); hold off
%     xI = mean(Cs(cI).xdata);
%     yI = mean(Cs(cI).ydata);
    IsIn = inpolygon(xx,yy,Cs(cI).xdata,Cs(cI).ydata);
    [Peaks(pI,3),maxI] = max(Amat(:).*IsIn(:));
    [Peaks(pI,1),Peaks(pI,2)] = ind2sub(size(Amat),maxI);
        
    for ccI=1:numel(Cs)
      Cs(ccI).IsIn = Cs(ccI).IsIn || inpolygon(Peaks(pI,2),Peaks(pI,1),Cs(ccI).xdata,Cs(ccI).ydata);
    end
    % let's find highest contour the first point is not in
    
    cI = find([Cs.IsIn] == 0,1,'last');
    pI = pI + 1;
  end
  
  xs = Peaks(:,1);
  ws = W_vect(Peaks(:,2)).';
  ys = Peaks(:,3)*Np;
end

function test
  x = [1:128];
  a = 0.5*exp(-(x - 20).^2/25) + 1.6*exp(-(x - 40).^2/2) + exp(-(x - 50).^2/225);
  [xs,ws,ys] = AVP.findpeaks(a)
end

