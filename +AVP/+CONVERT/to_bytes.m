function bytes = to_bytes(x)
  if isstr(x) || islogical(x), bytes = uint8(x); else
    if isa(x,'function_handle')
      bytes = AVP.CONVERT.something2bytes(functions(x));
    else
      if isreal(x), bytes = typecast(x(:).','uint8');
      else bytes = [AVP.CONVERT.to_bytes(real(x)),AVP.CONVERT.to_bytes(imag(x))];
      end
    end
  end
end

