# Quickshell locker

[Português](README.md) · **English**

A process independent of the bar, using `WlSessionLock` and PAM authentication
through the installed Hyprlock policy. The password is never sent in arguments
or written to files. Only PAM success releases the session.

`rice-lock` opens the locker; `rice-lock --preview` opens only the visual preview.
`rice-lock --suspend` waits for the lock confirmation before suspending.
The `rice-lock-bridge` service integrates lock and suspend requests via logind.

The visual uses the theme chosen in the bar: clock and date at the top and a
password field in a capsule below. A click or keystroke reveals the field;
mouse movement does not. A banner with a background shows authentication errors.

- [Usage and shortcuts](../../../docs/usage.md)
- [Isolation, PAM, suspend and recovery](../../../docs/architecture.md)
- [Migration and Hyprlock fallback](../../../docs/migration.md)

The preview is not a lock screen. Authentication, suspend and hotplug validation
require interactive testing on the target machine.
