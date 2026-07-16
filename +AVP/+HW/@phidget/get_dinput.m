function out = get_dinput(phidget, index)
% function out = get_dinput(phidget, index)
% reads INDEX bit (1-based) from digital input 
    out = get_value(phidget, 'getInputState', index-1);
end

