function bounds = crop_area(y,varargin),
  %> function crop_area(y,...),
  %> returns margins inside which most of the values of X are lyeing,
  %> stripping CROP area of outliers from the both ends
  %> @param varargin
  %>   - DIVIDERS: n+1 vector x axis dividers, y are values in between them
  %>   - CROP: scalar or 2x1 vector part of total area to strip, 1% default
  
  AVP.opt_param('dividers',[1:numel(y)+1].');
  AVP.opt_param('crop',0.01);
  if numel(crop) == 1, crop = [crop; crop]; end

  AreaArr = y.*(dividers(2:end) - dividers(1:end-1));
  AreaLeft = [0; cumsum(AreaArr)];
  AreaRight = [0; cumsum(AreaArr(end:-1:1))];
  bounds(1) = AVP.find_0_in_vector(AreaLeft - AreaLeft(end)*crop(1));
  bounds(2) = numel(AreaRight) - AVP.find_0_in_vector(AreaRight - AreaRight(end)*crop(2));
end


