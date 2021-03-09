function sz = size_of_type(type)
  sz = AVP.sizeof(zeros(1,1,type(:).'));
end