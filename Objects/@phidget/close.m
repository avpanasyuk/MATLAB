function close(obj)
calllib('plib','CPhidget_close',obj.handle);
calllib('plib','CPhidget_delete',obj.handle);
unloadlibrary plib;
end
