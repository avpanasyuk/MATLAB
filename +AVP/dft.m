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
  F = [1:n]/n*30.; % linear frequencies
  N = 3729;
  CosC = repmat(randi(1,[1,n]),N,1);
  SinC = repmat(randi(1,[1,n]),N,1);
  [Nmap, Fmap] = meshgrid([1:N]/N,F); % N changes vertically
  Signal = sum(cos(Nmap*2*pi.*Fmap)
  
  
end

