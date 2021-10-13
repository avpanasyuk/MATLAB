function out = typecast_mat2types(x,num_bytes,type)
  %> typecasts byte matrics with columns being repeated byte sequences of
  %> the same format to typecasted value rows one value of given type and
  %> size after another
  %> The initial call is typecast_mat2types() to reset byte counter
  persistent start_byte_row
  
  if nargin == 0, start_byte_row = 1; out = [];
  else
    out = AVP.typecast(x(start_byte_row:start_byte_row+num_bytes-1,:),type);
    start_byte_row = start_byte_row + num_bytes;
  end
end