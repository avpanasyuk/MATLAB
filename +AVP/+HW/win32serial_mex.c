/* win32serial_mex.c - Win32 serial port MEX wrapper.
 * Single dispatcher: win32serial_mex(command, args...)
 * Build with build_win32serial.m
 */

#include "mex.h"
#include "matrix.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string.h>
#include <stdio.h>

#define MAX_PORTS 32

static HANDLE g_handles        [MAX_PORTS];
static DWORD  g_read_timeout_ms[MAX_PORTS];
static DWORD  g_write_timeout_ms[MAX_PORTS];
static DWORD  g_baud           [MAX_PORTS];
static char   g_port_name      [MAX_PORTS][32];
static int    g_initialized = 0;

static void cleanup_all(void) {
    int i;
    for (i = 0; i < MAX_PORTS; i++) {
        if (g_handles[i] && g_handles[i] != INVALID_HANDLE_VALUE) {
            CloseHandle(g_handles[i]);
            g_handles[i] = NULL;
        }
    }
}

static int alloc_slot(void) {
    int i;
    for (i = 0; i < MAX_PORTS; i++)
        if (g_handles[i] == NULL || g_handles[i] == INVALID_HANDLE_VALUE) return i;
    return -1;
}

static int get_slot(const mxArray *arg) {
    int idx;
    if (!mxIsNumeric(arg) || mxGetNumberOfElements(arg) != 1)
        mexErrMsgIdAndTxt("win32serial:badhandle", "Handle must be a scalar numeric.");
    idx = (int)mxGetScalar(arg) - 1;
    if (idx < 0 || idx >= MAX_PORTS)
        mexErrMsgIdAndTxt("win32serial:badhandle", "Handle out of range.");
    return idx;
}

static HANDLE get_handle(const mxArray *arg) {
    int slot = get_slot(arg);
    HANDLE h = g_handles[slot];
    if (!h || h == INVALID_HANDLE_VALUE)
        mexErrMsgIdAndTxt("win32serial:closed", "Port is not open.");
    return h;
}

static void format_win_error(DWORD err, char *out, size_t n) {
    char buf[512];
    size_t L;
    buf[0] = 0;
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                   NULL, err, 0, buf, sizeof(buf), NULL);
    L = strlen(buf);
    while (L > 0 && (buf[L-1] == '\n' || buf[L-1] == '\r' || buf[L-1] == ' ' || buf[L-1] == '.'))
        buf[--L] = 0;
    _snprintf(out, n, "Win32 error %lu: %s", (unsigned long)err, buf);
    out[n-1] = 0;
}

static void apply_timeouts(int slot, DWORD read_ms, DWORD write_ms) {
    COMMTIMEOUTS to;
    memset(&to, 0, sizeof(to));
    if (read_ms == 0) {
        to.ReadIntervalTimeout         = MAXDWORD;
        to.ReadTotalTimeoutMultiplier  = 0;
        to.ReadTotalTimeoutConstant    = 0;
    } else {
        to.ReadIntervalTimeout         = 0;
        to.ReadTotalTimeoutMultiplier  = 0;
        to.ReadTotalTimeoutConstant    = read_ms;
    }
    to.WriteTotalTimeoutMultiplier = 0;
    to.WriteTotalTimeoutConstant   = write_ms;
    SetCommTimeouts(g_handles[slot], &to);
    g_read_timeout_ms[slot]  = read_ms;
    g_write_timeout_ms[slot] = write_ms;
}

static void set_read_timeout(int slot, DWORD ms) {
    if (g_read_timeout_ms[slot] == ms) return;
    apply_timeouts(slot, ms, g_write_timeout_ms[slot]);
}

/* ---------- commands ---------- */

