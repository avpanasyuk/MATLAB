classdef RPi < handle
  properties
    c
    i2c
    i2c_IDs
  end
  methods
    function r = RPi
      r.c = raspi();
      r.i2c = r.c.AvailableI2CBuses;
      if numel(r.i2c) > 1, error('More then one bus!'); end
      r.i2c_IDs = scanI2CBus(r.c, r.i2c{1});
      disp('Devices present with IDs:')
      disp(r.i2c_IDs)
    end
    
    function d = i2c_dev(r, ID)
      if ~any(strcmp(ID, r.i2c_IDs)), error('No such i2c device!'); end
      d = i2cdev(r.c, r.i2c{1}, ID);        
    end
    
    function delete(r)
      delete(r.c)
    end
  end
end