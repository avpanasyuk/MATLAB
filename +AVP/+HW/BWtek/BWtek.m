% exp may be number in milliseconds, 'auto' for autoexposure and 'auto_bg'
% for autoexposure and background subtraction

function [counts,Exposure,wl] = BWtek(exp,cmd)
global BWtek_wl BWtek_exp

% we store x, px and wl not to creare them again every time
% we store exp so that automatic BWtek_wl control knows where to start from
MinExp = 9; MaxExp = 65535; MaxLevel = 60000;
if isempty(BWtek_wl)
    [counts t BWtek_wl] = bwtekc(MinExp);
    BWtek_exp = MinExp; % set BWtek_exp to minimum
end
if nargin() == 0, exp = BWtek_exp; end
if nargin() < 2, cmd = @pause; end

if ischar(exp) 
    if(strcmpi('auto',exp) || strcmpi('auto_bg',exp))
        while 1
           [counts,BWtek_exp] = bwtekc(BWtek_exp);
           BWtek_exp = double(BWtek_exp);
           MaxC = double(max(counts));
           if MaxC > MaxLevel % saturation
               if BWtek_exp ~= MinExp,
                   BWtek_exp = max(BWtek_exp/4,MinExp);
               else
                   break
                   % error('Light is too strong, can not select BWtek_exp without saturation!')
               end
           elseif MaxC < MaxLevel/4, % underexposure
               if  BWtek_exp ~= MaxExp
                   BWtek_exp = min(BWtek_exp*MaxLevel/2/MaxC, MaxExp); 
               else, break, end
           else, break, end
        end
        if strcmpi('auto_bg',exp)
            disp('Measuring background level, close fiber and press any key to start...');
            cmd()
            bg = BWtek(BWtek_exp);
            counts = max(counts - bg,0);
        end 
    else
        if strcmpi('close',exp)
            BWtek_wl = [];
            clear bwtekc
            return
        else
            if strcmpi('cont',exp)
                while(1), plot(BWtek_wl,BWtek('auto')), drawnow, end
            end
        end
    end        
else BWtek_exp = exp; counts = bwtekc(exp); end
Exposure = BWtek_exp;
wl = BWtek_wl;
end

