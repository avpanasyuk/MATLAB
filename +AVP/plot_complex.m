function plot_complex( y, varargin )
%PLOT_COMPLEX Summary of this function goes here
%   Detailed explanation goes here

plot([real(y), imag(y)],varargin{:});
end

