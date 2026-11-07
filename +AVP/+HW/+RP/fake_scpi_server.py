"""Fake Red Pitaya SCPI server on 127.0.0.1:5000 for AVP.HW.RP.selftest - no board needed.

Usage: fake_scpi_server.py <timeout_s> <nonce>. Serves one connection and exits when it closes,
or after timeout_s of silence. *IDN? answers "FAKE-RP <nonce>", so the test can prove it reached
the server it launched; the port is bound exclusively, so a stale listener makes this one fail.

ACQ:SOURn:DATA? replies are real-format BIN blocks: '#5' + 5-digit count + big-endian float32 +
CR LF, sample k of channel n = RAW[n] + 1e-4*(k % 100), so a shift by any byte count shows.
Setup commands are tracked like the board does (ACQ:RST -> DEC 1, GAIN LV), and TEST:STATE?
returns the state that was declared when the last DATA? arrived. FILL? answers 0 once after each
ACQ:START, then 1, so the driver's poll loop runs.
Fault injection, armed by commands that get no reply:
  TEST:BADBLOCK - the next block ends in XX1junk CR LF instead of CR LF, and the FILL? after it is
                  answered 50 ms late: a leftover starting with '1' plus a late reply is what an
                  input flush placed after the FILL? loop cannot absorb
  TEST:NOFILL   - the next FILL? gets no reply
  TEST:BADHEADER - the next block starts with X instead of #
"""
import socket, struct, sys, time

RAW = {1: 0.977, 2: 0.027}
N = 16384


def reset():
    return {"DEC": "1", "UNITS": "?", "FORMAT": "?", "AVG": "?", "GAIN1": "LV", "GAIN2": "LV",
            "START": False, "TRIG": False}


def snapshot(st):
    keys = ("DEC", "UNITS", "FORMAT", "AVG", "GAIN1", "GAIN2")
    s = " ".join(f"{k}={st[k]}" for k in keys)
    return s + (" START" if st["START"] else "") + (" TRIG" if st["TRIG"] else "")


s = socket.socket()
if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
    s.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
else:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("127.0.0.1", 5000)); s.listen(1)
except OSError as e:
    sys.exit(f"fake_scpi_server: port 5000 is in use ({e})")
s.settimeout(float(sys.argv[1]))
st, last, buf = reset(), "none", b""
bad_block = bad_header = no_fill = late_fill = False
fills_since_start = 0
try:
    c, _ = s.accept(); c.settimeout(float(sys.argv[1]))
    while True:
        d = c.recv(65536)
        if not d:
            break
        buf += d
        while b"\r\n" in buf:
            line, buf = buf.split(b"\r\n", 1)
            cmd = line.decode()
            arg = cmd.split(" ", 1)[1] if " " in cmd else ""
            if cmd == "*IDN?":
                c.sendall(f"FAKE-RP {sys.argv[2]}\r\n".encode())
            elif cmd == "TEST:BADBLOCK":
                bad_block = True
            elif cmd == "TEST:NOFILL":
                no_fill = True
            elif cmd == "TEST:BADHEADER":
                bad_header = True
            elif cmd == "TEST:STATE?":
                c.sendall(last.encode() + b"\r\n")
            elif cmd == "ACQ:RST":
                st = reset()
            elif cmd.startswith("ACQ:DEC "):
                st["DEC"] = arg
            elif cmd.startswith("ACQ:DATA:UNITS "):
                st["UNITS"] = arg
            elif cmd.startswith("ACQ:DATA:FORMAT "):
                st["FORMAT"] = arg
            elif cmd.startswith("ACQ:AVG "):
                st["AVG"] = arg
            elif cmd.startswith("ACQ:SOUR") and ":GAIN " in cmd:
                st["GAIN" + cmd[8]] = arg
            elif cmd == "ACQ:START":
                st["START"], st["TRIG"], fills_since_start = True, False, 0
            elif cmd == "ACQ:TRIG NOW":
                st["TRIG"] = True
            elif cmd == "ACQ:TRIG:FILL?":
                if no_fill:
                    no_fill = False
                    continue
                if late_fill:
                    late_fill = False
                    time.sleep(0.05)
                fills_since_start += 1
                c.sendall(b"0\r\n" if fills_since_start == 1 else b"1\r\n")
            elif cmd.startswith("ACQ:SOUR") and cmd.endswith(":DATA?"):
                last = snapshot(st)
                ch = int(cmd[8])
                payload = struct.pack(f">{N}f", *[RAW[ch] + 1e-4 * (k % 100) for k in range(N)])
                tail = b"XX1junk\r\n" if bad_block else b"\r\n"
                head = b"X5" if bad_header else b"#5"
                late_fill, bad_block, bad_header = late_fill or bad_block, False, False
                c.sendall(head + f"{len(payload):05d}".encode() + payload + tail)
except (socket.timeout, ConnectionError):
    pass
