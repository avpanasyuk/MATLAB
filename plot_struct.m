function plot_struct(S,Xi,Nhor,Ihor),
if nargin < 4, 
  Ihor = 1;
  if nargin < 3,
    Nhor = 1;
  end
end
n = fieldnames(S);
for ni=1:length(n),
  subplot(length(n),Nhor,Ihor+Nhor*(ni-1));
  plot(S.(n{Xi}),S.(n{ni})(:,1))
  ylabel(n{ni})
end
end

