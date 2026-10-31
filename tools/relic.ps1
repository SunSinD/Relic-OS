<#
.SYNOPSIS
  RelicOS host tool: dev loop, VM control, screenshots and ISO build.

.DESCRIPTION
  One VM lives in build\vm\RelicOS (git-ignored):

      RelicOS.vmx            VNC on 127.0.0.1:5901 so tools\vnc.py can drive it
      RelicOS-HD.vmdk        installed RelicOS        (IDE 1:1, boots from here)
      transfer.vmdk + -flat  FAT32 copy of src\relic  (IDE 0:0, written by prepare)
      CD                     build\RelicOS-v0.5.0.iso (IDE 1:0)

  dev      stop VM -> write src\relic to the transfer disk -> boot.  The guest
           HomeSys.HC sees RelicDev.TXT on that disk and copies the sources
           onto the installed system before the desktop starts.
  iso      same, but the marker says "build": RelicBoot.HC runs Build.HC
           before the desktop, the host waits for the ISO chunks, powers
           off and assembles build\RelicOS-v0.5.0.iso (a few minutes).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\relic.ps1 dev
  powershell -ExecutionPolicy Bypass -File tools\relic.ps1 shot
  powershell -ExecutionPolicy Bypass -File tools\relic.ps1 iso
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('dev', 'prepare', 'start', 'stop', 'shot', 'iso', 'extract', 'newvm', 'log')]
    [string]$Command = 'dev',

    [string]$Iso,
    [string]$Version = '0.5.0',
    [int]$TransferMB = 512,
    [switch]$Network,
    [switch]$LegacyBoot,
    [int]$VncPort = 5901
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$SourceDir = Join-Path $RepoRoot 'src\relic'
$BuildDir = Join-Path $RepoRoot 'build'
$VmDir = Join-Path $BuildDir 'vm\RelicOS'
$Vmx = Join-Path $VmDir 'RelicOS.vmx'
$HdPath = Join-Path $VmDir 'RelicOS-HD.vmdk'
$FlatPath = Join-Path $VmDir 'transfer-flat.vmdk'
$DescPath = Join-Path $VmDir 'transfer.vmdk'
$IsoOut = Join-Path $BuildDir "RelicOS-v$Version.iso"
$ShotDir = Join-Path $BuildDir 'shots'
$Fat32Py = Join-Path $PSScriptRoot 'fat32img.py'
$VncPy = Join-Path $PSScriptRoot 'vnc.py'

$VmwareDir = @("${env:ProgramFiles(x86)}\VMware\VMware Workstation", "$env:ProgramFiles\VMware\VMware Workstation") |
    Where-Object { Test-Path (Join-Path $_ 'vmrun.exe') } | Select-Object -First 1
if (-not $VmwareDir) { throw 'VMware Workstation (vmrun.exe) not found.' }
$Vmrun = Join-Path $VmwareDir 'vmrun.exe'
$Vdisk = Join-Path $VmwareDir 'vmware-vdiskmanager.exe'

function Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "   $msg" -ForegroundColor Green }

function Python {
    foreach ($n in 'python.exe', 'py.exe') {
        $c = Get-Command $n -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }
    throw 'Python 3 is required (tools\fat32img.py, tools\vnc.py).'
}

function Vnc([string[]]$VncArgs) {
    & (Python) $VncPy --port $VncPort @VncArgs
    if ($LASTEXITCODE -ne 0) { throw "vnc.py $($VncArgs -join ' ') failed." }
}

function Test-Running {
    $list = & $Vmrun -T ws list
    if ($LASTEXITCODE -ne 0) { throw 'Could not check whether the VM is running.' }
    return [bool]($list | Where-Object { $_ -ieq $Vmx })
}

function Stop-Vm {
    if (Test-Running) {
        Step 'stop: powering off the VM'
        & $Vmrun -T ws stop $Vmx hard | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'vmrun stop failed; transfer disk was not changed.' }
        $stopDeadline = (Get-Date).AddSeconds(30)
        while (Test-Running) {
            if ((Get-Date) -gt $stopDeadline) { throw 'VM did not stop within 30 seconds.' }
            Start-Sleep -Milliseconds 500
        }
        Ok 'VM is off.'
    }
}

