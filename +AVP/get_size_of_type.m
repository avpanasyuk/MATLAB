function num_bytes = get_size_of_type(type)
  % converts precision in form, say, 'uint8' into a number of bytes
  if strcmp(type,'char'), num_bytes = 1; else
    num_bytes = numel(typecast(cast(0,type(:).'),'uint8'));
  end
end
