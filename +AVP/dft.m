function [ft intercept n] = dft(x,y,n,approach)
  %> this function does fourier transform for non-uniformly distributed samples
  %> @param x should be in domain [-pi, pi]
  %> @param y
  %> @param n - maximum harmonics - number of wavelength over the domain
  intercept = [];
  
  if ~exist('approach','var'), approach = 2; end
  switch approach
    case 1
      SumSin = zeros(1,n); SumCos = zeros(1,n);
      
      for HarmI=1:n
        SumSin(HarmI) = SumSin(HarmI) + sum(sin(HarmI*x).*y);
        SumCos(HarmI) = SumCos(HarmI) + sum(cos(HarmI*x).*y);
      end
      ft = complex(SumCos,SumSin)/numel(x)*2;
    case 2
      % let's try to fit
      Nvect = [0:n];
      [Narr, Xarr] = meshgrid(Nvect,x);
      Arg = Narr.*Xarr;
      Mat = [cos(Arg),sin(Arg(:,2:end))];
      Sol = pinv(Mat)*y;
      if max(Sol(2:end)) > (max(y)-min(y))*2
        error('Two many harmonis, try to decrease n, maybe significantly')
      end
      % Sol = y\Mat;
      ft = complex(Sol(2:n+1),Sol(n+2:end));
      intercept = Sol(1);
    case 3
      % let's try to fit
      Nvect = [0:n-1];
      [Narr, Xarr] = meshgrid(Nvect,x);
      Arg = Narr.*Xarr;
      Mat = [sin(Arg), cos(Arg)];
      % Sol = pinv(Mat)*y;
      Sol = y\Mat;
      ft = complex(Sol(1:n),Sol(n+1:end));
  end
end

function test_script
  n = 60;
  F = [1:n]-1; %/n*30.; % linear frequencies
  N = 3012;
  CosC = repmat(randi(100,[1,n]),N,1);
  SinC = repmat(randi(100,[1,n]),N,1);
  [Fmap, Nmap] = meshgrid(F, [1:N]/N); % N changes vertically
  Signal = sum(cos(Nmap*2*pi.*Fmap).*CosC + sin(Nmap*2*pi.*Fmap).*SinC,2);
  plot(Signal)
  ft = AVP.realfft(Signal);
  
  % [ft intercept n] = AVP.dft([1:N]/N*2*pi-pi,Signal,2*n,2);
  subplot(2,2,1)
  plot(real(ft(1:n)))
  subplot(2,2,2)
  plot(CosC(1,1:end))
  subplot(2,2,3)
  plot(imag(ft(2:n)))
  subplot(2,2,4)
  plot(SinC(1,2:end))
  
  
  
end