static void cmd_open(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char port_name[64], full[80], msg[600];
    DWORD baud, read_to, write_to;
    BYTE  databits, parity, stopbits;
    int   slot;
    HANDLE h;
    DCB   dcb;

    if (nrhs < 3)
        mexErrMsgIdAndTxt("win32serial:nargin",
            "open needs: port_name, baud [, databits, parity, stopbits, read_to_ms, write_to_ms]");
    if (!mxIsChar(prhs[1]))
        mexErrMsgIdAndTxt("win32serial:bad", "port_name must be a string");
    mxGetString(prhs[1], port_name, sizeof(port_name));
    baud     =        (DWORD)mxGetScalar(prhs[2]);
    databits = (nrhs > 3) ? (BYTE)mxGetScalar(prhs[3])  : 8;
    parity   = (nrhs > 4) ? (BYTE)mxGetScalar(prhs[4])  : NOPARITY;
    stopbits = (nrhs > 5) ? (BYTE)mxGetScalar(prhs[5])  : ONESTOPBIT;
    read_to  = (nrhs > 6) ? (DWORD)mxGetScalar(prhs[6]) : 10000;
    write_to = (nrhs > 7) ? (DWORD)mxGetScalar(prhs[7]) : 10000;

    slot = alloc_slot();
    if (slot < 0) mexErrMsgIdAndTxt("win32serial:noslot", "Too many open ports");

    _snprintf(full, sizeof(full), "\\\\.\\%s", port_name);
    h = CreateFileA(full, GENERIC_READ | GENERIC_WRITE, 0, NULL,
                    OPEN_EXISTING, 0, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        format_win_error(GetLastError(), msg, sizeof(msg));
        mexErrMsgIdAndTxt("win32serial:open", "Cannot open %s: %s", port_name, msg);
    }

    memset(&dcb, 0, sizeof(dcb));
    dcb.DCBlength = sizeof(dcb);
    if (!GetCommState(h, &dcb)) {
        format_win_error(GetLastError(), msg, sizeof(msg));
        CloseHandle(h);
        mexErrMsgIdAndTxt("win32serial:getstate", "GetCommState failed: %s", msg);
    }
    dcb.BaudRate         = baud;
    dcb.ByteSize         = databits;
    dcb.Parity           = parity;
    dcb.StopBits         = stopbits;
    dcb.fBinary          = TRUE;
    dcb.fParity          = (parity != NOPARITY);
    dcb.fOutxCtsFlow     = FALSE;
    dcb.fOutxDsrFlow     = FALSE;
    dcb.fDtrControl      = DTR_CONTROL_ENABLE;
    dcb.fDsrSensitivity  = FALSE;
    dcb.fTXContinueOnXoff= TRUE;
    dcb.fOutX            = FALSE;
    dcb.fInX             = FALSE;
    dcb.fErrorChar       = FALSE;
    dcb.fNull            = FALSE;
    dcb.fRtsControl      = RTS_CONTROL_ENABLE;
    dcb.fAbortOnError    = FALSE;
    if (!SetCommState(h, &dcb)) {
        format_win_error(GetLastError(), msg, sizeof(msg));
        CloseHandle(h);
        mexErrMsgIdAndTxt("win32serial:setstate", "SetCommState failed: %s", msg);
    }
    SetupComm(h, 65536, 65536);
    PurgeComm(h, PURGE_RXCLEAR | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_TXABORT);

    g_handles[slot] = h;
    g_baud[slot]    = baud;
    strncpy(g_port_name[slot], port_name, sizeof(g_port_name[slot]) - 1);
    g_port_name[slot][sizeof(g_port_name[slot]) - 1] = 0;
    g_read_timeout_ms[slot]  = ~0u;
    g_write_timeout_ms[slot] = ~0u;
    apply_timeouts(slot, read_to, write_to);

    plhs[0] = mxCreateDoubleScalar((double)(slot + 1));
}

static void cmd_close(int nrhs, const mxArray *prhs[]) {
    int slot = get_slot(prhs[1]);
    if (g_handles[slot] && g_handles[slot] != INVALID_HANDLE_VALUE) {
        PurgeComm(g_handles[slot], PURGE_RXCLEAR | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_TXABORT);
        CloseHandle(g_handles[slot]);
    }
    g_handles[slot] = NULL;
    g_port_name[slot][0] = 0;
}

static void cmd_read(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int    slot = get_slot(prhs[1]);
    HANDLE h    = get_handle(prhs[1]);
    DWORD  nbytes, timeout_ms, total = 0;
    BYTE  *buf;

    if (nrhs < 3) mexErrMsgIdAndTxt("win32serial:nargin", "read: handle, nbytes [, timeout_ms]");
    nbytes     = (DWORD)mxGetScalar(prhs[2]);
    timeout_ms = (nrhs > 3) ? (DWORD)mxGetScalar(prhs[3]) : g_read_timeout_ms[slot];
    set_read_timeout(slot, timeout_ms);

    plhs[0] = mxCreateNumericMatrix(nbytes, 1, mxUINT8_CLASS, mxREAL);
    if (nbytes == 0) return;
    buf = (BYTE *)mxGetData(plhs[0]);
    while (total < nbytes) {
        DWORD got = 0;
        if (!ReadFile(h, buf + total, nbytes - total, &got, NULL)) {
            char msg[600];
            format_win_error(GetLastError(), msg, sizeof(msg));
            mexErrMsgIdAndTxt("win32serial:read", "ReadFile failed: %s", msg);
        }
        if (got == 0)
            mexErrMsgIdAndTxt("win32serial:read_timeout",
                "Read timed out: %lu of %lu bytes in %lu ms",
                (unsigned long)total, (unsigned long)nbytes, (unsigned long)timeout_ms);
        total += got;
    }
}

