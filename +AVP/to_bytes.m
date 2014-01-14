function bytes = to_bytes(x)
  if isreal(x), bytes = typecast(x(:).','uint8');
  else bytes = [AVP.to_bytes(real(x)),AVP.to_bytes(imag(x))];
  end
end

