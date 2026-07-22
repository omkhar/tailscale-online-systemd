# tailscale-online-systemd

This repository contains systemd examples for services that bind to a Tailscale address.
The examples delay the service until Tailscale reports that the local node is ready.

This repository uses ASD-STE100 Simplified Technical English for repository-authored documentation.

## Scope

Use these examples on a Linux system that has systemd and the Tailscale Linux package.
The two drop-in examples require these package items:

- `/usr/bin/tailscale`
- `tailscaled.service`
- `tailscale-wait-online.service`
- `tailscale-online.target`

The inline example requires only `/usr/bin/tailscale` and `tailscaled.service` from this list.

This update was validated against Tailscale v1.98.9.
The upstream units use `/usr/bin/tailscale`.
Check the installed units before you use an example on a different package.

No application runtime is in this repository.
The validation workflow uses Ubuntu 24.04, Bash, ShellCheck, and `systemd-analyze`.
It uses `actions/checkout` v7.0.1 and `zizmorcore/zizmor-action` v0.6.0.
Dependabot checks GitHub Actions each day.

## Readiness contract

The Tailscale package defines this dependency chain:

```text
protected service
  -> tailscale-online.target
  -> tailscale-wait-online.service
  -> tailscaled.service
```

The wait service runs `/usr/bin/tailscale wait`.
With a TUN interface, the command waits for these conditions:

- `tailscaled` responds.
- The backend state is `Running`.
- The node has at least one Tailscale IP address.
- A local network interface has that address.

In userspace-networking mode, the command does not wait for a physical interface.
It still waits for `tailscaled`, the `Running` state, and a reported Tailscale address.

The upstream wait service has `Type=oneshot` and `RemainAfterExit=yes`.
The command has no default timeout and can wait indefinitely.

Use this strict dependency in a drop-in:

```ini
[Unit]
Requires=tailscale-online.target
After=tailscale-online.target
```

`Requires=` starts the target and makes the protected service depend on a successful target start.
`After=` starts the protected service after the target start job finishes.
Both settings are necessary for this strict contract.

Do not use only `After=tailscaled.service`.
The daemon process can start before the Tailscale interface and addresses are ready.

## Examples

- [`examples/basic-drop-in.conf`](examples/basic-drop-in.conf) adds the strict target dependency.
- [`examples/exact-ip-drop-in.conf.template`](examples/exact-ip-drop-in.conf.template) also checks one or two fixed addresses.
- [`examples/inline-wait-wrapper.service`](examples/inline-wait-wrapper.service) waits inside a service that you own.

### Basic drop-in

Use the basic drop-in when the service needs any ready Tailscale address.

For a service named `example.service`, create the drop-in directory:

```sh
sudo install -d -m 0755 /etc/systemd/system/example.service.d
```

Install the example:

```sh
sudo install -m 0644 examples/basic-drop-in.conf \
  /etc/systemd/system/example.service.d/tailscale-online.conf
```

Reload systemd and restart the service:

```sh
sudo systemctl daemon-reload
sudo systemctl restart example.service
```

Inspect the effective unit:

```sh
systemctl cat example.service
systemctl show example.service -p Requires -p After -p ExecStartPre
systemctl status tailscale-online.target tailscale-wait-online.service
```

### Exact-IP drop-in

Use the exact-IP template when a service configuration contains a fixed Tailscale address.
First, get the current addresses:

```sh
tailscale ip
```

Replace `<tailscale-ipv4>` in the template.
Remove the comment marker from the IPv6 line only when the service also needs a fixed IPv6 address.

```ini
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv4>
ExecStartPre=/usr/bin/tailscale ip --assert=<tailscale-ipv6>
```

Each `ExecStartPre=` command must succeed before systemd starts the main service command.
The assertion fails when the address is not one of the current node addresses.

### Inline wrapper

Use the inline unit only when you own the complete service unit.
Replace the address, port, executable, and arguments before installation.

The shell runs `tailscale wait` first.
It uses `exec` to replace the shell with the service process after Tailscale is ready.

For a package-owned service, use a drop-in.
Do not replace the package `ExecStart=` value without a separate review.

## Validation

Run the repository contract:

```sh
bash tests/test-repository.sh
```

On Linux with `systemd-analyze`, run the integration test:

```sh
bash tests/test-systemd.sh
```

Also run these checks before a commit:

```sh
shellcheck tests/test-repository.sh tests/test-systemd.sh
actionlint
zizmor --pedantic .
git diff --check
```

The integration test uses local stub units.
It checks systemd syntax and dependency loading.
It does not start Tailscale or a protected service.

No mutation target applies to these configuration examples.
The repository has no product code and no package dependency graph.

## Security

Startup order is not an access-control policy.
Use Tailscale grants for new tailnet policies.
Use the service authentication and authorization controls when they are available.
Use the local firewall policy that the host requires.

Do not publish real node names, tailnet names, addresses, credentials, or logs.
See [`docs/security-considerations.md`](docs/security-considerations.md).

## Known limitations

- The target reports boot-time readiness only.
- The target does not monitor later Tailscale connectivity changes.
- `RemainAfterExit=yes` keeps the wait service active after the first successful check.
- A manual stop or restart of the required target also stops or restarts the protected service.
- `tailscale wait` can wait indefinitely when Tailscale does not become ready.
- The basic example accepts any local Tailscale address.
- A fixed address can change after a node reset, address change, or configuration change.
- The examples do not configure service restart or start-limit policy.
- The inline example still requires `/usr/bin/tailscale` and `tailscaled.service`.
- The examples require the package unit names and CLI paths that this document lists.
- A successful syntax test does not prove correct behavior on a specific host.
- Tailscale readiness does not prove that a peer, route, DNS name, or application is reachable.
- The repository has no live-host or reboot test in CI.

## Documentation

- [`docs/implementation-notes.md`](docs/implementation-notes.md) explains the dependency and failure behavior.
- [`docs/review-checklist.md`](docs/review-checklist.md) lists the host review steps.
- [`docs/security-considerations.md`](docs/security-considerations.md) lists the security boundary.
- [Tailscale CLI reference](https://tailscale.com/docs/reference/tailscale-cli) documents `wait` and `ip --assert`.
- [Tailscale v1.98.9 online target](https://github.com/tailscale/tailscale/blob/v1.98.9/cmd/tailscaled/tailscale-online.target) is the validated target source.
- [Tailscale v1.98.9 wait service](https://github.com/tailscale/tailscale/blob/v1.98.9/cmd/tailscaled/tailscale-wait-online.service) is the validated wait-service source.
- [systemd unit documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) defines `Requires=` and `After=`.
- [systemd service documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) defines `ExecStartPre=`.
- [Tailscale grants](https://tailscale.com/docs/features/access-control/grants) documents the current access-control method.

## License

The Apache License 2.0 applies to this repository.
See [`LICENSE`](LICENSE).
The standard license text is legal text and is not controlled-language documentation.
