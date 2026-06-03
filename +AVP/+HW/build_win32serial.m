function build_win32serial(varargin)
	%> Build the win32serial_mex MEX file.
	%> Usage: AVP.HW.build_win32serial            % release build
	%>        AVP.HW.build_win32serial('debug')   % with -g
	%>
	%> Builds in a temp dir then copies the result in. This sidesteps
	%> LNK1104 caused by Dropbox/AV grabbing the output file the moment
	%> link.exe creates it inside the Dropbox-synced project folder.
	here   = fileparts(mfilename('fullpath'));
	src    = fullfile(here, 'win32serial_mex.c');
	tmpdir = fullfile(tempdir, ['build_win32serial_' char(java.util.UUID.randomUUID)]);
	mkdir(tmpdir);
	cleanup = onCleanup(@() rmdir(tmpdir, 's'));

	% Unload if currently loaded (no-op if never built).
	clear AVP.HW.win32serial_mex

	% Remove any leftover .mexw64/.lib/.exp in the project dir; if these are
	% locked we want a clear error now, not a confusing one later.
	ext = mexext;
	for stale = {[ '.' ext], '.lib', '.exp', '.pdb'}
		f = fullfile(here, ['win32serial_mex' stale{1}]);
		if isfile(f), delete(f); end
	end

	args = {src, '-outdir', tmpdir, '-output', 'win32serial_mex', ...
		'-DWIN32_LEAN_AND_MEAN', '-ladvapi32'};
	if any(strcmpi(varargin, 'debug'))
		args = [{'-g'}, args];
	else
		args = [{'-O'}, args];
	end
	fprintf('Building %s (out: %s)\n', src, tmpdir);
	mex(args{:});

	built = fullfile(tmpdir, ['win32serial_mex.' ext]);
	if ~isfile(built)
		error('build_win32serial:notbuilt', ...
			'mex reported success but %s is missing', built);
	end
	dest = fullfile(here, ['win32serial_mex.' ext]);
	copyfile(built, dest, 'f');
	fprintf('Built %s\n', dest);
end % build_win32serial
