function out = get_raw_value(phidget, index)
% function out = get_raw_value(phidget, index)
% reads 10-bit raw sensor value from INDEX (1-based) input
    out = get_value(phidget, 'getSensorRawValue', index-1);
end

