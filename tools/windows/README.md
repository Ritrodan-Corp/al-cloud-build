# Windows scrcpy fallback

This helper is a paused engineering fallback for the retained GCP rollback/development environment. The current preferred manual-control path is the browser streaming/control stack.

The helper documents an IAP/OpenSSH forwarding pattern without publishing deployment-specific identifiers.

Provide the target VM, zone, project, SSH user, and SSH key from deployment configuration when launching:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\windows\start-azl-scrcpy.ps1 \
  -Instance YOUR_INSTANCE \
  -Zone YOUR_ZONE \
  -Project YOUR_PROJECT \
  -SshUser YOUR_SSH_USER \
  -SshKey YOUR_SSH_KEY
```

The path remains local client -> IAP TCP tunnel -> OpenSSH port forward -> VM loopback ADB -> ReDroid. Do not expose ADB or scrcpy on a public interface.

The launcher intentionally has no default instance, zone, project, SSH username, or key identity. Supply those values explicitly or through a secure deployment configuration source.
