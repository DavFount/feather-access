Config = {
    Contract = 1,
    RequiredCoreContract = 1,
    ReadinessTimeoutMs = 30000,
    DevMode = true,
    Audit = {
        Enabled = true, SourceInstance = 'default',
        PollIntervalMs = 1000, BatchSize = 10, LeaseSeconds = 30,
        InitialRetrySeconds = 2, MaximumRetrySeconds = 60, TransportTimeoutMs = 3000,
    },
    Grants = { Managers = {}, Readers = {}, Auditors = {}, MaxValidityMs = 31622400000, CheckTimeoutMs = 5000 },
    Providers = {
        TimeoutMs = 2000,
        MaxInFlight = 32,
        -- Exact target type -> authoritative resource and allowed vocabulary.
        Targets = {},
        -- Organization UUID -> authoritative membership resource.
        Memberships = {},
        TrustedReaders = { ['feather-access'] = true },
    },
}

-- Isolated acceptance resource only. Never enable this on production.
if Config.DevMode then
    Config.Grants.Managers['feather-access-tests'] = true
    Config.Grants.Readers['feather-access-tests'] = true
    Config.Grants.Auditors['feather-access-tests'] = true
    Config.Providers.Targets['access_test.property'] = {
        resource = 'feather-access-tests', capabilities = { 'property.enter' },
    }
    Config.Providers.Targets['access_test.asset'] = {
        resource = 'feather-access-tests', capabilities = { 'asset.retrieve' },
    }
    Config.Providers.Memberships['10000000-0000-4000-8000-000000000001'] = 'feather-access-tests'
    Config.Providers.TrustedReaders['feather-access-tests'] = true
end
