function does = has_member_func(class_name_or_obj,func_name)
  if isstr(class_name_or_obj)
    mc = meta.class.fromName(class_name_or_obj);
  else
    mc =  metaclass(class_name_or_obj);
  end
  
  mnames = {mc.MethodList.Name};
  does = any(strcmp(mnames,func_name));  
end
