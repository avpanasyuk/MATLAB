function p = demod_ratio(x,carrier,shift)
  if size(x,2) > 1
    carrier = repmat(carrier,1,size(x,2));
  end
  p = complex(mean(x.*carrier),mean(x.*circshift(carrier,shift)))./...
    mean(carrier.^2);
end