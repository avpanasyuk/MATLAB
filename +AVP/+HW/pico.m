classdef pico < handle
  %> typical use:
  %> - block mode, without continous acquision
  %> p = AVP.HW.pico()
  %> p.set_channel('A',true,'range','50MV')
  %> p.set_sig_gen_built_in(0,600000,'SINE',1000) to run generator
  %> p.set_trigger()
  %> [bufferTimes, bufferCh, numDataValues, overflow] = p.get_samples(1e4, 1000, 'auto',1);
  properties
    h = []
    unitSerial
    variant
    DriverData
    MinSamplingInterval_ns
    Channel = repmat(struct('Range',0,'Coupling',true),2,1) % if Range == 0 the chanenel is disabled
    % Coupling == true corresponds to DC
  end

  properties(Constant)
    ValidRange = [2,10]
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

        % lets determine a minimum sampling interval_ns
        obj.MinSamplingInterval_ns = get_timebase(obj, 0, 1, 10);
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

    function set_channel(obj, channel_ID, do_enable, varargin)
      %> @param channel_ID - 0-based index or ? string from DriverData.enums.enPS2000Channel.PS2000_CHANNEL_?
      %> @param do_enable - bool
      %> @param varargin
      %>           coupling - true:DC, false:AC
      %>           range - a code in obj.ValidRange or ??? string from DriverData.enums.enPS2000Range.PS2000_???
      %>             between '50MV" and '20V'
      if ischar(channel_ID), channel_ID = obj.DriverData.enums.enPS2000Channel.(['PS2000_CHANNEL_' channel_ID]); end
      AVP.opt_param('coupling', obj.Channel(channel_ID+1).Coupling);
      if obj.Channel(channel_ID+1).Range % if channel is enabled already
        AVP.opt_param('range', obj.Channel(channel_ID+1).Range);
      else
        AVP.opt_param('range', '5V');
      end

      if ischar(range), range = obj.DriverData.enums.enPS2000Range.(['PS2000_' range]); end
      if range < obj.ValidRange(1) || range > obj.ValidRange(2), error('Wrong range!'); end

      if do_enable
        obj.Channel(channel_ID+1).Range = range;
      else
        obj.Channel(channel_ID+1).Range = 0;
      end

      obj.Channel(channel_ID+1).Coupling = coupling;

      if ~calllib('ps2000', 'ps2000_set_channel', obj.h, channel_ID, do_enable, coupling, range)
        error('ps2000_set_channel failed!');
      end
    end % set_channel

    function set_trigger(obj, varargin)
      %> @param varargin
      %>           source - 0-based index or ??? string from DriverData.enums.enPS2000Channel.PS2000_???
      %>           thresh - value in 16-bit ADC counts
      %>           direction - 0-based index or ??? string from DriverData.enums.enPS2000TriggerDirection.PS2000_???
      %>           delay - % of requested number of data points between, -
      %>             trigger and block start, -100 to 100%. Thus, 0% means that the trigger event is at the
      %>             first data value in the block, and -50% means that it is in the middle of the
      %>             block.
      %>           auto_trigger_ms -  the delay in milliseconds after which the oscilloscope
      %>             will collect samples if no trigger event occurs. If this is set to zero the
      %>             oscilloscope will wait for a trigger indefinitely.
      AVP.opt_param('source','NONE');
      if ischar(source), source = obj.DriverData.enums.enPS2000Channel.(['PS2000_' source]); end
      AVP.opt_param('thresh',0);
      AVP.opt_param('direction','RISING');
      if ischar(direction), direction = obj.DriverData.enums.enPS2000TriggerDirection.(['PS2000_' direction]); end
      AVP.opt_param('delay',0);
      AVP.opt_param('auto_trigger_ms',0);
      if ~calllib('ps2000', 'ps2000_set_trigger', obj.h, source, thresh, direction, delay, auto_trigger_ms)
        error('set_trigger failed!');
      end
    end % set_trigger

    function stop(obj)
      if ~calllib('ps2000', 'ps2000_stop', obj.h)
        error('obj failed!');
      end
    end % stop

    function set_sig_gen_built_in(obj, offsetVoltage, pkToPk, waveType, startFrequency, varargin)
      %> @param waveType - 0-based index or ??? string from DriverData.enums.enPS2000WaveType.PS2000_???
      %> @param varargin
      if ischar(waveType), waveType = obj.DriverData.enums.enPS2000WaveType.(['PS2000_' waveType]); end
      AVP.opt_param('stopFrequency', startFrequency);
      % if stopFrequency ~= startFrequency will do sweeps
      AVP.opt_param('increment', (startFrequency - stopFrequency)/100);
      AVP.opt_param('dwellTime', 100/min([startFrequency,stopFrequency]));
      AVP.opt_param('sweepType', 'UP');
      if ischar(sweepType), sweepType = obj.DriverData.enums.enPS2000SweepType.(['PS2000_' sweepType]); end
      AVP.opt_param('sweeps', 100);
      if ~calllib('ps2000', 'ps2000_set_sig_gen_built_in', obj.h, offsetVoltage, pkToPk, waveType, ...
          startFrequency, stopFrequency, increment, dwellTime, sweepType, sweeps)
        error('set_sig_gen_built_in failed!');
      end
    end % set_sig_gen_built_in

    function [bufferTimes, bufferCh, numDataValues, overflow, timeIndisposed_ms, samplingInterval_ns] = ...
        get_samples(obj, samplingInterval_ns, num_samples, varargin)
      %> @param numDataValues - the number of data values obtained.
      %> @param overflow - a bit pattern indicating whether an overflow has occurred and, if so, on which channel.

      if ~obj.Channel(1).Range && ~obj.Channel(2).Range
        error('get_samples - both channels are disabled!');
      end

      if AVP.opt_param_is_set('auto')
        had_overflow = [false,false];
        channel_done = [false,false];
        while ~channel_done(1) || ~channel_done(2)
          [bufferTimes, bufferCh, numDataValues, overflow, timeIndisposed_ms, samplingInterval_ns] = ...
            obj.get_samples(samplingInterval_ns, num_samples);
          for ChI = 1:2              
            if obj.Channel(ChI).Range % channel is enabled
              range = obj.Channel(ChI).Range; % 2-based index
              if bitand(overflow,bitshift(1,ChI-1)) % overflow
                had_overflow(ChI) = true;
                if range < obj.ValidRange(2)
                  range = range + 1;
                end
              else
                MaxV = max(abs(AVP.minmax(bufferCh{ChI})));
                % try to decrease range
                while ~had_overflow(ChI) && range > obj.ValidRange(1) && ...
                    MaxV < PicoConstants.SCOPE_INPUT_RANGES(range) % indices in PicoConstants.SCOPE_INPUT_RANGES are shifted by 1
                  range = range - 1;
                end
              end
              if range ~= obj.Channel(ChI).Range
                range
                obj.set_channel(ChI - 1, true, 'range', range);
              else
                channel_done(ChI) = true; 
              end
            else
              channel_done(ChI) = true;
            end
          end
        end
      else
        % lets figure out timebase and oversampling to use ADC in full
        % oversample influences both samplingInterval_ns and maxSamples, so
        % we have tune is to both
        % we will try to keep timebase as low as possible and increase
        % oversample to get MinSamplingInterval_ns
        oversample = PS2000Constants.PS2000_MAX_OVERSAMPLE;

        timebase = 0; old_timebase = -1;
        while old_timebase ~= timebase % tuning oversample to both samplingInterval_ns and num_samples
          % oversample may only get smaller every loop
          old_timebase = timebase;
          timebase = floor(log(samplingInterval_ns/oversample/obj.MinSamplingInterval_ns)/log(2));
          if timebase < 0
            oversample = floor(samplingInterval_ns/obj.MinSamplingInterval_ns);
            timebase = 0;
          elseif timebase > PS2000Constants.PS2200_MAX_TIMEBASE
            timebase = PS2000Constants.PS2200_MAX_TIMEBASE;
          end
          [samplingInterval_ns, timeUnits, maxSamples] = obj.get_timebase(timebase, oversample, num_samples); % check maxSamples
          if maxSamples < num_samples, oversample = floor(oversample*maxSamples/num_samples); old_timebase = -1; end
          if oversample < 1, oversample = 1; end
          % timebase, oversample
        end

        % Run block
        timeIndisposed_place = 0;
        [status, timeIndisposed_ms] = calllib('ps2000', 'ps2000_run_block', ...
          obj.h, num_samples, timebase, oversample, timeIndisposed_place);

        if ~status
          error('run_block failed!');
        end

        readyStatus = 0;
        while readyStatus == 0
          readyStatus = calllib('ps2000', 'ps2000_ready', obj.h);
        end

        if(readyStatus == -1)
          error('USB cable may have been unplugged.');
        else
          % Set up the buffers
          pBufferTimes = libpointer('int32Ptr', zeros(num_samples, 1));

          % Setup channels if enabled
          for ChI = 1:2
            if obj.Channel(ChI).Range
              pBufferCh{ChI} = libpointer('int16Ptr', zeros(num_samples, 1));
            else
              pBufferCh{ChI} = libpointer;
            end
          end

          overflowPtr = libpointer('int16Ptr', 0);

          % Get times and samples
          numDataValues = calllib('ps2000', 'ps2000_get_times_and_values', ...
            obj.h, pBufferTimes, pBufferCh{1}, pBufferCh{2}, ...
            [], [], overflowPtr, timeUnits, num_samples);

          % Indicate if parameters out of range or incorrect time units
          if(numDataValues == 0)
            error('ps2000_get_times_and_values: One or more parameters out of range or timeUnits incorrect');
          else
            % Output to buffers and convert channel data to milliVolts
            bufferTimes = double(pBufferTimes.Value);

            for ChI = 1:2
              if obj.Channel(ChI).Range
                bufferCh{ChI} = adc2mv(pBufferCh{ChI}.Value, PicoConstants.SCOPE_INPUT_RANGES(obj.Channel(ChI).Range+1), ...
                  PS2000Constants.PS2000_MAX_VALUE);
              else
                bufferCh{ChI} = [];
              end
            end

            overflow = overflowPtr.Value;
          end
        end
      end % if auto
    end % get_samples
  end % methods

  methods (Access = protected)
    function [samplingInterval_ns, timeUnits, maxSamples] = get_timebase(obj, timebase, oversample, num_samples)
      %> This function discovers which timebases are available on the oscilloscope. You should set up
      %> the channels using ps2000_set_channel and, if required, ETS mode using
      %> ps2000_set_ets first. Then call this function with increasing values of timebase, starting
      %> from 0, until you find a timebase with a sampling interval and sample count close enough to
      %> your requirements.
      %> @param timebase - a code between 0 and the maximum timebase PS2000Constants.PS2200_MAX_TIMEBASE
      %>          Timebase 0 is the fastest timebase. Each successive
      %>          timebase has twice the sampling interval of the previous one.
      %> @retval samplingInterval_ns
      %> @retval maxSamples
      samplingInterval_space = 0;
      maxSamples_space = 0;
      timeUnits_Space = 0;

      [status, samplingInterval_ns, timeUnits, maxSamples] = calllib('ps2000', ...
        'ps2000_get_timebase', obj.h, timebase + 1, ...
        1, samplingInterval_space, timeUnits_Space, ...
        oversample, maxSamples_space);

      if ~status, error('get_timebase failed!'); end

      if num_samples > maxSamples, num_samples = maxSamples; end

      [status, samplingInterval_ns, timeUnits, maxSamples] = calllib('ps2000', ...
        'ps2000_get_timebase', obj.h, timebase + 1, ...
        num_samples, samplingInterval_space, timeUnits_Space, ...
        oversample, maxSamples_space);

      if ~status, error('get_timebase failed!'); end
      samplingInterval_ns = double(samplingInterval_ns);
      maxSamples = double(maxSamples);

    end % get_timebase
  end % protected methods
end % pico
