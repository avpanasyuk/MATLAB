function plot_fit(x,y,f,c,c_init),
% overplots fit function f=@(c,x) over data
plot(x,y,'.b'); hold on; axis manual
if nargin > 4, plot(x,f(c_init,x),'-g'); end
plot(x,f(c,x),'-r'); hold off; axis auto; 
end