# AL Cloud wake bus

This file exists only to keep a dedicated long-lived pull request open for AL Cloud timer wake events.

The AL Cloud control-plane Worker will post `ALCLOUD_WAKE` comments to that pull request when scheduled events become due. ChatGPT Work can then watch the pull request for activity.

Do not merge the wake-bus pull request while it is in use. No gameplay state or secrets belong in this file or in wake comments.
