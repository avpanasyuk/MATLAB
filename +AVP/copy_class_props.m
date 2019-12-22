function copy_class_props(to_name,from)
  % used in class constructor to copy fields from another structure
  fn = evalin('caller',['fieldnames(',to_name,')']);
  for fi=1:numel(fn)
    if isprop(from,fn{fi})
      assignin('caller','copy_class_props_temp',from.(fn{fi}));
      evalin('caller',[to_name,'.',fn{fi},...
        '=copy_class_props_temp; clear copy_class_props_temp']);
  end
end