function Write-Vmx {
    param([switch]$InstallMode)
    if (-not $Iso) { $script:Iso = $IsoOut }
    $isoLine = ''
    if (Test-Path $Iso) { $isoLine = ($Iso -replace '\\', '/') }
    $text = @"
.encoding = "windows-1252"
config.version = "8"
virtualHW.version = "19"
displayName = "RelicOS Dev"
guestOS = "other-64"
firmware = "bios"
memsize = "2048"
numvcpus = "4"
bios.bootDelay = "0"
bios.hddOrder = "ide1:1"
bios.bootOrder = "$(if ($InstallMode) { 'cdrom,hdd' } else { 'hdd,cdrom' })"
ide1:1.present = "TRUE"
ide1:1.fileName = "RelicOS-HD.vmdk"
ide1:1.deviceType = "disk"
ide0:0.present = "$(if ($InstallMode) { 'FALSE' } else { 'TRUE' })"
ide0:0.fileName = "transfer.vmdk"
ide0:0.deviceType = "disk"
ide1:0.present = "TRUE"
ide1:0.fileName = "$isoLine"
ide1:0.deviceType = "cdrom-image"
ide1:0.startConnected = "$(if ($isoLine) { 'TRUE' } else { 'FALSE' })"
floppy0.present = "FALSE"
ethernet0.present = "$(if ($Network) { 'TRUE' } else { 'FALSE' })"
ethernet0.virtualDev = "vlance"
ethernet0.connectionType = "nat"
usb.present = "FALSE"
sound.present = "TRUE"
sound.autodetect = "TRUE"
sound.fileName = "-1"
svga.autodetect = "TRUE"
mks.enable3d = "FALSE"
mks.gamingMouse.policy = "auto"
tools.syncTime = "FALSE"
uuid.action = "create"
msg.autoAnswer = "TRUE"
gui.enableStretchGuest = "TRUE"
RemoteDisplay.vnc.enabled = "TRUE"
RemoteDisplay.vnc.port = "$VncPort"
"@
    Set-Content -Path $Vmx -Value $text -Encoding ASCII
    Ok "VMX: $Vmx"
}

function Prepare([string]$Mode = 'dev') {
    Step "prepare: $SourceDir -> transfer disk ($Mode)"
    Stop-Vm
    New-Item -ItemType Directory -Path $VmDir -Force | Out-Null
    & (Python) $Fat32Py create --image $FlatPath --src $SourceDir --size-mb $TransferMB `
        --label RELIC --vmdk $DescPath --marker "RelicDev.TXT=$Mode"
    if ($LASTEXITCODE -ne 0) { throw 'fat32img.py create failed.' }
    if (-not (Test-Path $Vmx)) { Write-Vmx }
    $vmText = [IO.File]::ReadAllText($Vmx)
    $vmText = $vmText -replace 'ide0:0.present = "FALSE"', 'ide0:0.present = "TRUE"'
    $vmText = $vmText -replace 'bios.bootOrder = "cdrom,hdd"', 'bios.bootOrder = "hdd,cdrom"'
    $vmText = $vmText -replace 'ide1:0.startConnected = "TRUE"', 'ide1:0.startConnected = "FALSE"'
    if ($Network) {
        $vmText = $vmText -replace 'ethernet0.present = "FALSE"', 'ethernet0.present = "TRUE"'
        if ($vmText -notmatch 'ethernet0.virtualDev') { $vmText += "`nethernet0.virtualDev = `"vlance`"`n" }
        if ($vmText -notmatch 'ethernet0.connectionType') { $vmText += "`nethernet0.connectionType = `"nat`"`n" }
    }
    [IO.File]::WriteAllText($Vmx, $vmText)
}

function Start-Vm {
    Step 'start: booting RelicOS'
    if (-not (Test-Path $Vmx)) { throw "No VM at $Vmx. Run: tools\relic.ps1 newvm" }
    if (-not (Test-Path $HdPath)) { throw "Missing $HdPath." }
    if (Test-Running) {
        Ok 'VM is already running.'
        return
    }
    & $Vmrun -T ws start $Vmx gui | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'vmrun start failed.' }
    if ($LegacyBoot) {
        Start-Sleep -Seconds 3
        Vnc @('key', '1')
    }
    Ok 'VM is booting (about 20 s until the desktop shows).'
}

# Screenshot of the VMware window itself (PrintWindow: works even when the
# window is behind others, never touches other apps).  VMware's VNC server
# misreports fast-changing frames, so VNC is only the fallback.
function Shot {
    New-Item -ItemType Directory -Path $ShotDir -Force | Out-Null
    $path = Join-Path $ShotDir 'latest.png'
    $p = Get-Process vmware -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (-not $p) { Vnc @('shot', $path); return }
    Add-Type -AssemblyName System.Drawing
    if (-not ('RelicPW' -as [type])) {
        Add-Type @"
using System; using System.Runtime.InteropServices;
public class RelicPW {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  public struct RECT { public int L, T, R, B; }
}
"@
    }
    [RelicPW]::SetProcessDPIAware() | Out-Null
    $r = New-Object RelicPW+RECT
    [RelicPW]::GetClientRect($p.MainWindowHandle, [ref]$r) | Out-Null
    $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $dc = $g.GetHdc()
    [RelicPW]::PrintWindow($p.MainWindowHandle, $dc, 3) | Out-Null
    $g.ReleaseHdc($dc)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Ok $path
}

