# Review checklist

Use this checklist before you change a production service.

## Host check

- Confirm that the host uses systemd.
- Confirm that the Tailscale package supplies the units and CLI path in `README.md`.
- Record the installed Tailscale version.
- Confirm that the protected service must bind to a Tailscale address.
- Identify each fixed address in the service configuration.
- Plan a recovery method before a reboot test.

## Configuration check

- Use `Requires=tailscale-online.target`.
- Use `After=tailscale-online.target`.
- Add one `tailscale ip --assert=<address>` command for each required fixed address.
- Install the drop-in below `/etc/systemd/system/<unit>.d/`.
- Do not edit a package-owned unit.
- Run `systemctl daemon-reload` after installation.

## Verification check

- Run `systemctl cat <unit>`.
- Run `systemctl show <unit> -p Requires -p After -p ExecStartPre`.
- Start the service while Tailscale is ready.
- Confirm that the service listens only on the intended address and port.
- Test the failure behavior with an approved maintenance procedure.
- Reboot the host during an approved maintenance window.
- Confirm the final service and Tailscale status.

## Security check

- Configure Tailscale grants or the approved existing access policy.
- Keep service authentication enabled when it is available.
- Apply the required local firewall policy.
- Do not publish real names, addresses, credentials, or logs.

## Repository check

- Run both test scripts.
- Run ShellCheck, actionlint, and zizmor.
- Confirm that the documents describe the changed behavior and limitations.
- Confirm that `git diff --check` passes.
- Sign the commit.
- Wait for CI and review before merge.
