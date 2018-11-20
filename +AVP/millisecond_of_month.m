function ms = millisecond_of_month()
  d = datevec(now);
  ms = ((d(3)*24 + d(4))*60 + d(5))*60 + d(6);
end
  