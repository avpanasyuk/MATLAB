% converts precision in form, say, 'uint8' into a number of bytes
% converts precision in form, say, 'uint8' into a number of bytes
function prec = get_prec
  prec.uint8 = 1;
  prec.uint16 = 2;
  prec.uint32 = 4;
  prec.int8 = 1;
  prec.int16 = 2;
  prec.int32 = 4;
end
