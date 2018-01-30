
function key = getkey(varargin)
  AVP.opt_param('Prompt','PAUSED, PRESS KEY ...\n',true);
  fprintf(Prompt);
  key = CONTRIB.getkey(varargin{:});
  fprintf(repmat('\b',1,numel(Prompt)));
end

