function home_dir = get_home_dir
  if ispc
      home_dir=getenv('USERPROFILE');
  else
      home_dir=getenv('HOME');
  end
end
