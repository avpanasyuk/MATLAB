function set_light(phidget,state,light)
    call(phidget,'setOutputState',light,state)
end
