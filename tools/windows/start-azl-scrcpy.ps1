[CmdletBinding()]
param(
    [string]$Instance = "azl-android-arm64-01",
    [string]$Zone = "us-central1-a",
    [string]$Project = "",
    [int]$LocalAdbPort = 15555,
    [int]$RemoteAdbPort = 5555,
    [int]$MaxFps = 15,
    [string]$VideoBitRate = "2M"
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "Required command '$Name' was not found on PATH."
    }
    return $cmd.Source
}

$gcloud = Require-Command "gcloud"
$adb = Require-Command "adb"
$scrcpy = Require-Command "scrcpy"
$serial = "127.0.0.1:$LocalAdbPort"
$tunnel = $null

try {
    $gcloudArgs = @(
        "compute", "ssh", $Instance,
        "--zone=$Zone",
        "--tunnel-through-iap"
    )
    if ($Project) {
        $gcloudArgs += "--project=$Project"
    }
    # Use gcloud's explicit SSH-flag interface on Windows instead of the
    # POSIX-style `-- SSH_ARGS` separator. Keep each value space-free so
    # Start-Process cannot accidentally split one SSH flag into two argv items.
    $gcloudArgs += @(
        "--ssh-flag=-N",
        "--ssh-flag=-L${LocalAdbPort}:127.0.0.1:${RemoteAdbPort}",
        "--ssh-flag=-oExitOnForwardFailure=yes",
        "--ssh-flag=-oServerAliveInterval=30"
    )

    Write-Host "Opening IAP/SSH ADB tunnel to $Instance..."
    $tunnel = Start-Process -FilePath $gcloud -ArgumentList $gcloudArgs -PassThru -NoNewWindow

    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        if ($tunnel.HasExited) {
            throw "gcloud SSH tunnel exited before local port $LocalAdbPort became ready."
        }
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            $task = $client.ConnectAsync("127.0.0.1", $LocalAdbPort)
            if ($task.Wait(250) -and $client.Connected) {
                $ready = $true
                $client.Close()
                break
            }
            $client.Close()
        } catch {
            # Tunnel is still starting.
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $ready) {
        throw "Timed out waiting for local tunnel port $LocalAdbPort."
    }

    Write-Host "Connecting local ADB to $serial..."
    & $adb connect $serial
    if ($LASTEXITCODE -ne 0) {
        throw "adb connect failed."
    }

    Write-Host "Launching scrcpy at up to $MaxFps FPS, H.264, $VideoBitRate, no audio."
    & $scrcpy `
        "--serial=$serial" `
        "--no-audio" `
        "--max-fps=$MaxFps" `
        "--video-bit-rate=$VideoBitRate" `
        "--video-codec=h264" `
        "--print-fps" `
        "--window-title=AL Cloud"

    if ($LASTEXITCODE -ne 0) {
        throw "scrcpy exited with code $LASTEXITCODE."
    }
}
finally {
    try { & $adb disconnect $serial | Out-Null } catch {}
    if ($tunnel -and -not $tunnel.HasExited) {
        Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue
    }
}
