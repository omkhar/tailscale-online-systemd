# tailscale-online-systemd

Examples for starting a systemd service only after Tailscale is online and ready for local services to bind to its interface or IP addresses.

This repository is for Linux systems that install Tailscale's systemd units. It focuses on services that bind to a Tailscale address, such as internal dashboards, monitoring endpoints, UPS daemons, admin tools, or small private APIs.

## The Pattern

Use Tailscale's packaged `tailscale-online.target` as the dependency point for your service:

```ini
[Unit]
Wants=tailscale-online.target
After=tailscale-online.target
```

That target runs `tailscale wait`, which waits for Tailscale to be running and for the Tailscale interface and IP address state to be ready.

If your service binds to one exact Tailscale address, add an explicit address assertion before the service starts:

```ini
[Service]
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv4>
```

Add a second assertion if the service also binds to a fixed Tailscale IPv6 address:

```ini
[Service]
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv6>
```

## Why This Matters

`After=tailscaled.service` is usually not enough. It only orders your service after the Tailscale daemon process starts. A service can still start before `tailscale0` exists or before the node's Tailscale IP addresses are assigned.

That timing is enough to break daemons that bind to specific addresses. They may exit with errors such as "cannot assign requested address", "not listening", or "some listening interfaces were not available". If systemd retries quickly, the service can hit its start limit before Tailscale finishes coming online.

`tailscale-online.target` addresses that boot race directly.

## Examples

- [`examples/basic-drop-in.conf`](examples/basic-drop-in.conf): minimal drop-in for services that only need Tailscale to be online.
- [`examples/exact-ip-drop-in.conf.template`](examples/exact-ip-drop-in.conf.template): drop-in template for services that bind to specific Tailscale IP addresses.
- [`examples/inline-wait-wrapper.service`](examples/inline-wait-wrapper.service): alternate pattern for custom services where you control `ExecStart`.

If your installed Tailscale package does not include `tailscale-online.target`, use the inline wrapper pattern or upgrade Tailscale before relying on the drop-in examples.

## Install a Drop-In

For a packaged service named `example.service`, create a drop-in directory:

```sh
sudo install -d -m 0755 /etc/systemd/system/example.service.d
```

Then install the drop-in:

```sh
sudo install -m 0644 examples/basic-drop-in.conf \
  /etc/systemd/system/example.service.d/tailscale-online.conf
```

Reload systemd and restart the service:

```sh
sudo systemctl daemon-reload
sudo systemctl restart example.service
```

Check the merged unit:

```sh
systemctl cat example.service
systemctl show example.service -p Wants -p After -p ExecStartPre
```

Check the dependency path:

```sh
systemctl status tailscale-online.target tailscale-wait-online.service
```

## Exact-IP Variant

Use the exact-IP template when the service configuration contains a fixed Tailscale address in a `listen`, `bind`, or `LISTEN` directive.

First get the node's current Tailscale addresses:

```sh
tailscale ip
```

Then replace the placeholders in `examples/exact-ip-drop-in.conf.template`:

```ini
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv4>
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv6>
```

This prevents the service from starting unless the specific address it needs is actually present.

## Security Notes

Waiting for Tailscale to be online is not an access-control policy. Use Tailscale ACLs, service configuration, and local firewall policy to decide who can reach the listening service.

Avoid committing real tailnet names, node names, private hostnames, production IP addresses, secrets, API keys, logs, or service credentials to public examples.

## Documentation

- Tailscale CLI reference: `tailscale wait`, `tailscale ip`, and `tailscale ip --assert`
  <https://tailscale.com/docs/reference/tailscale-cli>
- Tailscale access controls
  <https://tailscale.com/docs/features/access-control/acls>
- systemd unit dependencies and ordering
  <https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html>
- systemd service `ExecStartPre=`
  <https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html>

## License

Apache License 2.0. See [`LICENSE`](LICENSE).
