classdef fifo < handle
  properties
    Buffer
    CurI
  end

  methods
    function a = fifo(bytes)
      a.Buffer = uint8(bytes(:));
      a.CurI = 1;
    end

    function out = pop(a,n,datatype)
      if ~exist('datatype','var'), datatype = 'uint8'; end
      if ~exist('n','var'), n = 1; end


      if strcmp(datatype, 'uint8')
        if n > a.remains()
          error('Not enough bytes to pop from!');
        end

        out = a.Buffer(a.CurI:a.CurI + n - 1);
        a.CurI = a.CurI +  1;
      else
        out = typecast(pop(a, n*AVP.size_of_type(datatype)), datatype);
      end
    end

    function n = remains(a)
      n = numel(a.Buffer) - a.CurI + 1;
    end
  end
end % classdef fifo