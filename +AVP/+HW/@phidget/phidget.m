% this object initializes phidget board

function obj = phidget()
    % initialize phidget thingy
    if strcmp(getenv('PROCESSOR_ARCHITECTURE'),'x86'),
        libname='phidget21_32';
    else libname='phidget21_64'; end
    eval(['loadlibrary ',libname,' phidget21Matlab.h alias plib'])
    
    handle_ptr = libpointer('int32Ptr',0);
    calllib('plib', 'CPhidgetInterfaceKit_create', handle_ptr);
    s.handle = get(handle_ptr, 'Value');
    calllib('plib', 'CPhidget_open',s.handle, -1);
	
	% now we should wait until phidget gets connected, say, 10 seconds
    waited = 0; wait_step = 100;
    while calllib('plib', 'CPhidget_waitForAttachment',s.handle,wait_step) ~= 0,
		drawnow
		waited = waited + wait_step;
		if waited > 10000, error('Can not open phidget - timeout occured!'), end
    end
    
    obj = class(s,'phidget');
end
    
    
    

