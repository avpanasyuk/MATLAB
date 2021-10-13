%> reverses "save2bytestream".
function vars = load_from_bytestream(x,varargin)
  AVP.opt_param('ConcatenateIfPossible',true);
  
  if exist('x','var') % initiate bytes source, either byte array or file
    if ischar(x), AVP.pop(x,0); else, AVP.pop(x); end
  end
  
  % read vars one by one, possibly concatenating them if
  % possible
  VarI = 1;
  while AVP.pop() ~= 0
    NewVar = pop_a_var_from_bytestream();
    if ~exist('vars','var')
      vars{VarI} = NewVar;
    else
      if ConcatenateIfPossible
        try
          vars{VarI} = [vars{VarI}; NewVar]; % see whether we can concatenate
        catch ME
          VarI = VarI + 1;
          vars{VarI} = NewVar;
        end
      else
        VarI = VarI + 1;
        vars{VarI} = NewVar;
      end
    end
  end
  if VarI == 1
    vars = vars{1};
  end
end

%> reverses "save2bytestream".
function NewVar = pop_a_var_from_bytestream()
  code = AVP.pop('char');
  switch code
    case 'v'
      NewVar = AVP.pop(AVP.pop('char',AVP.pop(1)));
    case 'z'
      type = AVP.pop('char',AVP.pop(1));
      NewVar = complex(AVP.pop(type),AVP.pop(type));
    case 's'
      for fi=1:AVP.pop(1)
        fn = AVP.pop('char',AVP.pop(1));
        NewVar.(fn) = pop_a_var_from_bytestream();
      end
    case {'a','x','c'}
      ndims = AVP.pop(1);
      sz = typecast(AVP.pop(2*ndims),'uint16');
      if code == 'c'
        NewVar = cell(double(sz(:).'));
        for n=1:prod(sz)
          NewVar{n} = pop_a_var_from_bytestream();
        end
      else
        type = AVP.pop('char',AVP.pop(1));
        NewVar = AVP.pop(type,sz);
        if code == 'x'
          NewVar = complex(NewVar,AVP.pop(type,sz));
        end
      end
    case 't'
      NewVar = AVP.pop('char',AVP.pop('uint16'));
    case 'e'
      NewVar = [];
    case 'l'
      NewVar = struct2table(pop_a_var_from_bytestream());
    otherwise
      error(['Wrong code "' code '"!'])
  end
end










