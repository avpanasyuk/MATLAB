function out = get_analog(phidget, index)
% function out = get_analog(phidget, index)
% reads 10-bit value from INDEX (1-based) analog input
    out = get_value(phidget, 'getSensorValue', index-1);
end

