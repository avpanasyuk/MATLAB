% We can get "address" string from the "Device Manager" panel. Interface
% should correspond to "USB Test and Measurement Device (IVI)". Go to
% Driver Details and look at "Device Instance Path". It can be easily converted 
% to VISA rsrcname. 
classdef DS1052E < handle
  properties
    interface
  end
  methods
    function obj = DS1052E()
      obj.interface = visa('ni','USB::0x1AB1::0x0588::DS1ED122608527::INSTR');
      set(obj.interface,'InputBufferSize',5000)
      fopen(obj.interface)
      try 
        %fprintf(obj.interface,'*IDN?')
        %out = strtok(fscanf(obj.interface),',');
        out = regexp(obj.send('*IDN?',1),',','split');
        if ~strcmp('DS1052E',out{2})
          error(['DS1052E: Wrong device = ' out{2}]);
        end
        fprintf(obj.interface,'*RST')
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
    
    %% OK, now translate major commands
    function auto(obj), obj.send(':AUTO'); end
    
    %% type could be 'NORM'al, 'AVER'age or 'PEAK'detect. If missing then query
    function out = ACQtype(obj,type)
      if nargin < 2, out = obj.send(':ACQ:TYPE?'); 
      else obj.send([':ACQ:TYPE ' type]); end
    end
    
    function out = ACQaverage(obj,power2)
      if nargin < 2, out = obj.send(':ACQ:AVER?'); 
      else obj.send([':ACQ:AVER ' int2str(2^power2)]); end
    end    
  end
end
