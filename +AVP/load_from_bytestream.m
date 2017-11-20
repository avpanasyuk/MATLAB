%> reverses "save2bytestream".
function var = load_from_bytestream(bytes)
  if exist('bytes','var'), AVP.pop(bytes); end
  
  code = AVP.pop('char');
  switch code
    case 'v'
      var = AVP.pop(AVP.pop('char',AVP.pop(1)));
    case 'z'
      type = AVP.pop('char',AVP.pop(1));
      var = complex(AVP.pop(type),AVP.pop(type));
    case 's'
      for fi=1:AVP.pop(1)
        fn = AVP.pop('char',AVP.pop(1));
        var.(fn) = AVP.load_from_bytestream();
      end
    case {'a','x','c'}
      ndims = AVP.pop(1);
      sz = typecast(AVP.pop(2*ndims),'uint16');
      if code == 'c'
        var = cell(double(sz));
        for n=1:prod(sz)
          var{n} = AVP.load_from_bytestream();
        end
      else
        type = AVP.pop('char',AVP.pop(1));
        var = AVP.pop(type,sz);
        if code == 'x'
          var = complex(var,AVP.pop(type,sz));
        end
      end
    case 't'
      var = AVP.pop('char',AVP.pop('uint16'));
    case 'e'
      var = [];
    case 'l'
      var = struct2table(AVP.load_from_bytestream(AVP.pop(AVP.pop('uint32'))));
    otherwise
      error(['Wrong code "' code '"!'])
  end
end





