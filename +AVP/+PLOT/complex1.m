function complex1(y,varargin)
  %> because scale of all plots is different let's use subplots
  AVP.opt_param('x',1:size(y,1),1);
  AVP.opt_param('funcArr',{@real,@imag,@abs,@angle},1);
  
  for fI=1:numel(funcArr)
    subplot(numel(funcArr),1,fI);
    plot(x,funcArr{fI}(y),varargin{:});
    ylabel(func2str(funcArr{fI}))
  end  
end
