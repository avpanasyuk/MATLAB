%> @brief convert any variable into bytes along with format information.
%> @param x - possibly nested numeric and string variables,
%> (cell) arrays and structs of them, nothing else
function bytes = save2bytestream(x)
  if iscell(x)
    bytes = [uint8(['c',ndims(x)]),...
      typecast(uint16(size(x)),'uint8')];
    for n=1:numel(x),
      bytes = [bytes,AVP.CONVERT.save2bytestream(x{n})];
    end
  else
    if isstruct(x)
      fn = fieldnames(x);
      bytes = [uint8(['s',numel(fn)])];
      for fi=1:numel(fn)
        bytes = [bytes,uint8([numel(fn{fi}),fn{fi}])];
        bytes = [bytes,AVP.CONVERT.save2bytestream(getfield(x,fn{fi}))];
      end
    else
      if isstr(x)
        bytes = [uint8('t'),typecast(uint16(numel(x)),'uint8')];
        bytes = [bytes,AVP.CONVERT.to_bytes(uint8(x))];
      else
        if istable(x)
          b = AVP.CONVERT.save2bytestream(table2struct(x,'ToScalar',true));
          bytes = [uint8('l'),AVP.CONVERT.to_bytes(uint32(numel(b))),b];
        else
          if numel(x) == 0, bytes = uint8('e'); else
            type = class(x(1));
            if numel(x) ~= 1
              if isreal(x(1))
                code = 'a';
              else
                code = 'x';
              end
              bytes = [uint8([code,ndims(x)]),...
                typecast(uint16(size(x)),'uint8')];
            else
              if isreal(x(1))
                code = 'v';
              else
                code = 'z';
              end
              bytes = uint8(code);
            end
            bytes = [bytes,uint8([numel(type),type]), AVP.CONVERT.to_bytes(x)];
          end
        end
      end
    end
  end
end





