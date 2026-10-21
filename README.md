# Feather Access

Server-only provider foundation for durable capability delegation in Feather.

Requires `feather-core` Contract 1 and `feather-mysql`. Start both first, then
`ensure feather-access`. After manifest changes, run `refresh` before restarting
the resource. Restart Access after a required dependency stops or restarts.

`config.lua` contains the required contract versions and the per-dependency
readiness timeout in milliseconds (0–60000, default 30000).

Startup verifies checksummed resource-owned migrations. An unknown migration or
checksum mismatch fails startup; restore the matching resource/schema version
rather than deleting the migration ledger. DDL is restart-safe but is not wrapped
in a transaction because MariaDB DDL commits implicitly.

`Config.DevMode` defaults to false. Enabling it trusts only the explicitly named
development provider fixture. Do not enable it in production. The fixture resources
are siblings of Access and are not loaded by Access's manifest.

`Config.Providers` configures exact provider owners and trusted context readers:

```lua
Targets = {
    ['my_storage'] = {
        resource = 'my-storage',
        capabilities = { 'storage.read', 'storage.insert', 'storage.remove' },
    },
},
Memberships = { ['organization-uuid'] = 'my-society' },
TrustedReaders = { ['my-storage'] = true },
```

Replace `organization-uuid` with an actual lowercase UUID. No production providers
are enabled by default. `TimeoutMs` is 10–10000 (default 2000); `MaxInFlight` is
1–128 (default 32). A timed-out callback retains its slot until completion or owner
stop, so hung providers cannot create unlimited background work.

## Server API

- `GetCapabilities()` returns the resource version, contract, state and feature versions.
- `GetHealth()` returns a defensive lifecycle snapshot, including failure details.
- `AwaitReady(timeoutMs?)` waits for foundation readiness with a bounded timeout.
- `RegisterTargetProvider({ targetType, contract = 1, resolve })` registers the
  configured target owner. `resolve({ targetType, targetId })` returns a successful
  envelope containing `{ targetType, targetId, epoch, status, capabilities }`.
  Epoch is an integer from 1 to 9007199254740991. Status is `active`, `suspended`,
  `retired`, or `unavailable`; capabilities are a nonempty exact subset of the
  configured vocabulary.
- `UnregisterTargetProvider({ targetType })` removes the caller's registration.
- `RegisterMembershipProvider({ organizationId, contract = 1, resolve })`
  registers the configured membership owner for one organization UUID.
  `resolve({ organizationId, characterId })` returns a successful envelope with
  `{ organizationId, characterId, status, roleIds }`. Status is `active` or
  `inactive`; inactive membership must have no roles.
- `UnregisterMembershipProvider({ organizationId })` removes the caller's registration.
- `ResolveTargetContext({ targetType, targetId })` and
  `ResolveMembershipContext({ organizationId, characterId })` return validated
  defensive facts to explicitly trusted readers. These calls grant no permission.

Capability/role arrays are dense and duplicate-free, with at most 32 entries.
Names use lowercase stable keys up to 64 characters (`a-z`, digits, `_`, `.`, `-`,
starting with a letter). Role IDs additionally accept lowercase UUIDs. Empty role
arrays confer no implicit eligibility. Providers echo normalized lowercase UUIDs.
Responses include `{ provider = { key, resource, contract, generation } }`.
Generation identifies a runtime registration; it is not a durable delegation epoch.

Caller identity comes from the invoking resource. Registration scopes cannot be
claimed by supplying a resource field. Registrations are ephemeral and are removed
when the provider stops. Providers must re-register after their own or Access's
restart. Duplicate registration requires an explicit owner-only unregister first.

All results use `{ ok = true, value = ... }` or
`{ ok = false, code = 'stable_code', message = '...', details = ... }`.
Health and capability reads are diagnostic; they do not authorize access.

`AccessStatus` and `AccessReleaseContractSmokeTest` are read-only server-console
commands. The release smoke expects development mode off and the trusted fixture
stopped. Run it after reverting test configuration before packaging.

This slice creates `feather_access_schema_migrations` and an empty
`feather_access_receipts` foundation table. There are no grant/check/list services,
grant records, client events, UI, audit publisher or production domain adapters.
Those features report zero. `ready` means dependency/migration/provider foundation
readiness; consumers must also require the feature version they need. Context
resolution does not validate a grantor, authorize a character, preserve grants on
transfer or serialize a later gameplay mutation.

Design and implementation documentation lives in
[feather-framework-docs](../feather-framework-docs/feather-access/ACCESS_IMPLEMENTATION_PLAN.md).
