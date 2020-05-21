function complex(y,varargin)
  AVP.opt_param('no_abs_phase',0);
  AVP.opt_param('x',1:numel(y));
  y = y(:);
  plot(x,real(y),'b-+',x,imag(y),'c-+');
  line_titles = {'real','imag'};
  if ~no_abs_phase
    held = ishold;
    if ~held, hold on; end
    plotyy(x,abs(y),x,angle(y));
    if ~held, hold off; end
    line_titles = {line_titles{:},'abs','angle'};
  end
  % AVP.PLOT.legend(line_titles);
end
