% adds variable(s) to file
function AddTo(name,x)
  f = fopen(name,'a');
  fwrite(f,AVP.CONVERT.save2bytestream(x));
  fclose(f);
end