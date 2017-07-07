function Z = RCp2Z(R,Cw)
  Denom = 1 +(R.*Cw).^2;
  Z = complex(1,-Cw.*R).*R./Denom;
end