static void cmd_try_read(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int    slot   = get_slot(prhs[1]);
    HANDLE h      = get_handle(prhs[1]);
    DWORD  nbytes, got = 0;
    BYTE  *tmp;

    if (nrhs < 3) mexErrMsgIdAndTxt("win32serial:nargin", "try_read: handle, nbytes");
    nbytes = (DWORD)mxGetScalar(prhs[2]);
    set_read_timeout(slot, 0);

    tmp = (BYTE *)mxMalloc(nbytes ? nbytes : 1);
    if (nbytes && !ReadFile(h, tmp, nbytes, &got, NULL)) {
        char msg[600];
        format_win_error(GetLastError(), msg, sizeof(msg));
        mxFree(tmp);
        mexErrMsgIdAndTxt("win32serial:read", "ReadFile failed: %s", msg);
    }
    plhs[0] = mxCreateNumericMatrix(got, 1, mxUINT8_CLASS, mxREAL);
    if (got) memcpy(mxGetData(plhs[0]), tmp, got);
    mxFree(tmp);
}

static void cmd_write(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    HANDLE       h    = get_handle(prhs[1]);
    const BYTE  *data;
    DWORD        n, total = 0;

    if (nrhs < 3) mexErrMsgIdAndTxt("win32serial:nargin", "write: handle, uint8_data");
    if (!mxIsUint8(prhs[2]))
        mexErrMsgIdAndTxt("win32serial:write", "data must be uint8");
    data = (const BYTE *)mxGetData(prhs[2]);
    n    = (DWORD)mxGetNumberOfElements(prhs[2]);
    while (total < n) {
        DWORD wrote = 0;
        if (!WriteFile(h, data + total, n - total, &wrote, NULL)) {
            char msg[600];
            format_win_error(GetLastError(), msg, sizeof(msg));
            mexErrMsgIdAndTxt("win32serial:write", "WriteFile failed: %s", msg);
        }
        if (wrote == 0)
            mexErrMsgIdAndTxt("win32serial:write_timeout", "Write timed out");
        total += wrote;
    }
    if (nlhs > 0) plhs[0] = mxCreateDoubleScalar((double)total);
}

static void cmd_available(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    HANDLE h = get_handle(prhs[1]);
    DWORD  errs;
    COMSTAT stat;
    if (!ClearCommError(h, &errs, &stat)) {
        char msg[600];
        format_win_error(GetLastError(), msg, sizeof(msg));
        mexErrMsgIdAndTxt("win32serial:available", "ClearCommError failed: %s", msg);
    }
    plhs[0] = mxCreateDoubleScalar((double)stat.cbInQue);
}

static void cmd_flush(int nrhs, const mxArray *prhs[]) {
    HANDLE h = get_handle(prhs[1]);
    DWORD  flags = PURGE_RXCLEAR | PURGE_TXCLEAR;
    if (nrhs > 2 && mxIsChar(prhs[2])) {
        char what[16] = {0};
        mxGetString(prhs[2], what, sizeof(what));
        if      (!_stricmp(what, "input"))  flags = PURGE_RXCLEAR;
        else if (!_stricmp(what, "output")) flags = PURGE_TXCLEAR;
    }
    PurgeComm(h, flags);
}

static void cmd_set_baud(int nrhs, const mxArray *prhs[]) {
    int    slot = get_slot(prhs[1]);
    HANDLE h    = get_handle(prhs[1]);
    DCB    dcb;
    memset(&dcb, 0, sizeof(dcb));
    dcb.DCBlength = sizeof(dcb);
    if (!GetCommState(h, &dcb))
        mexErrMsgIdAndTxt("win32serial:getstate", "GetCommState failed");
    dcb.BaudRate = (DWORD)mxGetScalar(prhs[2]);
    if (!SetCommState(h, &dcb))
        mexErrMsgIdAndTxt("win32serial:setstate", "SetCommState failed");
    g_baud[slot] = dcb.BaudRate;
}

