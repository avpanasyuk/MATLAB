function img = dng_read(filename)
  warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
  t = Tiff(filename,'r');
  offsets = getTag(t,'SubIFD');
  setSubDirectory(t,offsets(1));
  img = read(t);
  close(t);
end