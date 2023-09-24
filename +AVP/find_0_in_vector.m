function ind = find_0_in_vector(x)
  %> X should be monotonous and rising
  LeftI = 1;
  RightI = numel(x);

  if x(LeftI) > 0 || x(RightI) < 0
    error('X should be monotonous, rising and crossing 0');
  end

  while RightI - LeftI > 1
    NewI = round((LeftI + RightI)/2);
    if x(NewI) > 0, RightI = NewI; else LeftI = NewI; end
  end
  if x(RightI) == x(LeftI)
    ind = (LeftI + RightI)/2;
  else
    ind = LeftI - x(LeftI)/(x(RightI) - x(LeftI));
  end
end

