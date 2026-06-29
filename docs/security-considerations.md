# Security Considerations

This pattern solves startup ordering. It does not authenticate clients, authorize users, encrypt application payloads beyond what Tailscale already provides on the network path, or replace service hardening.

## Keep Access Control Separate

Use Tailscale ACLs to decide which users, groups, tags, or devices may reach the service. Also keep the service's own authentication and authorization enabled when appropriate.

Binding a service to a Tailscale IP can reduce exposure compared with binding to every interface, but it is not a complete access-control model by itself.

## Avoid Public Operational Details

Public examples should not include:

- real node names
- tailnet names
- MagicDNS names
- production Tailscale IP addresses
- private LAN addresses
- user emails
- API tokens
- service passwords
- logs from real incidents

Use placeholders such as `<tailscale-ipv4>`, `<tailscale-ipv6>`, and `example.service`.

## Review Before Publishing

Before publishing an example repository, scan for sensitive material:

```sh
grep -RInE '([0-9]{1,3}\.){3}[0-9]{1,3}|fd7a:|ts\.net|password|token|secret|key|@' .
```

Then inspect any matches manually. Automated scans catch patterns, not intent.
