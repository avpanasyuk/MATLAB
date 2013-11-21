function out = get_cal_temp(phidget,index)
    out = (double(get_raw_value(phidget,index))/4095*5.-0.5)/0.04;
end
