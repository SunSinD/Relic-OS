#!/usr/bin/env python3
"""Create and read FAT32 disk images for the RelicOS transfer disk.

TempleOS reads FAT32 with VFAT long names.  This writes a partitioned
(MBR type 0x0C) FAT32 image that VMware can attach as a monolithicFlat
extent (transfer-flat.vmdk) without Windows ever mounting the volume.
"""

from __future__ import annotations

import argparse
import os
import struct
import sys
import time
from pathlib import Path

SECTOR = 512
PART_LBA = 2048
RESERVED = 32
NUM_FATS = 2
ROOT_CLUSTER = 2


def _now_fat():
    t = time.localtime()
    fat_date = ((t.tm_year - 1980) << 9) | (t.tm_mon << 5) | t.tm_mday
    fat_time = (t.tm_hour << 11) | (t.tm_min << 5) | (t.tm_sec // 2)
    return fat_date, fat_time


def _short_base(name: str, used: set[str]) -> bytes:
    stem, _, ext = name.upper().replace(" ", "").rpartition(".")
    if not _:
        stem, ext = name.upper().replace(" ", ""), ""
    def clean(s, n):
        out = []
        for ch in s:
            if ch.isalnum() or ch in "$_~-":
                out.append(ch)
            else:
                out.append("_")
            if len(out) >= n:
                break
        return "".join(out)
    base = clean(stem, 8) or "FILE"
    ext8 = clean(ext, 3)
    for i in range(1, 1000):
        if i == 1 and len(base) <= 8 and f"{base}.{ext8}" not in used and "." not in name[1:]:
            # Prefer a real 8.3 when the name already fits.
            raw = name.upper()
            if raw == f"{base}.{ext8}" or (not ext8 and raw == base):
                key = f"{base}.{ext8}"
                used.add(key)
                return (base.ljust(8) + ext8.ljust(3)).encode("ascii")
        suffix = f"~{i}"
        head = clean(stem, 8 - len(suffix))
        key = f"{head}{suffix}.{ext8}"
        if key not in used:
            used.add(key)
            return ((head + suffix).ljust(8) + ext8.ljust(3)).encode("ascii")
    raise RuntimeError(f"cannot allocate 8.3 name for {name}")


def _lfn_checksum(short11: bytes) -> int:
    s = 0
    for b in short11:
        s = ((s & 1) << 7) + (s >> 1) + b
        s &= 0xFF
    return s


def _lfn_entries(long_name: str, short11: bytes) -> list[bytes]:
    chars = list(long_name.encode("utf-16-le"))
    # utf-16-le bytes -> uint16 code units
    units = list(struct.unpack("<" + "H" * (len(chars) // 2), bytes(chars)))
    units.append(0)
    chk = _lfn_checksum(short11)
    slots = []
    idx = 0
    seq = 1
    while idx < len(units):
        chunk = units[idx:idx + 13]
        idx += 13
        while len(chunk) < 13:
            chunk.append(0xFFFF)
        name1 = struct.pack("<5H", *chunk[0:5])
        name2 = struct.pack("<6H", *chunk[5:11])
        name3 = struct.pack("<2H", *chunk[11:13])
        slots.append([seq, name1, name2, name3, chk])
        seq += 1
    slots[-1][0] |= 0x40
    out = []
    for seq, n1, n2, n3, chk in reversed(slots):
        out.append(struct.pack("<B10sBBB12sH4s", seq, n1, 0x0F, 0, chk, n2, 0, n3))
    return out


class Fat32Image:
    def __init__(self, path: Path, size_mb: int = 512, label: str = "RELIC"):
        self.path = Path(path)
        self.size_mb = size_mb
        self.label = (label.upper() + "           ")[:11]
        self.total_sectors = (size_mb * 1024 * 1024) // SECTOR
        self.part_sectors = self.total_sectors - PART_LBA
        self.fat_lba = PART_LBA + RESERVED
        # FAT32 needs >= 65525 clusters: prefer 4 KiB clusters, fall back to
        # 512-byte clusters when the volume is too small for that.
        for self.spc in (8, 1):
            tmp1 = self.part_sectors - RESERVED
            tmp2 = (256 * self.spc + NUM_FATS) // 2
            self.fat_size = (tmp1 + tmp2 - 1) // tmp2
            self.data_lba = self.fat_lba + NUM_FATS * self.fat_size
            self.cluster_count = (PART_LBA + self.part_sectors - self.data_lba) // self.spc
            if self.cluster_count >= 65525:
                break
        else:
            raise RuntimeError("image too small for FAT32")
        self.fat = [0] * (self.cluster_count + 2)
        self.fat[0] = 0x0FFFFFF8
        self.fat[1] = 0x0FFFFFFF
        self.fat[2] = 0x0FFFFFFF  # empty root
        self.next_cluster = 3
        self.fh = None

    def _open(self, create: bool):
        if create:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self.fh = open(self.path, "wb+")
            chunk = b"\x00" * (1024 * 1024)
            for _ in range(self.size_mb):
                self.fh.write(chunk)
            self.fh.flush()
        else:
            self.fh = open(self.path, "rb+")
            self.size_mb = os.path.getsize(self.path) // (1024 * 1024)

    def close(self):
        if self.fh:
            self.fh.close()
            self.fh = None

    def _write_lba(self, lba: int, data: bytes):
        self.fh.seek(lba * SECTOR)
        self.fh.write(data)

    def _read_lba(self, lba: int, count: int = 1) -> bytes:
        self.fh.seek(lba * SECTOR)
        return self.fh.read(count * SECTOR)

    def _clus_to_lba(self, clus: int) -> int:
        return self.data_lba + (clus - 2) * self.spc

    def _alloc(self, nclus: int) -> list[int]:
        if self.next_cluster + nclus > self.cluster_count + 2:
            raise RuntimeError("FAT32 image full")
        chain = list(range(self.next_cluster, self.next_cluster + nclus))
        self.next_cluster += nclus
        for i, c in enumerate(chain):
            self.fat[c] = chain[i + 1] if i + 1 < len(chain) else 0x0FFFFFFF
        return chain

    def _write_chain(self, chain: list[int], data: bytes):
        off = 0
        cs = self.spc * SECTOR
        for c in chain:
            block = data[off:off + cs]
            if len(block) < cs:
                block = block + b"\x00" * (cs - len(block))
            self._write_lba(self._clus_to_lba(c), block)
            off += cs

    def _format(self):
        # MBR
        mbr = bytearray(SECTOR)
        # bootable partition, type FAT32 LBA
        start_chs = (0, 32, 33)  # ignored; LBA is what matters
        mbr[446] = 0x80
        mbr[447:450] = b"\x00\x20\x21"
        mbr[450] = 0x0C
        mbr[451:454] = b"\xfe\xff\xff"
        struct.pack_into("<I", mbr, 454, PART_LBA)
        struct.pack_into("<I", mbr, 458, self.part_sectors)
        mbr[510] = 0x55
        mbr[511] = 0xAA
        self._write_lba(0, bytes(mbr))

        vol_id = int(time.time()) & 0xFFFFFFFF
        bpb = bytearray(SECTOR)
        bpb[0:3] = b"\xEB\x58\x90"
        bpb[3:11] = b"MSWIN4.1"
        struct.pack_into("<H", bpb, 11, SECTOR)
        bpb[13] = self.spc
        struct.pack_into("<H", bpb, 14, RESERVED)
        bpb[16] = NUM_FATS
        struct.pack_into("<H", bpb, 17, 0)
        struct.pack_into("<H", bpb, 19, 0)
        bpb[21] = 0xF8
        struct.pack_into("<H", bpb, 22, 0)
        struct.pack_into("<H", bpb, 24, 63)
        struct.pack_into("<H", bpb, 26, 16)
        struct.pack_into("<I", bpb, 28, PART_LBA)
        struct.pack_into("<I", bpb, 32, self.part_sectors)
        struct.pack_into("<I", bpb, 36, self.fat_size)
        struct.pack_into("<H", bpb, 40, 0)
        struct.pack_into("<H", bpb, 42, 0)
        struct.pack_into("<I", bpb, 44, ROOT_CLUSTER)
        struct.pack_into("<H", bpb, 48, 1)
        struct.pack_into("<H", bpb, 50, 6)
        bpb[64] = 0x80
        bpb[66] = 0x29
        struct.pack_into("<I", bpb, 67, vol_id)
        bpb[71:82] = self.label.encode("ascii")
        bpb[82:90] = b"FAT32   "
        bpb[510] = 0x55
        bpb[511] = 0xAA
        self._write_lba(PART_LBA, bytes(bpb))
        self._write_lba(PART_LBA + 6, bytes(bpb))

        fsinfo = bytearray(SECTOR)
        struct.pack_into("<I", fsinfo, 0, 0x41615252)
        struct.pack_into("<I", fsinfo, 484, 0x61417272)
        struct.pack_into("<I", fsinfo, 488, 0xFFFFFFFF)
        struct.pack_into("<I", fsinfo, 492, 3)
        fsinfo[510] = 0x55
        fsinfo[511] = 0xAA
        self._write_lba(PART_LBA + 1, bytes(fsinfo))
        self._write_lba(PART_LBA + 7, bytes(fsinfo))

        # empty root cluster
        self._write_lba(self._clus_to_lba(ROOT_CLUSTER), b"\x00" * (self.spc * SECTOR))

    def _flush_fat(self):
        raw = bytearray(self.fat_size * SECTOR)
        for i, v in enumerate(self.fat):
            struct.pack_into("<I", raw, i * 4, v)
        for fat_n in range(NUM_FATS):
            self._write_lba(self.fat_lba + fat_n * self.fat_size, bytes(raw))

    def _dir_entries(self, names_data: list[tuple[str, int, int, int, bool]]) -> bytes:
        """names_data: (name, cluster, size, attr, is_dir)"""
        used = set()
        date, tim = _now_fat()
        blobs = []
        for name, clus, size, attr, is_dir in names_data:
            short11 = _short_base(name, used)
            for e in _lfn_entries(name, short11):
                blobs.append(e)
            ent = bytearray(32)
            ent[0:11] = short11
            ent[11] = attr
            struct.pack_into("<H", ent, 14, tim)
            struct.pack_into("<H", ent, 16, date)
            struct.pack_into("<H", ent, 18, date)
            struct.pack_into("<H", ent, 20, (clus >> 16) & 0xFFFF)
            struct.pack_into("<H", ent, 22, tim)
            struct.pack_into("<H", ent, 24, date)
            struct.pack_into("<H", ent, 26, clus & 0xFFFF)
            struct.pack_into("<I", ent, 28, 0 if is_dir else size)
            blobs.append(bytes(ent))
        return b"".join(blobs)

    def _write_dir(self, cluster: int, entries: bytes, is_root: bool, parent: int = 0):
        date, tim = _now_fat()
        prefix = b""
        if not is_root:
            def dot(name, clus):
                e = bytearray(32)
                e[0:11] = name
                e[11] = 0x10
                struct.pack_into("<H", e, 20, (clus >> 16) & 0xFFFF)
                struct.pack_into("<H", e, 26, clus & 0xFFFF)
                struct.pack_into("<H", e, 14, tim)
                struct.pack_into("<H", e, 16, date)
                struct.pack_into("<H", e, 22, tim)
                struct.pack_into("<H", e, 24, date)
                return bytes(e)
            prefix = dot(b".          ", cluster) + dot(b"..         ", parent)
        payload = prefix + entries
        need = max(1, (len(payload) + self.spc * SECTOR - 1) // (self.spc * SECTOR))
        # Root already owns cluster 2; extend if needed.
        chain = [cluster]
        if need > 1:
            extra = self._alloc(need - 1)
            self.fat[cluster] = extra[0]
            chain.extend(extra)
        self._write_chain(chain, payload)

    def add_tree(self, src_dir: Path, extra: dict[str, bytes] | None = None):
        src_dir = Path(src_dir)

        def walk(host: Path, dir_clus: int, parent_clus: int, is_root: bool):
            items = []
            children = []
            for child in sorted(host.iterdir(), key=lambda p: p.name.lower()):
                if child.name.startswith("."):
                    continue
                if child.is_dir():
                    chain = self._alloc(1)
                    items.append((child.name, chain[0], 0, 0x10, True))
                    children.append((child, chain[0]))
                else:
                    data = child.read_bytes()
                    nclus = max(1, (len(data) + self.spc * SECTOR - 1) // (self.spc * SECTOR))
                    chain = self._alloc(nclus)
                    self._write_chain(chain, data)
                    items.append((child.name, chain[0], len(data), 0x20, False))
            if is_root:
                for name, data in (extra or {}).items():
                    nclus = max(1, (len(data) + self.spc * SECTOR - 1) // (self.spc * SECTOR))
                    chain = self._alloc(nclus)
                    self._write_chain(chain, data)
                    items.append((name, chain[0], len(data), 0x20, False))
            blob = self._dir_entries(items)
            self._write_dir(dir_clus, blob, is_root, parent_clus)
            for child, clus in children:
                walk(child, clus, dir_clus, False)

        walk(src_dir, ROOT_CLUSTER, 0, True)

    def create_and_fill(self, src_dir: Path, extra: dict[str, bytes] | None = None):
        print(f"Creating {self.size_mb} MB FAT32 image at {self.path}")
        self._open(True)
        try:
            self._format()
            self.add_tree(src_dir, extra)
            self._flush_fat()
        finally:
            self.close()
        print(f"Wrote {self.path} ({self.size_mb} MB)")


def write_vmdk_descriptor(desc_path: Path, flat_path: Path, size_mb: int):
    sectors = (size_mb * 1024 * 1024) // SECTOR
    cyl = sectors // (16 * 63)
    cid = f"{int(time.time()) & 0xFFFFFFFF:08x}"
    # Extent must sit next to the descriptor so VMware resolves it
    # relative to the VMDK (and, when the VMX lives in the same folder,
    # relative to the VMX as well).
    flat_name = flat_path.name
    text = (
        "# Disk DescriptorFile\n"
        "version=1\n"
        'encoding="windows-1252"\n'
        f"CID={cid}\n"
        "parentCID=ffffffff\n"
        'createType="monolithicFlat"\n'
        "\n"
        "# Extent description\n"
        f'RW {sectors} FLAT "{flat_name}" 0\n'
        "\n"
        "# The Disk Data Base\n"
        "#DDB\n"
        "\n"
        'ddb.virtualHWVersion = "19"\n'
        f'ddb.geometry.cylinders = "{cyl}"\n'
        'ddb.geometry.heads = "16"\n'
        'ddb.geometry.sectors = "63"\n'
        'ddb.adapterType = "ide"\n'
    )
    desc_path.write_text(text, encoding="ascii")
    print(f"Wrote VMDK descriptor {desc_path} (CID={cid}, {sectors} sectors)")


def _parse_existing(path: Path, file_prefix: str = ""):
    """Open an existing image produced by this tool and yield (name, data)."""
    # mmap so multi-GB disks (e.g. a converted guest HD) are not read into RAM.
    import mmap
    with open(path, "rb") as fh, mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ) as data:
        if len(data) < (PART_LBA + RESERVED + 2) * SECTOR:
            raise RuntimeError("image too small")
        part_lba = struct.unpack_from("<I", data, 454)[0]
        bpb = data[part_lba * SECTOR:(part_lba + 1) * SECTOR]
        bps = struct.unpack_from("<H", bpb, 11)[0]
        spc = bpb[13]
        reserved = struct.unpack_from("<H", bpb, 14)[0]
        fats = bpb[16]
        fat_size = struct.unpack_from("<I", bpb, 36)[0]
        root = struct.unpack_from("<I", bpb, 44)[0]
        fat_off = (part_lba + reserved) * bps
        data_lba = part_lba + reserved + fats * fat_size

        def fat_ent(c):
            return struct.unpack_from("<I", data, fat_off + c * 4)[0] & 0x0FFFFFFF

        def chain(c):
            out = []
            seen = set()
            while 2 <= c < 0x0FFFFFF8 and c not in seen:
                out.append(c)
                seen.add(c)
                c = fat_ent(c)
            return out

        def clus_bytes(c):
            lba = data_lba + (c - 2) * spc
            return data[lba * bps:(lba + spc) * bps]

        def read_file(c, size):
            buf = b"".join(clus_bytes(x) for x in chain(c))
            return buf[:size]

        def iter_dir(dir_clus, prefix=""):
            raw = b"".join(clus_bytes(c) for c in chain(dir_clus))
            lfn = []
            for off in range(0, len(raw), 32):
                e = raw[off:off + 32]
                if not e or e[0] == 0x00:
                    break
                if e[0] == 0xE5:
                    lfn = []
                    continue
                attr = e[11]
                if attr == 0x0F:
                    units = struct.unpack("<5H", e[1:11]) + struct.unpack("<6H", e[14:26]) + struct.unpack("<2H", e[28:32])
                    lfn.append((e[0] & 0x3F, units))
                    continue
                if attr & 0x08:
                    lfn = []
                    continue
                if lfn:
                    lfn.sort()
                    units = []
                    for _, u in lfn:
                        units.extend(u)
                    chars = []
                    for u in units:
                        if u == 0:
                            break
                        if u != 0xFFFF:
                            chars.append(chr(u))
                    name = "".join(chars)
                else:
                    base = e[0:8].decode("ascii", "replace").rstrip()
                    ext = e[8:11].decode("ascii", "replace").rstrip()
                    name = f"{base}.{ext}" if ext else base
                lfn = []
                clus = struct.unpack_from("<H", e, 26)[0] | (struct.unpack_from("<H", e, 20)[0] << 16)
                size = struct.unpack_from("<I", e, 28)[0]
                rel = f"{prefix}{name}"
                if attr & 0x10:
                    if name in (".", ".."):
                        continue
                    yield from iter_dir(clus, rel + "/")
                else:
                    if name.upper().startswith(file_prefix.upper()):
                        yield rel, read_file(clus, size)

        yield from iter_dir(root)


def extract_prefix(image: Path, dest: Path, prefix: str = "ISO."):
    dest.mkdir(parents=True, exist_ok=True)
    found = []
    for name, blob in _parse_existing(image, prefix):
        base = name.split("/")[-1]
        if base.upper().startswith(prefix.upper()):
            out = dest / base
            out.write_bytes(blob)
            found.append(out)
            print(f"  extracted {name} ({len(blob)} bytes)")
    return found


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("create")
    c.add_argument("--image", required=True)
    c.add_argument("--src", required=True)
    c.add_argument("--size-mb", type=int, default=512)
    c.add_argument("--label", default="RELIC")
    c.add_argument("--vmdk")
    c.add_argument("--marker", action="append", default=[],
                   help="extra root file NAME=TEXT (e.g. RelicDev.TXT=dev)")
    x = sub.add_parser("extract")
    x.add_argument("--image", required=True)
    x.add_argument("--dest", required=True)
    x.add_argument("--prefix", default="ISO.")
    args = ap.parse_args()
    if args.cmd == "create":
        img = Fat32Image(Path(args.image), args.size_mb, args.label)
        extra = {}
        for m in args.marker:
            name, _, text = m.partition("=")
            extra[name] = (text + "\n").encode("ascii")
        img.create_and_fill(Path(args.src), extra)
        if args.vmdk:
            write_vmdk_descriptor(Path(args.vmdk), Path(args.image), args.size_mb)
    else:
        files = extract_prefix(Path(args.image), Path(args.dest), args.prefix)
        if not files:
            print("No matching files.", file=sys.stderr)
            sys.exit(2)


if __name__ == "__main__":
    main()