static void cmd_set_timeout(int nrhs, const mxArray *prhs[]) {
    int   slot = get_slot(prhs[1]);
    DWORD r    = (DWORD)mxGetScalar(prhs[2]);
    DWORD w    = (nrhs > 3) ? (DWORD)mxGetScalar(prhs[3]) : g_write_timeout_ms[slot];
    apply_timeouts(slot, r, w);
}

static void cmd_isopen(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int    slot = get_slot(prhs[1]);
    int    ok   = 0;
    HANDLE h    = g_handles[slot];
    if (h && h != INVALID_HANDLE_VALUE) {
        DCB dcb;
        memset(&dcb, 0, sizeof(dcb));
        dcb.DCBlength = sizeof(dcb);
        ok = GetCommState(h, &dcb) ? 1 : 0;
        if (!ok) {
            CloseHandle(h);
            g_handles[slot] = NULL;
        }
    }
    plhs[0] = mxCreateLogicalScalar(ok);
}

static void cmd_info(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int slot = get_slot(prhs[1]);
    const char *fields[] = {"Port", "BaudRate", "Timeout_ms", "WriteTimeout_ms"};
    plhs[0] = mxCreateStructMatrix(1, 1, 4, fields);
    mxSetField(plhs[0], 0, "Port",            mxCreateString(g_port_name[slot]));
    mxSetField(plhs[0], 0, "BaudRate",        mxCreateDoubleScalar((double)g_baud[slot]));
    mxSetField(plhs[0], 0, "Timeout_ms",      mxCreateDoubleScalar((double)g_read_timeout_ms[slot]));
    mxSetField(plhs[0], 0, "WriteTimeout_ms", mxCreateDoubleScalar((double)g_write_timeout_ms[slot]));
}

static void cmd_list(int nlhs, mxArray *plhs[]) {
    HKEY  hkey;
    LONG  rc;
    DWORD i, count = 0;
    char  name[256], data[256];
    DWORD name_len, data_len, type;

    rc = RegOpenKeyExA(HKEY_LOCAL_MACHINE,
        "HARDWARE\\DEVICEMAP\\SERIALCOMM", 0, KEY_READ, &hkey);
    if (rc != ERROR_SUCCESS) {
        plhs[0] = mxCreateCellMatrix(0, 1);
        return;
    }
    while (1) {
        name_len = sizeof(name);
        data_len = sizeof(data);
        rc = RegEnumValueA(hkey, count, name, &name_len, NULL, &type,
                           (LPBYTE)data, &data_len);
        if (rc != ERROR_SUCCESS) break;
        count++;
    }
    plhs[0] = mxCreateCellMatrix(count, 1);
    for (i = 0; i < count; i++) {
        name_len = sizeof(name);
        data_len = sizeof(data);
        rc = RegEnumValueA(hkey, i, name, &name_len, NULL, &type,
                           (LPBYTE)data, &data_len);
        if (rc == ERROR_SUCCESS && type == REG_SZ)
            mxSetCell(plhs[0], i, mxCreateString(data));
        else
            mxSetCell(plhs[0], i, mxCreateString(""));
    }
    RegCloseKey(hkey);
}

/* ---------- entry ---------- */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    char cmd[32];

    if (!g_initialized) {
        memset(g_handles, 0, sizeof(g_handles));
        mexAtExit(cleanup_all);
        g_initialized = 1;
    }
    if (nrhs < 1 || !mxIsChar(prhs[0]))
        mexErrMsgIdAndTxt("win32serial:cmd", "first argument must be a command string");
    mxGetString(prhs[0], cmd, sizeof(cmd));

    if      (!_stricmp(cmd, "open"))        cmd_open       (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "close"))       cmd_close      (nrhs, prhs);
    else if (!_stricmp(cmd, "read"))        cmd_read       (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "try_read"))    cmd_try_read   (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "write"))       cmd_write      (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "available"))   cmd_available  (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "flush"))       cmd_flush      (nrhs, prhs);
    else if (!_stricmp(cmd, "set_baud"))    cmd_set_baud   (nrhs, prhs);
    else if (!_stricmp(cmd, "set_timeout")) cmd_set_timeout(nrhs, prhs);
    else if (!_stricmp(cmd, "isopen"))      cmd_isopen     (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "info"))        cmd_info       (nlhs, plhs, nrhs, prhs);
    else if (!_stricmp(cmd, "list"))        cmd_list       (nlhs, plhs);
    else mexErrMsgIdAndTxt("win32serial:cmd", "unknown command: %s", cmd);
}
