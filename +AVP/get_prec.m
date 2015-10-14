% converts precision in form, say, 'uint8' into a number of bytes
function num_bytes = get_size_of_type(type)
  num_bytes = numel(typecast(
end
