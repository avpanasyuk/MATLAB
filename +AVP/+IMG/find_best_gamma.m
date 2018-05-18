function [img gamma] = find_best_gamma(img)
  %> finds best gamma and while checking that there is no solarization
  imgs = AVP.scale_to_range(img,[0,1]);
  gamma = fzero(@(x) mean(imgs(:).^x)-0.5,1,optimset('PlotFcns',{@optimplotx,@optimplotfval}));
  img = img.^gamma;
end
