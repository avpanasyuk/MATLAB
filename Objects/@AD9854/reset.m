function reset(obj)
putvalue(obj.parport.Master_Reset,1); % wait 10 SYSCLK
putvalue(obj.parport.Master_Reset,0); % wait 10 SYSCLK - oh, well
end

