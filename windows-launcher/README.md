# Azur Lane Cloud Windows launcher

Use `Azur Lane Cloud.vbs` as the normal one-click entry point.

It checks whether `http://127.0.0.1:8766/api/status` is already reachable. If so, it opens the controller immediately. Otherwise it starts the same proven Google Cloud IAP + SSH local forward used during manual testing, waits for the controller to become reachable, then opens `http://127.0.0.1:8766/` in the default browser.

Requirements:
- Google Cloud CLI (`gcloud.cmd`) installed and on PATH.
- Existing Google Cloud authentication/authorization for the project.
- The VM and browser-streaming service must be running.

If the hidden wrapper is blocked or VBScript is unavailable, double-click `azl-cloud-launch.cmd` instead. It performs the same operation with a visible command window.

On setup or tunnel failure, the launcher opens `%LOCALAPPDATA%\AzurLaneCloud\tunnel.log` in Notepad. Successful tunnel processes remain running in the background and can be reused by later launches. They end on Windows sign-out/reboot or when manually terminated.

The launcher deliberately keeps the VM browser service bound to `127.0.0.1:8766`; it does not expose the controller directly on the VM network interface.
