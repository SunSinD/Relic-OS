"""Tiny VNC (RFB 3.8) client for driving the RelicOS VMware guest.

VMware Workstation exposes the guest screen over VNC when the VMX has
RemoteDisplay.vnc.enabled = "TRUE" (tools/relic.ps1 adds it).  TempleOS has
no VMware Tools, so this is the only way to script keystrokes and grab
screenshots from the host.

  python tools/vnc.py shot out.png
  python tools/vnc.py type "DrvRep;" --enter
  python tools/vnc.py key Escape
  python tools/vnc.py click 320 400
"""
import argparse
import socket
import struct
import sys
import time

KEYSYMS = {
    "Return": 0xFF0D, "Enter": 0xFF0D, "Escape": 0xFF1B, "Esc": 0xFF1B,
    "BackSpace": 0xFF08, "Tab": 0xFF09, "Up": 0xFF52, "Down": 0xFF54,
    "Left": 0xFF51, "Right": 0xFF53, "Home": 0xFF50, "End": 0xFF57,
    "PageUp": 0xFF55, "PageDown": 0xFF56, "Delete": 0xFFFF, "Space": 0x20,
    "Shift": 0xFFE1, "Ctrl": 0xFFE3, "Alt": 0xFFE9,
    "F1": 0xFFBE, "F2": 0xFFBF, "F3": 0xFFC0, "F4": 0xFFC1, "F5": 0xFFC2,
    "F6": 0xFFC3, "F7": 0xFFC4, "F8": 0xFFC5, "F9": 0xFFC6, "F10": 0xFFC7,
    "F11": 0xFFC8, "F12": 0xFFC9,
}
SHIFTED = set('~!@#$%^&*()_+{}|:"<>?ABCDEFGHIJKLMNOPQRSTUVWXYZ')


class Vnc:
    def __init__(self, host="127.0.0.1", port=5901):
        self.s = socket.create_connection((host, port), timeout=10)
        ver = self._recv(12)
        if not ver.startswith(b"RFB "):
            raise RuntimeError("not a VNC server: %r" % ver)
        self.s.sendall(b"RFB 003.008\n")
        n = self._recv(1)[0]
        if n == 0:
            raise RuntimeError("VNC refused: " + self._reason())
        types = self._recv(n)
        if 1 not in types:
            raise RuntimeError("VNC needs a password (types %s); remove RemoteDisplay.vnc.password" % list(types))
        self.s.sendall(b"\x01")
        if struct.unpack(">I", self._recv(4))[0] != 0:
            raise RuntimeError("VNC auth failed: " + self._reason())
        self.s.sendall(b"\x01")
        self.w, self.h = struct.unpack(">HH", self._recv(4))
        self._recv(16)
        self._recv(struct.unpack(">I", self._recv(4))[0])
        pf = struct.pack(">BBBBHHHBBB3x", 32, 24, 0, 1, 255, 255, 255, 16, 8, 0)
        self.s.sendall(b"\x00\x00\x00\x00" + pf)
        self.s.sendall(struct.pack(">BxHi", 2, 1, 0))

    def _recv(self, n):
        buf = bytearray()
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise RuntimeError("VNC connection closed")
            buf += chunk
        return bytes(buf)

    def _reason(self):
        return self._recv(struct.unpack(">I", self._recv(4))[0]).decode(errors="replace")

    def screenshot(self, path):
        from PIL import Image
        fb = bytearray(self.w * self.h * 4)
        self.s.sendall(struct.pack(">BBHHHH", 3, 0, 0, 0, self.w, self.h))
        got = False
        while not got:
            t = self._recv(1)[0]
            if t == 0:
                self._recv(1)
                for _ in range(struct.unpack(">H", self._recv(2))[0]):
                    x, y, w, h, enc = struct.unpack(">HHHHi", self._recv(12))
                    if enc == 0:
                        data = self._recv(w * h * 4)
                        for row in range(h):
                            o = ((y + row) * self.w + x) * 4
                            fb[o:o + w * 4] = data[row * w * 4:(row + 1) * w * 4]
                    elif enc == -223:
                        self.w, self.h = w, h
                        fb = bytearray(w * h * 4)
                        self.s.sendall(struct.pack(">BBHHHH", 3, 0, 0, 0, w, h))
                        continue
                    else:
                        raise RuntimeError("unexpected encoding %d" % enc)
                got = True
            elif t == 1:
                self._recv(3)
                self._recv(6 * struct.unpack(">H", self._recv(2))[0])
            elif t == 2:
                pass
            elif t == 3:
                self._recv(3)
                self._recv(struct.unpack(">I", self._recv(4))[0])
            else:
                raise RuntimeError("unknown server message %d" % t)
        img = Image.frombuffer("RGBX", (self.w, self.h), bytes(fb), "raw", "BGRX", 0, 1).convert("RGB")
        img.save(path)

    def key(self, sym, down=None):
        if down is None:
            self.key(sym, True)
            self.key(sym, False)
            return
        self.s.sendall(struct.pack(">BBxxI", 4, 1 if down else 0, sym))
        time.sleep(0.02)

    def press(self, name):
        parts = name.split("+")
        syms = [KEYSYMS.get(p, ord(p) if len(p) == 1 else None) for p in parts]
        if None in syms:
            raise SystemExit("unknown key: " + name)
        for s in syms:
            self.key(s, True)
        for s in reversed(syms):
            self.key(s, False)

    def type(self, text):
        for ch in text:
            if ch == "\n":
                self.key(KEYSYMS["Return"])
            elif ch in SHIFTED:
                self.key(KEYSYMS["Shift"], True)
                self.key(ord(ch))
                self.key(KEYSYMS["Shift"], False)
            else:
                self.key(ord(ch))

    def click(self, x, y, button=1):
        self.s.sendall(struct.pack(">BBHH", 5, 0, x, y))
        time.sleep(0.05)
        self.s.sendall(struct.pack(">BBHH", 5, button, x, y))
        time.sleep(0.08)
        self.s.sendall(struct.pack(">BBHH", 5, 0, x, y))

    def move(self, x, y):
        self.s.sendall(struct.pack(">BBHH", 5, 0, x, y))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=5901)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("shot"); p.add_argument("path")
    p = sub.add_parser("type"); p.add_argument("text"); p.add_argument("--enter", action="store_true")
    p = sub.add_parser("key"); p.add_argument("names", nargs="+")
    p = sub.add_parser("click"); p.add_argument("x", type=int); p.add_argument("y", type=int)
    p = sub.add_parser("move"); p.add_argument("x", type=int); p.add_argument("y", type=int)
    a = ap.parse_args()
    v = Vnc(port=a.port)
    if a.cmd == "shot":
        v.screenshot(a.path)
        print("%s (%dx%d)" % (a.path, v.w, v.h))
    elif a.cmd == "type":
        v.type(a.text)
        if a.enter:
            v.key(KEYSYMS["Return"])
    elif a.cmd == "key":
        for n in a.names:
            v.press(n)
    elif a.cmd == "click":
        v.click(a.x, a.y)
    elif a.cmd == "move":
        v.move(a.x, a.y)
    time.sleep(0.1)


if __name__ == "__main__":
    sys.exit(main())
