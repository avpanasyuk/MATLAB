function g = GrayCode(n)
  %> @param n - 0-based index
  g = bitxor(n,fix(n/2));
end

function test
  for i=0:15, disp(dec2bin(AVP.GrayCode(i),4)); end
end