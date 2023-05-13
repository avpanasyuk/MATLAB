% AD5933
classdef ad5933 < handle
  properties
    i2c
    rpi
  end
  properties(Constant)
    f_norm = 16e6/4/2^27
  end
  methods
    function b = ad5933(rpi)
      if ~exist('rpi','var'), b.rpi = AVP.HW.RPi;
      else b.rpi = rpi; end
      % disableI2C(rpi.c)
      % enableI2C(rpi.c,400000)
      b.i2c = b.rpi.i2c_dev('0x0D');
    end
    
    %% LOW LEVEL
    function delete(b)
      clear b.i2c
      delete(b.rpi)
    end
    function out = read_byte(b) % reads byte from pointed reg
      out = read(b.i2c,1);
    end
    function write_byte2reg(b,value,regI)
      write(b.i2c,[regI,value]);
    end
    function ptr2reg(b,regI)
      write(b.i2c,[bin2dec('10110000'),regI]);
    end
    function block_write(b,bytes) % writes starting with pointed reg
      write(b.i2c,[bin2dec('10100000'),numel(bytes),bytes]);
    end
    function bytes = block_read(b,n) % reads starting with pointed reg
      write(b.i2c,[bin2dec('10100001'),n]);
      bytes = read(b.i2c,n);
    end
    function set_bits_in_reg(b,reg,bits,num,pos)
      b.ptr2reg(reg);
      byte = b.read_byte();
      byte = AVP.setbits(byte,bits,num,pos,'uint8');
      % bitor(bitand(cntl_byte,bin2dec('1111')),bitshift(value,4));
      b.write_byte2reg(byte,reg);      
    end
    function set_bits_in_ctrl1(b,varargin)
      b.set_bits_in_reg(hex2dec('80'),varargin{:});
    end
    function set_bits_in_ctrl2(b,varargin)
      b.set_bits_in_reg(hex2dec('81'),varargin{:});
    end
     %% COMMANDS
   function command(b,bits)
      b.set_bits_in_ctrl1(bits,4,4);
    end
    function start_temp_sampling(b)
      b.command(bin2dec('1001'));
    end
    function init_start_freq(b)
      b.command(bin2dec('0001'));
    end
    function start_sweep(b)
      b.command(bin2dec('0010'));
    end
    function next_freq(b)
      b.command(bin2dec('0011'));
    end
    function repeat_freq(b)
      b.command(bin2dec('0100'));
    end
    function power_down(b)
      b.command(bin2dec('1010'));
    end
    function stand_by(b)
      b.command(bin2dec('1011'));
    end
    function reset(b)
      b.set_bits_in_ctrl2(1,1,4);
    end
    %% SETTINGS
    function f_true = set_freq_to_ptr(b,f)
      code = fix(f/b.f_norm);
      f_true = code*b.f_norm;
      bytes = typecast(uint32(code),'uint8');
      b.block_write(bytes(3:-1:1));
    end
    function f_true = set_freq(b,f)
      b.ptr2reg(hex2dec('82'));
      f_true = b.set_freq_to_ptr(f);
    end
    function f_true = set_freq_incr(b,f)
      b.ptr2reg(hex2dec('85'));
      f_true = b.set_freq_to_ptr(f);
    end
    function set_incr_num(b,n)
      if n >= 512, error('n is too high!'); end
      b.write_byte2reg(fix(n/256),hex2dec('88'));
      b.write_byte2reg(bitand(n,255),hex2dec('89'));
    end
    
    function set_Vrange(b,rangeI)
      b.set_bits_in_ctrl1(rangeI,2,1);
    end
    
    function set_x5_gain(b,OnOff)
      b.set_bits_in_ctrl1(uint8(~OnOff),1,0);
    end
      
    function set_ext_clk(b,OnOff) 
      b.set_bits_in_ctrl2(OnOff,1,3);
    end
    
    function set_settling_cycles(b,n)
      if n/512 < 1, b9_10 = 0; else
        if n/512 < 2, b9_10 = 1; n = n/2; else
          if n/512 < 4, b9_10 = 3; n = n/4; else
            error('n is too high!');
          end
        end
      end
      b.write_byte2reg(b9_10*2+fix(n/256),hex2dec('8A'));      
      b.write_byte2reg(bitand(n,255),hex2dec('8B'));
    end
    %% DATA
    function temp = get_temp(b)
      b.ptr2reg(hex2dec('92'));
      bytes = double(block_read(b,2));
      temp = (bytes(1)*256 + bytes(2))/32;
    end
    function [temp_valid data_valid sweep_complete status] = get_status(b)
      b.ptr2reg(hex2dec('8F'));
      status = b.read_byte();
      temp_valid = bitand(status,1) ~= 0;
      data_valid = bitand(status,2) ~= 0;
      sweep_complete = bitand(status,4) ~= 0;
    end
    function Z = get_data(b)
      b.ptr2reg(hex2dec('94'));
      bytes = double(typecast(uint8([b.read_byte,b.read_byte,b.read_byte,b.read_byte]),'int8'));
      Z = complex(bytes(1)*256+bytes(2),bytes(3)*256+bytes(4));
    end

    function test
      b.stand_by
      b.set_freq(47000)
      b.set_freq_incr(1000)
      b.set_incr_num(1)
      b.set_ext_clk(1)
      
      b.init_start_freq
      b.start_sweep
      [temp_valid data_valid sweep_complete] = get_status(b)
      b.get_data     
      b.next_freq
      b.get_data
      [temp_valid data_valid sweep_complete] = get_status(b)
      b.reset
     
    end
    
  end
end