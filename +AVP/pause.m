
function pause(varargin)
  AVP.opt_param('prompt','PAUSED, PRESS ANY KEY ...',1);
  fprintf([prompt '\n'])
  pause(varargin{:});
  fprintf(repmat('\b',1,numel(prompt)+1))
end

