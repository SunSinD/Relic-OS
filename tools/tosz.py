"""Expand a TempleOS .Z file (LZW, port of Downloads/Linux/TOSZ.CPP).

Usage: python tools/tosz.py IN.HC.Z [OUT]   (prints to stdout without OUT)
"""
import struct
import sys

MAX_BITS = 12


def expand(data):
    csize, esize, ctype = struct.unpack_from("<QQB", data, 0)
    if ctype == 1:
        return data[17:17 + esize]
    if ctype not in (2, 3):
        raise ValueError("not a TempleOS .Z file")
    min_bits = 7 if ctype == 2 else 8
    min_entry = 1 << min_bits
    n = 1 << MAX_BITS
    base = [0] * n
    chs = [0] * n
    nxt = [None] * n
    hsh = [None] * n
    st = {"free": min_entry, "nbits": min_bits + 1, "limit": 1 << (min_bits + 1),
          "used": True, "cur": None, "next": None, "cbits": 0}

    def entry_get():
        if not st["used"]:
            return
        i = st["free"]
        st["used"] = False
        st["cur"] = st["next"]
        st["cbits"] = st["nbits"]
        if st["nbits"] < MAX_BITS:
            st["next"] = i
            i += 1
            if i == st["limit"]:
                st["nbits"] += 1
                st["limit"] = 1 << st["nbits"]
        else:
            while True:
                i += 1
                if i == st["limit"]:
                    i = min_entry
                if hsh[i] is None:
                    break
            st["next"] = i
            b = base[i]
            if hsh[b] == i:
                hsh[b] = nxt[i]
            else:
                p = hsh[b]
                while p is not None and nxt[p] != i:
                    p = nxt[p]
                if p is not None:
                    nxt[p] = nxt[i]
        st["free"] = i

    entry_get()
    st["used"] = True

    bits = int.from_bytes(data, "little")
    src_size = csize * 8
    pos = 17 * 8
    out = bytearray()

    def take(k):
        nonlocal pos
        v = (bits >> pos) & ((1 << k) - 1)
        pos += k
        return v

    last = take(st["nbits"])
    out.append(last)
    entry_get()
    last_ch = last
    while len(out) < esize and pos + st["nbits"] <= src_size:
        code_in = take(st["nbits"])
        stk = []
        if st["cur"] == code_in:
            stk.append(last_ch)
            code = last
        else:
            code = code_in
        while code >= min_entry:
            stk.append(chs[code])
            code = base[code]
        stk.append(code)
        last_ch = code
        st["used"] = True
        t = st["cur"]
        base[t] = last
        chs[t] = last_ch
        nxt[t] = hsh[last]
        hsh[last] = t
        entry_get()
        out.extend(reversed(stk))
        last = code_in
    return bytes(out[:esize])


if __name__ == "__main__":
    raw = expand(open(sys.argv[1], "rb").read())
    raw = raw.replace(b"\x1f", b" ").replace(b"\x05", b"")
    if len(sys.argv) > 2:
        open(sys.argv[2], "wb").write(raw)
    else:
        sys.stdout.buffer.write(raw)
