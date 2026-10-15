# Feather Access

Server-only foundation for durable capability delegation in Feather.

Requires `feather-core` Contract 1 and `feather-mysql`. Start both first, then
`ensure feather-access`. After manifest changes, run `refresh` before restarting
the resource. Restart Access after a required dependency stops or restarts.

`config.lua` contains the required contract versions and the per-dependency
readiness timeout in milliseconds (0–60000, default 30000).

## Server API

- `GetCapabilities()` returns the resource version, contract, state and feature versions.
- `GetHealth()` returns a defensive lifecycle snapshot, including failure details.
- `AwaitReady(timeoutMs?)` waits for foundation readiness with a bounded timeout.

All results use `{ ok = true, value = ... }` or
`{ ok = false, code = 'stable_code', message = '...', details = ... }`.
Health and capability reads are diagnostic; they do not authorize access.

This initial foundation has no grant/check/list API, database tables or migrations,
provider registration, client events, UI, or production domain adapters. These
features report zero. `ready` currently means foundation dependencies passed;
consumers must also require the feature version they need.

Design and implementation documentation lives in
[feather-framework-docs](../feather-framework-docs/feather-access/ACCESS_IMPLEMENTATION_PLAN.md).
