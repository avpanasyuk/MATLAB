function Z = RCp2Z(R,Cw)
  Denom = 1+(R.*Cw).^2;
  Z = complex(R./Denom,-Cw./Denom);
end
