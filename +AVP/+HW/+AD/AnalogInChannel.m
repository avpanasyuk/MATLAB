classdef AnalogInChannel < handle
	%> One scope channel of an Analog Discovery. Created eagerly by @c AVP.HW.AD.dwf
	%> and accessed as @c a.In(1) / @c a.In(2) (1-based to match MATLAB conventions;
	%> the underlying SDK index is 0-based and stored in @c idx).
	%>
	%> Wraps two SDK families:
	%>   - @c FDwfAnalogInChannel*  (Enable, Filter, Range, Offset, Attenuation)
	%>   - @c FDwfAnalogInStatus*   (Data, Data16, Noise, Sample) - per-channel readers
	%> Per-channel methods drop the SDK prefix.

	properties
		parent  %>< AVP.HW.AD.dwf the channel belongs to (held by reference)
		idx     %>< 0-based channel index passed to the SDK
	end

	methods
		function c = AnalogInChannel(parent, idx)
			c.parent = parent;
			c.idx    = int32(idx);
		end

		%% --- channel-config (FDwfAnalogInChannel*) -----------------------------
		function EnableSet(c, fEnable),   c.Cfg('EnableSet', int32(logical(fEnable))); end
		function f = EnableGet(c),        f = logical(c.CfgVal('Enable', 'int32')); end
		function FilterSet(c, filter),    c.Cfg('FilterSet', int32(filter)); end
		function f = FilterGet(c),        f = c.CfgVal('Filter', 'int32'); end
		function RangeSet(c, v),          c.Cfg('RangeSet', double(v)); end
		function v = RangeGet(c),         v = c.CfgVal('Range', 'double'); end
		function OffsetSet(c, v),         c.Cfg('OffsetSet', double(v)); end
		function v = OffsetGet(c),        v = c.CfgVal('Offset', 'double'); end
		function AttenuationSet(c, x),    c.Cfg('AttenuationSet', double(x)); end
		function x = AttenuationGet(c),   x = c.CfgVal('Attenuation', 'double'); end

		%% --- per-channel status (FDwfAnalogInStatus*) -------------------------
		function data = StatusData(c, n)
			%> Read @p n scaled-volt samples for this channel from the last
			%> @c AnalogInStatus(true) snapshot.
			p = libpointer('doublePtr', zeros(n,1));
			c.Sts('Data', p, int32(n));
			data = p.Value;
		end
		function data = StatusData16(c, n)
			%> Raw 16-bit ADC samples (no scaling).
			p = libpointer('int16Ptr', zeros(n,1,'int16'));
			c.Sts('Data16', p, int32(0), int32(n));
			data = p.Value;
		end
		function [dMin, dMax] = StatusNoise(c, n)
			%> Per-bucket min/max envelope (use after setting @c FilterMinMax).
			pMin = libpointer('doublePtr', zeros(n,1));
			pMax = libpointer('doublePtr', zeros(n,1));
			c.Sts('Noise', pMin, pMax, int32(n));
			dMin = pMin.Value;
			dMax = pMax.Value;
		end
		function v = StatusSample(c)
			%> Single instantaneous sample.
			p = libpointer('doublePtr', 0);
			c.Sts('Sample', p);
			v = p.Value;
		end
	end

	methods (Access = protected)
		function Cfg(c, suffix, varargin)
			%> @c FDwfAnalogInChannel<suffix>(h, idx, varargin)
			AVP.HW.AD.dwf.callByName(['AnalogInChannel' suffix], c.parent.h, c.idx, varargin{:});
		end
		function Sts(c, suffix, varargin)
			%> @c FDwfAnalogInStatus<suffix>(h, idx, varargin)
			AVP.HW.AD.dwf.callByName(['AnalogInStatus' suffix], c.parent.h, c.idx, varargin{:});
		end
		function v = CfgVal(c, baseName, type)
			%> Sugar for @c FDwfAnalogInChannel<baseName>Get(h, idx, T*) returning a scalar.
			p = libpointer([type 'Ptr'], 0);
			c.Cfg([baseName 'Get'], p);
			v = p.Value;
		end
	end
end
