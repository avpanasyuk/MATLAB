classdef Param
  properties (Access=protected)
    Device
    Name
    Type
  end

  properties( GetAccess=public, SetAccess=protected)
    Range % [min, max]
    Steps % numsteps if numel == 1 or steps themselves
    Value % to update from device call Refresh
  end
  
  methods
    function a = Param(Device,Name, Type)
      a.Device = Device;
      a.Name = Name;
      a.Type = Type;
      a.Info();
    end % constructor

    function Refresh(a)
      a.Value = a.Device.GetValueByName(a.Name, a.Type);
    end

    function Set(a, value)
      a.SetValueByName(a.Name, value);
      a.Refresh();
    end
  end %methods

  methods (Access=protected)
    function Info(a)
      pmin = libpointer('doublePtr',0);
      pmax = libpointer('doublePtr',0);
      psteps = libpointer('doublePtr',0);
      a.CallByName('Info', pmin, pmax, psteps);
      a.Range(1) = pmin.Value;
      a.Range(2) = pmax.Value;
      a.Steps = psteps.Value;      
    end % Info
    function varargout = Call(a,Suffix, varargin)
      [Varargout{1:nargout}] = a.Device.CallByName([a.Name,Suffix],varargin{:});
    end
  end
end % classdef ParamGroup