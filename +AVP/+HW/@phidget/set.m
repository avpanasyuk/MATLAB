function set(phidget,index,state)
% function set(phidget,index,state)
% sets INDEX bit (1-based) on digital output to STATE 
    call(phidget,'setOutputState',index-1,state)
end
