Config = {
    Contract = 1,
    RequiredCoreContract = 1,
    ReadinessTimeoutMs = 30000,
    DevMode = false,
    Providers = {
        TimeoutMs = 2000,
        MaxInFlight = 32,
        -- Exact target type -> authoritative resource and allowed vocabulary.
        Targets = {},
        -- Organization UUID -> authoritative membership resource.
        Memberships = {},
        TrustedReaders = {},
    },
}

-- Isolated acceptance resource only. Never enable this on production.
if Config.DevMode then
    Config.Providers.Targets['access_test.property'] = {
        resource = 'feather-access-tests', capabilities = { 'property.enter' },
    }
    Config.Providers.Targets['access_test.asset'] = {
        resource = 'feather-access-tests', capabilities = { 'asset.retrieve' },
    }
    Config.Providers.Memberships['10000000-0000-4000-8000-000000000001'] = 'feather-access-tests'
    Config.Providers.TrustedReaders['feather-access-tests'] = true
end
