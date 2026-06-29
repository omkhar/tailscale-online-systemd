# Contributing

Contributions are welcome when they keep the repository focused on small, reusable systemd examples for Tailscale-dependent services.

## Guidelines

- Prefer primary documentation links.
- Keep examples generic.
- Use placeholders for infrastructure-specific values.
- Do not include real hostnames, tailnet names, IP addresses, credentials, or logs.
- Avoid distribution-specific assumptions unless the example says which distribution it targets.
- Keep commit messages concise and descriptive.

## Testing Changes

For unit drop-ins, verify the merged unit on a Linux system with Tailscale installed:

```sh
systemctl cat example.service
systemctl show example.service -p Wants -p After -p ExecStartPre
```

For exact-IP examples, confirm that the assertion succeeds only for an address assigned to the node:

```sh
tailscale ip
tailscale ip --assert=<tailscale-ipv4>
```
