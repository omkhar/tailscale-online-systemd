# Implementation notes

## Upstream units

The Tailscale v1.98.9 source contains `tailscale-online.target` and `tailscale-wait-online.service` for Linux systemd packages.

The target has these dependencies:

```ini
Requires=tailscale-wait-online.service
After=tailscale-wait-online.service
```

The wait service has these important settings:

```ini
After=tailscaled.service
Requires=tailscaled.service
Type=oneshot
ExecStart=/usr/bin/tailscale wait
RemainAfterExit=yes
```

The source links are in `README.md`.

## Protected-service dependency

Use this dependency for a service that must not start after a failed online-target start:

```ini
[Unit]
Requires=tailscale-online.target
After=tailscale-online.target
```

`Requires=` creates the strong dependency.
If the target fails and the protected service is ordered after it, systemd does not start the protected service.

`After=` creates only an order.
It does not start the target and it does not create a success requirement.

`Wants=` creates a weak dependency.
A failure in a wanted unit does not stop the wanting unit from starting.
For this reason, the strict examples do not use `Wants=`.

## Wait behavior

With a TUN interface, `tailscale wait` checks these conditions:

1. The local Tailscale client responds.
2. The backend state is `Running`.
3. The node has a Tailscale IP address.
4. A local interface has the first reported Tailscale address.

In userspace-networking mode, no physical TUN interface exists.
The command still checks the daemon, the `Running` state, and a reported Tailscale address in this mode.

The CLI default timeout is zero.
Zero means that the command waits indefinitely.
The upstream wait service is a oneshot service and does not set a shorter timeout.

## Fixed-address check

Use an address check when a service binds to one fixed Tailscale address:

```ini
[Service]
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv4>
```

The CLI compares the supplied address with the current node addresses.
It exits with a nonzero status when it does not find the address.
The assertion reads Tailscale status.
It does not inspect local interface addresses.

systemd runs the main `ExecStart=` command only after all unprefixed `ExecStartPre=` commands succeed.
Use one check for each fixed address that the service needs.

## Package-service drop-in

Do not edit a package-owned unit.
Install local policy in `/etc/systemd/system/<unit>.d/*.conf`.

```sh
sudo install -d -m 0755 /etc/systemd/system/example.service.d
sudo install -m 0644 examples/basic-drop-in.conf \
  /etc/systemd/system/example.service.d/tailscale-online.conf
sudo systemctl daemon-reload
```

Inspect the effective unit:

```sh
systemctl cat example.service
systemctl show example.service -p Requires -p After -p ExecStartPre
```

## Inline wrapper

Use the inline example only for a service unit that you own.
The shell waits and then replaces itself with the service process:

```ini
ExecStart=/bin/sh -c '/usr/bin/tailscale wait && exec /usr/local/bin/example-service'
```

The wrapper uses `Requires=tailscaled.service` and `After=tailscaled.service`.
The `tailscale wait` command supplies the readiness check.

## Failure and recovery

A failed target start blocks a protected service that uses `Requires=` and `After=`.
An address assertion failure blocks the main service command.
A manual stop or restart of the required target also stops or restarts the protected service.

The examples do not add a restart policy to a package-owned service.
Use the existing service policy or add a reviewed host-specific policy.

The online target is not a continuous monitor.
After its first successful activation, the oneshot wait service stays active because it has `RemainAfterExit=yes`.
A later loss of Tailscale connectivity does not reset the target automatically.
