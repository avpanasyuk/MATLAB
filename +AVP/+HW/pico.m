classdef pico < handle
  properties
    h = []
    unitSerial
    variant
    DriverData
  end

  methods
    function obj = pico()
      archStr = computer('arch');

      ps2000MFile = str2func(strcat('ps2000MFile_', archStr));
      ps2000WrapMFile = str2func(strcat('ps2000WrapMFile_', archStr));

      % Only load library once
      if ~libisloaded('ps2000')
        [ps2000NotFound, ps2000Warnings] = loadlibrary('ps2000.dll', ps2000MFile);
        if ~isempty(ps2000NotFound)
        end
      end
      if ~libisloaded('ps2000Wrap')
        [ps2000NotFound, ps2000Warnings] = loadlibrary('ps2000Wrap.dll', ps2000WrapMFile);
      end

      % Load in enumeration and structure information
      % =============================================

      [~, obj.DriverData.structs, obj.DriverData.enums, ~] = ps2000MFile();
      % Constants from ps2000.h header file
      % ---------------------------------------


      fprintf('Opening PicoScope 2000 Series device...\n\n');

      obj.h = calllib('ps2000', 'ps2000_open_unit');

      % Verify obj.h returned
      if(obj.h == -1)
        error('Oscilloscope failed to open.');
      elseif(obj.h == 0)
        error('No oscilloscope found.');
      else
        % Display object information
        % Obtain serial number
        infoline = blanks(40);

        [infoLength, obj.unitSerial]  = calllib('ps2000', ...
          'ps2000_get_unit_info', obj.h, infoline, ...
          length(infoline), PicoStatus.PICO_BATCH_AND_SERIAL);

        % Set variant and channel count information

        infoLineVariant = blanks(40);

        [infoLength, obj.variant]  = calllib('ps2000', ...
          'ps2000_get_unit_info', obj.h, infoLineVariant, ...
          length(infoline), PicoStatus.PICO_VARIANT_INFO);
      end
      % libfunctionsview ps2000
      % libfunctionsview ps2000Wrap
    end % constructor

    function delete(obj)
      % This function is called before the object is disconnected.
      % OBJ is the device object.
      % End of function definition - DO NOT EDIT
        if isempty(obj.h)
          return;
        end

        disconnectStatus = calllib('ps2000', 'ps2000_close_unit', obj.h);

        if(disconnectStatus)
          fprintf(['Connection to PicoScope %s with serial number %s ' ...
            'closed successfully.\n'], obj.variant, obj.unitSerial);
        elseif(obj.h == 0)
          return;
        else
          error(['Connection to PicoScope %s with serial number %s ' ...
            'not closed. Status code %d\n'], ...
            obj.variant, obj.unitSerial, disconnectStatus);
        end
    end % delete

    function set_channel(obj, channel_ID, do_enable, coupling, range)
      %> @param channel_ID - index or ? string from DriverData.enums.enPS2000Channel.PS2000_CHANNEL_?
      %> @param do_enable - bool
      %> @param coupling - true:DC, false:AC
      %> @param range - index or ??? string from DriverData.enums.enPS2000Range.PS2000_???
      if ischar(channel_ID), channel_ID = obj.DriverData.enums.enPS2000Channel.(['PS2000_CHANNEL_' channel_ID]); end
      if ischar(range), range = obj.DriverData.enums.enPS2000Range.(['PS2000_' range]); end

      if ~calllib('ps2000', 'ps2000_set_channel', obj.h, channel_ID, do_enable, coupling, range)
        error('ps2000_set_channel failed!');
      end
    end % set_channel

    function set_trigger(obj, source, threshold, direction, delay, auto_trigger_ms)
      %> @param source - index or ??? string from DriverData.enums.enPS2000Channel.PS2000_???
      %> @param threshold - value in 16-bit ADC counts
      %> @param direction - index or ??? string from DriverData.enums.enPS2000ThresholdDirection.PS2000_???
      %> @param delay - % of requested number of data points between, -
      %>    trigger and block start, -100 to 100%

      if ischar(source), source = obj.DriverData.enums.enPS2000Channel.(['PS2000_' source]); end
      if ischar(direction), direction = obj.DriverData.enums.enPS2000ThresholdDirection.(['PS2000_' direction]); end

      if ~calllib('ps2000', 'ps2000_set_trigger', obj.h, source, threshold, direction, delay, auto_trigger_ms)
        error('set_trigger failed!');
      end
    end % set_trigger

    function stop(obj)
      if ~calllib('ps2000', 'ps2000_stop', obj.h)
        error('set_trigger failed!');
      end
    end
end % methods
end % pico
