# Windows scrcpy fallback

This helper is a paused engineering fallback for the retained GCP rollback/development environment. The current preferred manual-control path is the browser streaming/control stack described in the authoritative private canon.

The helper documents a private IAP/OpenSSH forwarding pattern without publishing deployment identifiers.

Provide the target VM and zone from private configuration when launching:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 \
  -Instance YOUR_PRIVATE_INSTANCE \
  -Zone YOUR_PRIVATE_ZONE \
  -Project YOUR_PRIVATE_PROJECT \
  -SshUser YOUR_PRIVATE_SSH_USER \
  -SshKey YOUR_PRIVATE_SSH_KEY
```

The path remains local client -> IAP TCP tunnel -> OpenSSH port forward -> VM loopback ADB -> ReDroid. Do not expose ADB or scrcpy on a public interface.

The launcher intentionally has no public default instance, zone, project, SSH username, or key identity. Supply those values explicitly or through a private wrapper/configuration source.
