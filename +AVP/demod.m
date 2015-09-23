function x = demod(x,carrier,shift)
  if size(x,2) > 1
    carrier = repmat(carrier,1,size(x,2));
  end
  x = complex(mean(x.*carrier),mean(circshift(x,shift).*carrier));
end