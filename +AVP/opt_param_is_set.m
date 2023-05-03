function Set = opt_param_is_set(name,Varargin)
  if ~exist('Varargin','var')
    Varargin = evalin('caller','varargin');
  end
  [Present, Place] = AVP.opt_param_present(name,Varargin);
  Set = Present && Varargin{2*Place};
end
