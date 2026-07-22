# Contributing

Keep each change small and specific to systemd services that depend on Tailscale readiness.

## Content rules

- Use ASD-STE100 Simplified Technical English for repository-authored prose.
- Use primary sources for technical claims.
- Use placeholders for host-specific values.
- Do not add real hostnames, tailnet names, addresses, credentials, or logs.
- State each package or distribution requirement.
- Update all affected documents and tests in the same change.
- Do not edit `LICENSE`.

## Example rules

- Use `Requires=tailscale-online.target` and `After=tailscale-online.target` for the strict drop-in pattern.
- Use `tailscale ip --assert=<address>` for each fixed address that a service needs.
- Put a package-service override in `/etc/systemd/system/<unit>.d/`.
- Do not edit a package-owned unit in `/usr/lib/systemd/system` or `/lib/systemd/system`.
- Keep the inline wrapper generic.

## Tests

Run these local checks:

```sh
bash tests/test-repository.sh
bash tests/test-systemd.sh
shellcheck tests/test-repository.sh tests/test-systemd.sh
actionlint
zizmor --pedantic .
git diff --check
```

The systemd test skips on a host that does not have `systemd-analyze`.
Run it on Linux before you publish a systemd change.

The repository has no product-code mutation target.
Do not claim mutation coverage for documentation or configuration files.

## Pull request

- Use a signed commit.
- Describe the changed contract.
- Include the local test results.
- Wait for CI and review before merge.
- Remove sensitive data from test output and comments.
