function ok = selftest()
  %> Offline test of AVP.HW.RedPitaya's acquisition path - no board. Starts fake_scpi_server.py
  %> (beside this file; Windows, python on PATH) on 127.0.0.1:5000 and checks: BIN block framing
  %> over consecutive reads, the Calib arithmetic, the LV raw path, the acquisition state declared
  %> before each read (also after GenerateWave's ACQ:RST), text replies staying aligned, recovery
  %> from a bad block header, a bad block trailer and a missing FILL? reply, and StartAcq's input
  %> validation.
  %> @retval ok - true when every check passes
  if ~ispc, error('AVP.HW.RP.selftest launches its fake board with Windows start'); end
  [st, out] = system('python -c "import sys; print(sys.version_info[0])"');
  if st ~= 0 || ~startsWith(strtrim(out),'3')
    error('AVP.HW.RP.selftest needs Python 3 as "python" on PATH; got status %d: %s', st, strtrim(out));
  end
  nonce = sprintf('%d', randi(1e9));
  srv = fullfile(fileparts(mfilename('fullpath')),'fake_scpi_server.py');
  system(sprintf('start "" /B python -I "%s" 30 %s', srv, nonce));
  w = warning('off','RedPitaya:nocalib'); w(2) = warning('off','RedPitaya:lv');
  restoreWarnings = onCleanup(@() warning(w));
  a = []; why = '';
  for Try = 1:40 % the server needs a moment to listen
    try
      a = AVP.HW.RedPitaya('127.0.0.1'); break;
    catch e
      why = e.message; pause(0.25);
    end
  end
  if isempty(a), error('fake_scpi_server.py never accepted a connection: %s', why); end
  closeSocket = onCleanup(@() delete(a)); % on every exit path; the server exits when it closes
  a.tcpc.Timeout = 2;
  try
    idn = a.writeread('*IDN?');
  catch
    idn = '';
  end
  if ~strcmp(idn, ['FAKE-RP ' nonce])
    error('port 5000 is answered by something other than the fake board this run launched');
  end

  k = 0:16383; RAWv = [0.977 0.027];
  raw = @(ch) double(single(RAWv(ch) + 1e-4*mod(k,100)));
  nfail = 0;

  a.Host = 'rp-f04769'; % borrow that board's Calib for the arithmetic
  c = a.Calib(a.Host);
  want = [(raw(1) - c(1,2))/c(1,1); (raw(2) - c(2,2))/c(2,1)];
  hvState = 'DEC=8 UNITS=VOLTS FORMAT=BIN AVG=ON GAIN1=HV GAIN2=HV START TRIG';
  a.StartAcq('SampleRateDividerLog2',3,'Channel',[1 2]);
  for rep = 1:3
    x = a.GetAcqBuffer();
    nfail = nfail + check(sprintf('HV read %d: corrected, aligned',rep), ...
      isequal(size(x),[2 16384]) && max(abs(x(:) - want(:))) < 1e-6);
  end
  nfail = nfail + check('acquisition state declared before the read', strcmp(a.writeread('TEST:STATE?'), hvState));
  a.GenerateWave(1000, 0.1); % sends ACQ:RST: DEC 1, GAIN LV on the board
  x = a.GetAcqBuffer();
  nfail = nfail + check('read after ACQ:RST: corrected, aligned', ...
    isequal(size(x),[2 16384]) && max(abs(x(:) - want(:))) < 1e-6);
  nfail = nfail + check('state re-declared after ACQ:RST', strcmp(a.writeread('TEST:STATE?'), hvState));
  a.StartAcq('SampleRateDividerLog2',3,'Channel',2,'Range',1);
  x = a.GetAcqBuffer();
  nfail = nfail + check('LV ch2 alone stays RAW', isequal(size(x),[1 16384]) && max(abs(x - raw(2))) < 1e-6);
  nfail = nfail + check('LV declared as LV', contains(a.writeread('TEST:STATE?'), 'GAIN2=LV'));

  a.StartAcq('SampleRateDividerLog2',3,'Channel',[1 2],'Range',1);
  writeline(a.tcpc,'TEST:BADHEADER');
  nfail = nfail + check('bad block header raises', raises(@() a.GetAcqBuffer(), 'block header'));
  nfail = nfail + check('next read after a bad header is clean', clean(a, [raw(1); raw(2)]));
  writeline(a.tcpc,'TEST:BADBLOCK');
  nfail = nfail + check('corrupt block trailer raises', raises(@() a.GetAcqBuffer(), 'CR LF'));
  nfail = nfail + check('next read after a corrupt block is clean', clean(a, [raw(1); raw(2)]));
  writeline(a.tcpc,'TEST:NOFILL');
  nfail = nfail + check('missing FILL? reply raises', raises(@() a.GetAcqBuffer(), 'no reply'));
  nfail = nfail + check('next read after a missing reply is clean', clean(a, [raw(1); raw(2)]));

  bad = {{'SampleRateDividerLog2',8.5}, {'SampleRateDividerLog2',17}, {'Channel',[1 1]}, ...
         {'Channel',3}, {'Range',NaN}, {'Range',[0 20]}};
  for b = bad
    nfail = nfail + check(sprintf('StartAcq rejects %s=%s', b{1}{1}, mat2str(b{1}{2})), ...
      raises(@() a.StartAcq(b{1}{:}), b{1}{1}));
  end
  nfail = nfail + check('a rejected StartAcq keeps the prior settings', ...
    a.SampleRateDividerLog2 == 3 && isequal(a.Channel,[1 2]) && isequal(a.Range,[1 1]));

  delete(a);
  nfail = nfail + check('fake board exited when the socket closed', serverGone());
  ok = nfail == 0;
  if ok, fprintf('ALL PASS\n'); else, fprintf('%d FAILED\n', nfail); end
end

function bad = check(name, ok)
  if ok, fprintf('PASS  %s\n', name); else, fprintf('FAIL  %s\n', name); end
  bad = ~ok;
end

function ok = raises(fn, fragment)
  try
    fn(); ok = false;
  catch e
    ok = contains(e.message, fragment);
  end
end

function ok = clean(a, want)
  try
    x = a.GetAcqBuffer(); ok = isequal(size(x), size(want)) && max(abs(x(:) - want(:))) < 1e-6;
  catch
    ok = false;
  end
end

function gone = serverGone()
  for Try = 1:20
    try
      delete(tcpclient('127.0.0.1', 5000, 'ConnectTimeout', 1)); %#ok<TNMLP> the poll IS the loop
      pause(0.25);
    catch
      gone = true; return
    end
  end
  gone = false;
end
