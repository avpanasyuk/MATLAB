function out = get_doutput(phidget, index)
% function out = get_doutput(phidget, index)
% reads INDEX bit (1-based) from digital output 
    out = get_value(phidget, 'getOutputState', index-1);
end

