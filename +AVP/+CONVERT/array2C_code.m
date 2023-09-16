function text = array2C_code(var_name)
  %> converts an array into C code to initialize it in C file.
  x = evalin('caller',var_name)
  type = AVP.CONVERT.MLtype2C(class(x));
  switch type
    case {'float','double'}
      format = '%g';
    otherwise
      format = '%i';
  end
  text = [type ' ' var_name '[] = {' sprintf([format ', '],x(1:end-1)) ...
    sprintf(format,x(end)) '};'];
end
