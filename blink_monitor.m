% picks up the best exposure value for sumix. It automatically selects 
% FRAME or SNAPSHOT mode and changes only exposure - the rest of parameters
% (like FREQUENCY, GAIN and SNAPEXPMULT should be set before)

function blink_monitor(cam,varargin),
     while 1,
         image(auto_exp(cam,varargin{:}))
         text(100,100,num2str(sumix(cam,'Exposure')))
         drawnow
     end
end

        
        
        
        
