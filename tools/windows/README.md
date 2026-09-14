# Windows scrcpy access

This is the low-overhead manual-play path for the AL Cloud Android runtime. It keeps ADB private on the VM and forwards only the loopback ADB socket through IAP plus Windows OpenSSH.

## Install local prerequisites

Install the official scrcpy package with WinGet:

```powershell
winget install --exact Genymobile.scrcpy
```

Google Cloud CLI must also be installed and authenticated. Windows OpenSSH client must be available as `ssh.exe`.

Check all prerequisites:

```powershell
scrcpy --version
adb --version
gcloud --version
ssh -V
```

## Why two tunnel layers on Windows

The Windows Google Cloud CLI launches PuTTY/plink for `gcloud compute ssh`. OpenSSH-style forwarding flags are not reliable through that wrapper. The launcher therefore avoids `gcloud compute ssh` for forwarding:

1. `gcloud compute start-iap-tunnel` forwards a local TCP port to VM SSH port 22.
2. Windows `ssh.exe` connects through that local IAP port and forwards local ADB to VM loopback `127.0.0.1:5555`.
3. Local ADB connects to the forwarded socket and scrcpy streams/control the Android guest.

No ADB or scrcpy port is exposed publicly.

## Start the stream

From a current checkout of this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1
```

Defaults:

- VM: `azl-android-arm64-01`
- zone: `us-central1-a`
- local IAP-to-SSH port: `127.0.0.1:22222`
- remote ADB: `127.0.0.1:5555`
- local forwarded ADB: `127.0.0.1:15555`
- SSH user: lower-case Windows username by default; override with `-SshUser` if required
- SSH key: `%USERPROFILE%\.ssh\google_compute_engine`
- video: H.264, up to 15 FPS, 2 Mbit/s
- audio: disabled

If the local gcloud configuration does not select the correct project, pass it explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 -Project YOUR_PROJECT_ID
```

If SSH authentication fails because the VM username differs from the Windows username:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 -SshUser VM_USERNAME
```

For diagnostic comparisons, change only one stream parameter at a time, for example:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 -MaxFps 15 -VideoBitRate 1M
```

Do not expose ADB or scrcpy on a public interface. The intended path is always local Windows client -> IAP TCP tunnel -> Windows OpenSSH port forward -> VM loopback ADB -> ReDroid.
