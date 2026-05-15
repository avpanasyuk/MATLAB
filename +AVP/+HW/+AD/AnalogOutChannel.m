classdef AnalogOutChannel < handle
	%> One wavegen channel of an Analog Discovery. Created eagerly by @c AVP.HW.AD.dwf
	%> and accessed as @c a.Out(1) / @c a.Out(2). Stores its 0-based SDK index in @c idx.
	%>
	%> Wraps two SDK families:
	%>   - @c FDwfAnalogOut*(idx, ...)        - channel-level (Reset, Configure, Status,
	%>                                          Run, Wait, Repeat, Trigger, Idle, Mode)
	%>   - @c FDwfAnalogOutNode*(idx, node, ...)  - per-node (Enable, Function, Frequency,
	%>                                              Amplitude, Offset, Symmetry, Phase, Data)
	%> Node-level methods keep the @c Node prefix and take a @c node argument
	%> (@c AVP.HW.AD.dwf.AnalogOutNodeCarrier / @c FM / @c AM).

	properties
		parent  %>< AVP.HW.AD.dwf the channel belongs to
		idx     %>< 0-based channel index passed to the SDK
	end

	methods
		function c = AnalogOutChannel(parent, idx)
			c.parent = parent;
			c.idx    = int32(idx);
		end

		%% --- channel-level (FDwfAnalogOut*) ------------------------------------
		function Reset(c),                     c.Chn('Reset'); end
		function Configure(c, fStart),         c.Chn('Configure', int32(logical(fStart))); end
		function sts = Status(c)
			p = libpointer('uint8Ptr', uint8(0));
			c.Chn('Status', p);
			sts = double(p.Value);
		end
		function RunSet(c, sec),               c.Chn('RunSet', double(sec)); end
		function sec = RunGet(c),              sec = c.ChnVal('Run', 'double'); end
		function WaitSet(c, sec),              c.Chn('WaitSet', double(sec)); end
		function sec = WaitGet(c),             sec = c.ChnVal('Wait', 'double'); end
		function RepeatSet(c, n),              c.Chn('RepeatSet', int32(n)); end
		function n = RepeatGet(c),             n = c.ChnVal('Repeat', 'int32'); end
		function TriggerSourceSet(c, trigsrc), c.Chn('TriggerSourceSet', uint8(trigsrc)); end
		function TriggerSlopeSet(c, slope),    c.Chn('TriggerSlopeSet', int32(slope)); end
		function IdleSet(c, idle),             c.Chn('IdleSet', int32(idle)); end
		function ModeSet(c, mode),             c.Chn('ModeSet', int32(mode)); end %>< Voltage/Current; ADP-only on AD1

		%% --- per-node (FDwfAnalogOutNode*) -------------------------------------
		function NodeEnableSet(c, node, fEnable)
			c.Nde('EnableSet', node, int32(logical(fEnable)));
		end
		function NodeFunctionSet(c, node, func), c.Nde('FunctionSet',  node, uint8(func));  end
		function NodeFrequencySet(c, node, hz),  c.Nde('FrequencySet', node, double(hz));   end
		function NodeAmplitudeSet(c, node, v),   c.Nde('AmplitudeSet', node, double(v));    end
		function NodeOffsetSet(c, node, v),      c.Nde('OffsetSet',    node, double(v));    end
		function NodeSymmetrySet(c, node, pct),  c.Nde('SymmetrySet',  node, double(pct));  end
		function NodePhaseSet(c, node, deg),     c.Nde('PhaseSet',     node, double(deg));  end
		function NodeDataSet(c, node, samples)
			%> Upload a custom waveform; samples in [-1,1] are scaled by the
			%> channel's amplitude/offset. Implies @c funcCustom on the node.
			samples = double(samples(:));
			c.Nde('DataSet', node, samples, int32(numel(samples)));
		end
	end

	methods (Access = protected)
		function Chn(c, suffix, varargin)
			%> @c FDwfAnalogOut<suffix>(h, idx, varargin)
			AVP.HW.AD.dwf.callByName(['AnalogOut' suffix], c.parent.h, c.idx, varargin{:});
		end
		function Nde(c, suffix, node, varargin)
			%> @c FDwfAnalogOutNode<suffix>(h, idx, node, varargin)
			AVP.HW.AD.dwf.callByName(['AnalogOutNode' suffix], ...
				c.parent.h, c.idx, int32(node), varargin{:});
		end
		function v = ChnVal(c, baseName, type)
			p = libpointer([type 'Ptr'], 0);
			c.Chn([baseName 'Get'], p);
			v = p.Value;
		end
	end
end