function Extract {
    Step "extract: ISO chunks -> $IsoOut"
    Stop-Vm
    $tmp = Join-Path $BuildDir 'iso-chunks'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    & (Python) $Fat32Py extract --image $FlatPath --dest $tmp --prefix 'ISO.'
    if ($LASTEXITCODE -ne 0) { throw 'No ISO chunks on the transfer disk. Did Build.HC finish?' }
    $sizeFile = Join-Path $tmp 'ISO.SIZE'
    if (-not (Test-Path $sizeFile)) { throw 'No ISO.SIZE on the transfer disk: the guest build did not finish.' }
    # Sort by chunk NUMBER (ISO.P100 must come after ISO.P99, not after ISO.P10).
    $chunks = @(Get-ChildItem $tmp | Where-Object { $_.Name -match '^ISO\.P(\d+)$' } |
        Sort-Object { [int]($_.Name -replace '^ISO\.P', '') })
    for ($i = 0; $i -lt $chunks.Count; $i++) {
        if ([int]($chunks[$i].Name -replace '^ISO\.P', '') -ne $i) { throw "ISO chunk $i is missing." }
    }
    if (Test-Path $IsoOut) { Remove-Item $IsoOut -Force }
    $fs = [IO.File]::Open($IsoOut, [IO.FileMode]::CreateNew)
    try {
        foreach ($c in $chunks) {
            $b = [IO.File]::ReadAllBytes($c.FullName)
            $fs.Write($b, 0, $b.Length)
        }
    } finally { $fs.Close() }
    $sizeText = (Get-Content $sizeFile -Raw).Trim()
    if ($sizeText -notmatch '^\d+$') { throw "The guest build failed ($sizeText). Run tools\relic.ps1 start and read the VM screen." }
    $expected = [int64]$sizeText
    $actual = (Get-Item $IsoOut).Length
    if ($expected -ne $actual) { throw "ISO size mismatch: expected $expected, got $actual." }
    Remove-Item $tmp -Recurse -Force
    Ok "ISO ready: $IsoOut ($([math]::Round($actual / 1MB, 1)) MB)"
}

function Wait-IsoChunks([int]$TimeoutMin = 30) {
    Step 'iso: waiting for the guest to write ISO.SIZE (this takes a few minutes)'
    $deadline = (Get-Date).AddMinutes($TimeoutMin)
    $probe = Join-Path $BuildDir 'iso-probe'
    $py = Python
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 15
        if (Test-Path $probe) { Remove-Item $probe -Recurse -Force }
        # cmd /c keeps python's "No matching files." on stderr away from
        # PowerShell, which would otherwise turn it into a terminating error.
        cmd /c "`"$py`" `"$Fat32Py`" extract --image `"$FlatPath`" --dest `"$probe`" --prefix ISO.SIZE >nul 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Remove-Item $probe -Recurse -Force
            Start-Sleep -Seconds 5
            Ok 'Guest finished writing the ISO.'
            return
        }
        Write-Host '.' -NoNewline
    }
    throw 'Timed out waiting for the ISO build. Run: tools\relic.ps1 shot'
}

function Show-BootLog {
    Step 'log: ::/Home/Boot.LOG from the VM hard disk'
    Stop-Vm
    $tmp = Join-Path $BuildDir 'hd-read'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $flat = Join-Path $tmp 'hd.vmdk'
    & $Vdisk -r $HdPath -t 2 $flat | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'vmware-vdiskmanager could not read the VM disk.' }
    $flatData = Join-Path $tmp 'hd-flat.vmdk'
    cmd /c "`"$(Python)`" `"$Fat32Py`" extract --image `"$flatData`" --dest `"$tmp`" --prefix Boot.LOG >nul 2>&1"
    $log = Join-Path $tmp 'Boot.LOG'
    if (Test-Path $log) { Get-Content $log } else { Write-Host '   No Boot.LOG on the disk.' }
    Remove-Item $tmp -Recurse -Force
}

function NewVm {
    Step "newvm: $VmDir"
    New-Item -ItemType Directory -Path $VmDir -Force | Out-Null
    $installMode = -not (Test-Path $HdPath)
    if ($installMode) {
        & $Vdisk -c -s 4GB -a ide -t 0 $HdPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the system disk.' }
        Ok "Created empty 4 GB disk. Boot the ISO in the VM, install with I, then run dev."
    }
    if (-not (Test-Path $DescPath)) { Prepare }
    Write-Vmx -InstallMode:$installMode
}

switch ($Command) {
    'dev'     { Prepare; Start-Vm }
    'prepare' { Prepare }
    'start'   { Start-Vm }
    'stop'    { Stop-Vm }
    'shot'    { Shot }
    'extract' { Extract }
    'newvm'   { NewVm }
    'log'     { Show-BootLog }
    'iso' {
        Prepare 'build'
        Start-Vm
        Wait-IsoChunks
        Extract
        # Put the "dev" marker back so the next start does not rebuild.
        Prepare 'dev'
    }
}
