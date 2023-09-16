function Ctype = MLtype2C(ML_type)
  switch ML_type
    case 'single'
      Ctype = 'float';
    otherwise
      if regexp(ML_type,".*int.*"), Ctype = [ML_type "_t"];
      else, Ctype = ML_type;
      end
  end
end
