function [x,fval,MinArrayX,MinArrayF] = fminsearch_global(fun,x0_samples,options,MinArrayX,MinArrayF)
% NOTE: For least square problems use LSQNONLIN instead of this.
% tries to find a global minimum by sampling at first at the grid defined
% by X0_SAMPLES and then recursively at the corners of cube centered as the weigted
% mean of found minimums and having size 1/3 of RMS
% NOTE: we are assuming that theoretical minimum is 0, so default weigth is 1/fval^2  
% X0_SAMPLES - cell array with a vector of inititial probe points for each variable. Initial sampling
% is done on the non-uniform rectangular grid defined this array

%%%Default tolerance
%%% (absolute) for x is TolX = 1e-4. We should check whether we chnaged
%%% it
TolX = 1e-4;
if exist('options','var') && isfield(options,'TolX'), TolX=options.TolX; end
if ~exist('options','var'), options = []; end

if exist('MinArrayF','var'), % Have to remember how many minimums we have
  NumMins = numel(MinArrayF);
else NumMins = 0; end

%% at first we sample at the grid points
%%% lets buidl a matrix of initial guesses.
grid = AVP.CONVERT.cell2grid(x0_samples);
%%% run all guesses and collect unique minimums
for GuessI=1:size(grid,1),
  [x,fval,exitflag] = fminsearch(fun,grid(GuessI,:),options);
  if exitflag ~= 1, disp({'Guess ' num2str(grid(GuessI,:)) ' failed!'});  continue; end
  %%% see whether we already have this minimum. 
  if exist('MinArrayX','var'),
    [MinDX,Imin] = min(max(abs(MinArrayX-repmat(x,size(MinArrayX,1),1)),[],2));
    %MinDX, TolX
    if MinDX < TolX, %, probably found the same minimum, lets see whether midpoint is better
      Xmid = (MinArrayX(Imin,:)+x)/2;
      Fmid = fun(Xmid);
      % compare results
      [~,Imin] = min([MinArrayF(Imin), Fmid, fval]);
      switch Imin
        case 1 % nothing, old value is best
        case 2
          MinArrayX(Imin,:) = Xmid;
          MinArrayF(Imin) = Fmid;
        case 3
          MinArrayX(Imin,:) = x;
          MinArrayF(Imin) = fval;
      end
      continue % we do not have to add a new point
    else % found new minimum 
      MinArrayX = [MinArrayX;x];
      MinArrayF = [MinArrayF;fval];
    end
  else % initiate arrays with the first minimum
    MinArrayX = x;
    MinArrayF = fval;
  end
  disp(['Found new minimum ' num2str(fval) ' at ' num2str(x)]);
end % for GuessI

%% analysis:
%%% bad cases
if ~exist('MinArrayF','var'),
  error('Failed to find any minimums!');
end

if NumMins == numel(MinArrayF), % we have not found any new minimums, exit recursion
  % we got to find the best minimum first
  [fval,Ind] = min(MinArrayF);
  x = MinArrayX(Ind,:);
  return
end

if numel(MinArrayF) == 1, % we found just a single minimuma single minimum, 
  % nowhere else to search
  return
end

% Ok, we go to my favourite thing - recursion. We find mean point of all
% the minimums, weighted with minimum value, and rms around this point 
% (seperately for each dimension), and sample a cube around the mean with 
% third of RMS size. the we feed this cube back to fminsearch_global
W = 1./(MinArrayF.^2); % weights
for DimI =1:size(grid,2),
  X = MinArrayX(:,DimI);
  if max(X)-min(X) < TolX, % basically all minimum at one position alog this dim
    SampleCube{DimI} = mean(X);
  else  
    MeanP = sum(X.*W)./sum(W);
    RMS = sqrt(sum(W.*(X - MeanP).^2)/sum(W));
    SampleCube{DimI} = [MeanP-RMS/3,MeanP+RMS/3];
  end
end
disp(['New level, Cube = ',mat2str(MeanP,4)])
[x,fval,MinArrayX,MinArrayF] = AVP.fminsearch_global(fun,SampleCube,options,MinArrayX,MinArrayF);
% find the best minimum and return it
end

