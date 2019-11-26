classdef EEPROM < handle
  %> format of every record is stored on writing and restored on reading.
  %> Every record is checksummed
  properties
    Pos = 0; % current read/write position
    CS = double(0); % because operations with uint8 are totally inconsistent
    read_bytes_func = @() error('Should be redefined!') %>< bytes = func(pos,size)
    write_bytes_func = @() error('Should be redefined!') %>< func(pos,bytes)
  end % properties
  
  methods
    function a = EEPROM(read_bytes_func, write_bytes_func)
      a.read_bytes_func = read_bytes_func;
      a.write_bytes_func = write_bytes_func;
    end  % constructor   
    
    function SetPos(a,pos)
      a.Pos = pos;
    end
    
    function write(a,bytes)
      a.write_bytes_func(a.Pos,bytes);
      a.Pos = a.Pos + numel(bytes);
      a.CS = mod(sum([a.CS;bytes(:)]),256);
    end % write
    
    function bytes = read(a,num)
      bytes = a.read_bytes_func(a.Pos,num);
      a.Pos = a.Pos + num;
      a.CS = mod(sum([a.CS;bytes(:)]),256);     
    end % read
    
    function store(a,thing)
      a.CS = 0;
      bytes = AVP.CONVERT.save2bytestream(thing);
      a.write(typecast(uint32(numel(bytes)),'uint8')); % size
      a.write(bytes); % data
      a.write(uint8(255-a.CS)); % cs is written in negative, so zero filed does not pass checksumming
      % when written, the value of CS itself is not stored in the CS
    end % store
    
    function thing = retrieve(a)
      a.CS = 0;
      num_bytes = typecast(a.read(4),'uint32'); % size
      thing = AVP.load_from_bytestream(a.read(num_bytes)); % data
      stored_CS = a.read(1); % now a.CS contains stored_CS as well
      if(mod(a.CS - stored_CS,255) ~= 255 - stored_CS)
        error('Checksum failed!');
      end
    end % retrieve
  end % methods
end % classdef EEPROM