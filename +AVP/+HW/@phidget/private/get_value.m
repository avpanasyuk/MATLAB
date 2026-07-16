function out = get_value(phidget, name, index)
    pVal = libpointer('int32Ptr',0);
    call(phidget,name,index, pVal);
    out = get(pVal,'Value');
end

