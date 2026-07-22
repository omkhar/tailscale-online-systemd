# Security considerations

This pattern controls service start order.
It does not authenticate a client or authorize an operation.
It does not replace service hardening.

## Access control

Use Tailscale grants for a new tailnet policy.
Tailscale continues to support access control lists, but it recommends grants for new policies.
Apply the least privilege that the service requires.

Keep the service authentication and authorization controls enabled when they are available.
Apply the local firewall policy that the host requires.

Binding to a Tailscale address can reduce network exposure.
The bind address is not a complete access-control policy.

## Public data

Do not publish these items:

- node names
- tailnet names
- MagicDNS names
- production Tailscale addresses
- private LAN addresses
- user email addresses
- API tokens
- service passwords
- private keys
- incident logs

Use `<tailscale-ipv4>`, `<tailscale-ipv6>`, and `example.service` as placeholders.

## Publication check

Run the repository contract before publication:

```sh
bash tests/test-repository.sh
```

Inspect the complete diff.
Automated pattern checks cannot determine the intent of all text.
Remove sensitive data from commit messages, pull request text, and CI logs.

## Operational limits

- The online target does not monitor later connectivity changes.
- A ready local interface does not prove that a remote peer is reachable.
- A fixed Tailscale address can change after a node or configuration change.
- A service can still expose an unintended port if its own configuration is wrong.
- An indefinite wait can keep a boot transaction active.
