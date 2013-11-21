% We can get "address" string from the "Device Manager" panel. Interface
% should correspond to "USB Test and Measurement Device (IVI)". Go to
% Driver Details and look at "Device Instance Path". It can be easily converted 
% to VISA rsrcname. 
classdef DG1022 < handle
  properties
    interface
  end
  methods
    function obj = DG1022()
      obj.interface = visa('ni','USB::0x1AB1::0x0588::DG1D125206149::INSTR');
      set(obj.interface,'InputBufferSize',5000)
      fopen(obj.interface)
      try 
        %fprintf(obj.interface,'*IDN?')
        %out = strtok(fscanf(obj.interface),',');
        out = regexp(obj.send('*IDN?',1),',','split');
        if ~strcmp('DG1022 ',out{2})
          error(['DG1022: Wrong device = <' out{2} '>']);
        end
      catch Err
        Err.getReport
        fclose(obj.interface)
      end
    end
    
    function delete(obj)
      fclose(obj.interface)
    end
    
    % if READ_ASCII is not specified than do not read anything,
    % if it is 1 we return ASCII, otherwise binary
    function out = send(obj,command,read_ascii)
      
      fprintf(obj.interface,command)
      if nargin > 2 
        if read_ascii ~= 0,
          [out,~,msg] = fscanf(obj.interface);
          if ~isempty(msg), error(msg); end
        else out =  fread(x.interface); end
      else out = {}; end
    end
    
  end
end
