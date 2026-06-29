# Implementation Notes

## Prefer `tailscale-online.target`

Modern Linux Tailscale packages provide `tailscale-online.target`. The target depends on `tailscale-wait-online.service`, which runs:

```ini
ExecStart=/usr/bin/tailscale wait
```

`tailscale wait` waits for the Tailscale daemon, backend state, interface, and Tailscale IP assignment before returning successfully.

Use this when you are extending an existing packaged service with a drop-in:

```ini
[Unit]
Wants=tailscale-online.target
After=tailscale-online.target
```

`Wants=` pulls the target into the transaction. `After=` supplies the ordering. Use both.

## Add An Exact-IP Assertion When Binding To A Fixed Address

If the service binds to a specific Tailscale address, waiting for any Tailscale IP may still be too broad. Assert the address that the service configuration requires:

```ini
[Service]
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv4>
```

If the address is missing, `tailscale ip --assert` exits non-zero and systemd does not start the main service process.

## Use A Drop-In For Packaged Services

Do not edit package-owned unit files under `/usr/lib/systemd/system` or `/lib/systemd/system`. Put local policy in `/etc/systemd/system/<unit>.d/*.conf`:

```sh
sudo install -d -m 0755 /etc/systemd/system/example.service.d
sudo install -m 0644 examples/basic-drop-in.conf \
  /etc/systemd/system/example.service.d/tailscale-online.conf
sudo systemctl daemon-reload
```

Review the merged unit:

```sh
systemctl cat example.service
systemctl show example.service -p Wants -p After -p ExecStartPre
```

## Inline Wrapper Pattern

If you own the service unit and can change `ExecStart`, Tailscale's CLI documentation also supports an inline form:

```ini
ExecStart=/bin/sh -c '/usr/bin/tailscale wait && exec /usr/local/bin/example-service'
```

For packaged services, a drop-in is usually cleaner because it avoids replacing the vendor's `ExecStart`.

## Failure Behavior

When `ExecStartPre=` fails, systemd treats the service start as failed and does not run the main `ExecStart=` command. This is useful when starting without the exact Tailscale address would produce a worse failure mode, such as a daemon exiting after partially binding sockets.

Use normal systemd restart and start-limit policy for the service you are protecting.
