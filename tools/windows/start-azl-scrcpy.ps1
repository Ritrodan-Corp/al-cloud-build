[CmdletBinding()]
param(
    [string]$Instance = "azl-android-arm64-01",
    [string]$Zone = "us-central1-a",
    [string]$Project = "",
    [string]$SshUser = $env:USERNAME.ToLower(),
    [string]$SshKey = "$env:USERPROFILE\.ssh\google_compute_engine",
    [int]$LocalSshPort = 22222,
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

function Wait-TcpPort([int]$Port, [int]$Attempts = 60) {
    for ($i = 0; $i -lt $Attempts; $i++) {
        try {
            $client = [System.Net.Sockets.TcpClient]::new()
            $task = $client.ConnectAsync("127.0.0.1", $Port)
            if ($task.Wait(250) -and $client.Connected) {
                $client.Close()
                return $true
            }
            $client.Close()
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    return $false
}

$gcloud = Require-Command "gcloud"
$ssh = Require-Command "ssh"
$adb = Require-Command "adb"
$scrcpy = Require-Command "scrcpy"

if (-not (Test-Path $SshKey)) {
    throw "SSH key not found at '$SshKey'. Run one normal gcloud compute ssh connection first so gcloud creates the key."
}

$serial = "127.0.0.1:$LocalAdbPort"
$iap = $null
$sshForward = $null

try {
    $iapArgs = @(
        "compute", "start-iap-tunnel", $Instance, "22",
        "--zone=$Zone",
        "--local-host-port=127.0.0.1:$LocalSshPort"
    )
    if ($Project) {
        $iapArgs += "--project=$Project"
    }

    Write-Host "Opening IAP tunnel to $Instance SSH on local port $LocalSshPort..."
    $iap = Start-Process -FilePath $gcloud -ArgumentList $iapArgs -PassThru -NoNewWindow
    if (-not (Wait-TcpPort -Port $LocalSshPort)) {
        throw "Timed out waiting for IAP SSH tunnel on 127.0.0.1:$LocalSshPort."
    }

    $sshArgs = @(
        "-i", $SshKey,
        "-p", "$LocalSshPort",
        "-N",
        "-L", "127.0.0.1:${LocalAdbPort}:127.0.0.1:${RemoteAdbPort}",
        "-o", "ExitOnForwardFailure=yes",
        "-o", "ServerAliveInterval=30",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "HostKeyAlias=$Instance.iap",
        "$SshUser@127.0.0.1"
    )

    Write-Host "Opening Windows OpenSSH ADB forward as $SshUser..."
    $sshForward = Start-Process -FilePath $ssh -ArgumentList $sshArgs -PassThru -NoNewWindow
    if (-not (Wait-TcpPort -Port $LocalAdbPort)) {
        if ($sshForward.HasExited) {
            throw "OpenSSH forwarding process exited before ADB became ready. If authentication failed, retry with -SshUser using the VM SSH username."
        }
        throw "Timed out waiting for forwarded ADB port 127.0.0.1:$LocalAdbPort."
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
    if ($sshForward -and -not $sshForward.HasExited) {
        Stop-Process -Id $sshForward.Id -Force -ErrorAction SilentlyContinue
    }
    if ($iap -and -not $iap.HasExited) {
        Stop-Process -Id $iap.Id -Force -ErrorAction SilentlyContinue
    }
}
