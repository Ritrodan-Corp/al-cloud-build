# Windows scrcpy access

This is the low-overhead manual-play path for the AL Cloud Android runtime. It keeps ADB private on the VM and forwards only the loopback ADB socket through the existing IAP/SSH path.

## Install local prerequisites

On Windows, install the official scrcpy package with WinGet:

```powershell
winget install --exact Genymobile.scrcpy
```

The WinGet package installs ADB dependencies alongside scrcpy. Google Cloud CLI must also already be installed and authenticated for access to the AL Cloud VM.

## Start the stream

From a checkout of this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1
```

Defaults:

- VM: `azl-android-arm64-01`
- zone: `us-central1-a`
- remote ADB: `127.0.0.1:5555`
- local forwarded ADB: `127.0.0.1:15555`
- video: H.264, up to 15 FPS, 2 Mbit/s
- audio: disabled

The launcher opens the IAP/SSH tunnel, waits for the local forwarded port, connects ADB, starts scrcpy, and cleans up the local ADB connection and tunnel when scrcpy closes.

If the local gcloud configuration does not already select the correct project, pass it explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 -Project YOUR_PROJECT_ID
```

For diagnostic comparisons, change only one stream parameter at a time, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 -MaxFps 15 -VideoBitRate 1M
```

Do not expose ADB or scrcpy on a public interface. The intended path is always local Windows client -> IAP/SSH tunnel -> VM loopback ADB -> ReDroid.
