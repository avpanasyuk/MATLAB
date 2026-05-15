classdef AnalogIOChannel < handle
	%> One AnalogIO channel of an Analog Discovery (the per-channel "supply"
	%> grouping inside @c FDwfAnalogIO*). On AD1 these are @c V+, @c V- and the
	%> USB monitor. Each channel exposes a fixed set of nodes (Enable, Voltage,
	%> Current, ...) discovered via @c NodeCount.
	%>
	%> Created eagerly by @c AVP.HW.AD.dwf and accessed as @c a.IO(k). All node
	%> indices are 0-based and passed straight to the SDK.

	properties
		parent  %>< AVP.HW.AD.dwf the channel belongs to
		idx     %>< 0-based channel index passed to the SDK
	end

	methods
		function c = AnalogIOChannel(parent, idx)
			c.parent = parent;
			c.idx    = int32(idx);
		end

		function s = Name(c)
			%> Human-readable channel name from the SDK (e.g. @c "Positive Supply").
			pName  = libpointer('cstring', blanks(32));
			pLabel = libpointer('cstring', blanks(16));
			AVP.HW.AD.dwf.callByName('AnalogIOChannelName', ...
				c.parent.h, c.idx, pName, pLabel);
			s = strtrim(pName.Value);
		end

		function n = NodeCount(c)
			p = libpointer('int32Ptr', int32(0));
			AVP.HW.AD.dwf.callByName('AnalogIOChannelInfo', c.parent.h, c.idx, p);
			n = double(p.Value);
		end

		function NodeSet(c, idxNode, value)
			%> Write a node (e.g. enable=1, voltage=3.3) on this channel.
			c.Nde('Set', idxNode, double(value));
		end
		function v = NodeGet(c, idxNode)
			%> Read back a node's commanded value.
			p = libpointer('doublePtr', 0);
			c.Nde('Get', idxNode, p);
			v = p.Value;
		end
		function v = NodeStatus(c, idxNode)
			%> Read a node's measured/status value (after @c AnalogIOStatus refresh).
			p = libpointer('doublePtr', 0);
			c.Nde('Status', idxNode, p);
			v = p.Value;
		end
	end

	methods (Access = protected)
		function Nde(c, suffix, idxNode, varargin)
			%> @c FDwfAnalogIOChannelNode<suffix>(h, idxChannel, idxNode, varargin)
			AVP.HW.AD.dwf.callByName(['AnalogIOChannelNode' suffix], ...
				c.parent.h, c.idx, int32(idxNode), varargin{:});
		end
	end
end
