"""Develop the imported RelicOS platform on a QEMU disk, without building an ISO."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import time
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "platform"
DISK = BUILD / "RelicOS.raw"
SHA = "ab4bc69e1e7f2a74563a4960fd1020b5c55dae4d"

def qemu(name):
    found = shutil.which(name)
    if found:
        return found
    candidate = Path.home() / "scoop/apps/qemu/current" / (name + ".exe")
    if candidate.is_file():
        return str(candidate)
    raise SystemExit(f"Missing {name}")

def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def wsl_path(path):
    path = Path(path).resolve()
    return "/mnt/" + path.drive[0].lower() + "/" + path.as_posix()[3:]

def mtool(name, *args):
    env = dict(os.environ, MTOOLS_SKIP_CHECK="1")
    command = shutil.which(name)
    if command:
        return run([command, *args], env=env)
    return run(["wsl", "--cd", "/tmp", "--exec", "env", "MTOOLS_SKIP_CHECK=1", name, *args])

def image():
    with DISK.open("rb") as f:
        f.seek(454)
        offset = struct.unpack("<I", f.read(4))[0] * 512
    if offset < 512 or offset > DISK.stat().st_size - 512:
        raise SystemExit("Invalid development disk partition")
    path = str(DISK) if shutil.which("mcopy") else wsl_path(DISK)
    return f"{path}@@{offset}"

def monitor(command):
    try:
        with socket.create_connection(("127.0.0.1", 4445), timeout=2) as sock:
            sock.recv(4096)
            sock.sendall((command + "\n").encode())
            try:
                while sock.recv(4096):
                    if command != "quit": break
            except (TimeoutError, ConnectionResetError):
                pass
    except OSError:
        if command != "quit":
            raise

def assert_off():
    try:
        with socket.create_connection(("127.0.0.1", 4445), timeout=1):
            raise SystemExit("Stop the platform VM before writing its disk")
    except OSError:
        pass

def bootstrap():
    BUILD.mkdir(parents=True, exist_ok=True)
    if DISK.exists():
        raise SystemExit("Development disk exists; use start or stage")
    boot = BUILD / "bootstrap.iso"
    if not boot.exists():
        data = urllib.request.urlopen(f"https://raw.githubusercontent.com/y4my4my4m/YDE/{SHA}/build/AUTO.ISO", timeout=60).read()
        boot.write_bytes(data)
    data = boot.read_bytes()
    tree = json.loads((ROOT / "research/upstream/YDE-tree.json").read_text())
    expected = next(e["sha"] for e in tree["tree"] if e["path"] == "build/AUTO.ISO")
    actual = hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()
    if actual != expected:
        raise SystemExit("Bootstrap integrity failure")
    run([qemu("qemu-img"), "create", "-f", "raw", str(DISK), "4G"])
    launch(bootstrap_image=boot)

def launch(bootstrap_image=None):
    assert_off()
    if not DISK.is_file():
        raise SystemExit("Run bootstrap first")
    args = [qemu("qemu-system-x86_64"), "-machine", "q35", "-accel", "tcg", "-drive", f"file={DISK},format=raw", "-m", "2G", "-smp", "4", "-rtc", "base=localtime", "-device", "isa-debug-exit", "-display", "none", "-vnc", "127.0.0.1:2", "-monitor", "tcp:127.0.0.1:4445,server,nowait", "-device", "qemu-xhci,id=xhci", "-device", "usb-tablet,bus=xhci.0", "-netdev", "user,id=n0", "-device", "rtl8139,netdev=n0", "-audiodev", "dsound,id=snd0", "-device", "AC97,audiodev=snd0"]
    args += ["-cdrom", str(bootstrap_image)] if bootstrap_image else ["-boot", "c"]
    log = (BUILD / "qemu.log").open("ab")
    kwargs = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {"start_new_session": True}
    process = subprocess.Popen(args, cwd=ROOT, stdout=log, stderr=log, **kwargs)
    log.close()
    (BUILD / "qemu.pid").write_text(str(process.pid))
    print(f"Platform VM PID {process.pid}; VNC127.0.0.1:5902. Existing upstream bootstrap only; no ISO built.")

def stage():
    assert_off()
    source = ROOT / "src/platform"
    if not (source / "StartOS.ZC").is_file():
        raise SystemExit("Platform source import is incomplete")
    backup = BUILD / "RelicOS.bootstrap.raw"
    if not backup.exists():
        shutil.copyfile(DISK, backup)
    disk = image()
    try:
        mtool("mmd", "-D", "s", "-i", disk, "::/Tmp/OSBuild")
    except subprocess.CalledProcessError:
        mtool("mdir", "-i", disk, "::/Tmp/OSBuild")
    children = [str(p) if shutil.which("mcopy") else wsl_path(p)
                for p in sorted(source.iterdir()) if not p.name.startswith(".")]
    mtool("mcopy", "-s", "-Q", "-o", "-i", disk, *children, "::/Tmp/OSBuild/")
    copy_to_disk(development_kernel_config(), "::/Tmp/OSBuild/Kernel/Kernel.PRJ")
    first = BUILD / "RelicStage1.ZC"
    first.write_bytes((source / "Misc/Auto/AutoFullDistro1.ZC").read_bytes().replace(
        b"In(in_str);", b"//Managed VM configuration is supplied in Kernel.PRJ.").replace(
        b"Reboot;", b'I64 log_n; U8 *log_b=DocSave(DocPut,&log_n); FileWrite("C:/Tmp/RelicCompile.DD",log_b,log_n); Free(log_b); OutU8(0x501,0x31);'))
    ready = BUILD / "RelicStageReady.ZC"
    ready.write_text('U0 Auto(){OnceFlush; FileWrite("::/Tmp/RelicPlatform.READY","ready",5);}')
    once = BUILD / "Once.ZC"
    once.write_text('#include "::/Misc/Auto/AutoFullDistro1";;')
    for host, target in [(first, "::/Misc/Auto/AutoFullDistro1.ZC"), (ready, "::/Tmp/OSBuild/Misc/Auto/AutoFullDistro4.ZC"), (once, "::/Home/Once.ZC"), (once, "::/Once.ZC")]:
        localfile = str(host) if shutil.which("mcopy") else wsl_path(host)
        mtool("mcopy", "-Q", "-o", "-i", disk, localfile, target)
    print("Staged full source and disk-only rebuild. Stage4 signals ready; ISO build is excluded.")


def copy_to_disk(host, target):
    localfile = str(host) if shutil.which("mcopy") else wsl_path(host)
    mtool("mcopy", "-o", "-i", image(), localfile, target)


def development_kernel_config():
    """The managed VM has one boot disk, C:, on AHCI. Avoid interactive In/StrGet."""
    source = (ROOT / "src/platform/Kernel/Kernel.PRJ").read_bytes()
    old = b"kernel_config = KConfigNew;"
    if source.count(old) != 1:
        raise SystemExit("Unexpected kernel configuration project")
    config = b'''kernel_config = CAlloc(sizeof(CKConfig));
    kernel_config->add_dev = DocNew;
    kernel_config->boot_drive_let = 'C';
    kernel_config->home_dir = StrNew("::/Home");
    kernel_config->disk_cache_size_exp = StrNew("Scale2Mem(0x80000,0x8000000)");
    kernel_config->opts[CONFIG_MOUNT_AHCI_AUTO] = TRUE;
    kernel_config->mount_ide_auto_hd_let = 'C';
    kernel_config->mount_ide_auto_cd_let = 'T';'''
    generated = BUILD / "Kernel-dev.PRJ"
    generated.write_bytes(source.replace(old, config))
    return generated


def sync():
    """Update an installed development disk; retain Home data and settings."""
    assert_off()
    source = ROOT / "src/platform"
    children = [str(p) if shutil.which("mcopy") else wsl_path(p)
                for p in sorted(source.iterdir()) if not p.name.startswith(".")]
    mtool("mcopy", "-s", "-Q", "-o", "-i", image(), *children, "::/")
    for name in ["HomeSys.ZC", "MakeHome.ZC", "Once.ZC"]:
        copy_to_disk(source / name, "::/Home/" + name)
    # A stale upstream distribution callback must never reach its ISO phase.
    ready = BUILD / "RelicStageReady.ZC"
    ready.write_text('U0 Auto(){OnceFlush; FileWrite("::/Tmp/RelicPlatform.READY","ready",5);}')
    copy_to_disk(ready, "::/Misc/Auto/AutoFullDistro4.ZC")
    print("Source synced. Kernel/compiler changes require rebuild, then start again.")


def rebuild():
    """Compile and install the kernel on the existing disk; never run distro stages."""
    sync()
    once = BUILD / "Rebuild.ZC"
    copy_to_disk(development_kernel_config(), "::/Kernel/Kernel.PRJ")
    once.write_text('U0 RelicRebuild(){WinMax; OnceFlush; SysOnceFlush; DocClear; '
                    'BootHDIns(\'C\'); I64 n; U8 *b=DocSave(DocPut,&n); '
                    'FileWrite("::/Tmp/RelicCompile.DD",b,n); Free(b); '
                    'OutU8(0x501,0x31);} RelicRebuild;')
    copy_to_disk(once, "::/Home/Once.ZC")
    launch()
    print("Guest compiles and exits. Inspect Tmp/RelicCompile.DD, run sync, then start.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["bootstrap", "stage", "sync", "rebuild", "start", "stop"])
    args = parser.parse_args()
    {"bootstrap": bootstrap, "stage": stage, "sync": sync, "rebuild": rebuild,
     "start": launch, "stop": lambda: monitor("quit")}[args.action]()
