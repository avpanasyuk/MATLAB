function out = AoS2SoA(x)
  names = fieldnames(x);
  for fi=1:numel(names)
 %   if isnumeric(x(1).(names{fi})) && numel(x(1).(names{fi})) == 1
    if numel(x(1).(names{fi})) == 1
      out.(names{fi}) = reshape([x.(names{fi})],size(x));
    end
  end
end

      
      