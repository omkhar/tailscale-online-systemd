# Review Checklist

Use this checklist before applying the pattern to a production service or publishing a derivative example.

## Technical Review

- The service really needs Tailscale online before it starts.
- `Wants=tailscale-online.target` and `After=tailscale-online.target` are both present.
- Exact-IP services use `tailscale ip --assert=<address>` for every fixed Tailscale address they bind.
- The drop-in is installed under `/etc/systemd/system/<unit>.d/`, not by editing a package-owned unit.
- `systemctl daemon-reload` was run after installing the drop-in.
- `systemctl cat <unit>` shows the merged configuration expected.
- `systemctl show <unit> -p Wants -p After -p ExecStartPre` confirms the dependency and pre-start checks.
- The service starts cleanly after Tailscale is online.
- A reboot test confirms the ordering works during boot.

## Editorial Review

- The README explains the problem before the solution.
- Examples use placeholders rather than real infrastructure values.
- Commands are copyable after replacing placeholders.
- The distinction between dependency and ordering is explicit.
- The security section does not imply that startup ordering is access control.
- Links point to primary documentation.
- Commit messages describe the change without tool-generated wording.

## Publication Review

- No real IP addresses, hostnames, tailnet names, credentials, or logs are present.
- `git status --short` shows only intended files.
- The repository license is Apache-2.0.
- The first commit is small, direct, and reviewable.
