RegisterCommand('AccessStatus', function(source)
    if source ~= 0 then return end
    local health = Access.GetHealth().value
    print(('[AccessStatus] state=%s phase=%s migrationsVerified=%s targets=%d memberships=%d inFlight=%d devMode=%s'):format(
        health.state, health.phase, tostring(health.migrations.verified),
        health.providers.targets, health.providers.memberships, health.providers.inFlight, tostring(Config.DevMode)))
    if health.failure then print('[AccessStatus] failure=' .. tostring(health.failure.code)) end
    local counts = {}
    for _, group in ipairs({ 'Managers', 'Readers', 'Auditors' }) do
        counts[group] = 0
        for _, enabled in pairs(Config.Grants[group]) do if enabled == true then counts[group] = counts[group] + 1 end end
    end
    print(('[AccessStatus] grantManagers=%d grantReaders=%d grantAuditors=%d fixtureManager=%s fixtureReader=%s fixtureAuditor=%s'):format(
        counts.Managers, counts.Readers, counts.Auditors,
        tostring(Config.Grants.Managers['feather-access-tests'] == true),
        tostring(Config.Grants.Readers['feather-access-tests'] == true),
        tostring(Config.Grants.Auditors['feather-access-tests'] == true)))
end, true)

RegisterCommand('AccessReleaseContractSmokeTest', function(source)
    if source ~= 0 then return end
    local caps, health = Access.GetCapabilities().value, Access.GetHealth().value
    local fixtureTrusted = false
    for _, definition in pairs(Config.Providers.Targets) do
        fixtureTrusted = fixtureTrusted or definition.resource == 'feather-access-tests'
    end
    for _, owner in pairs(Config.Providers.Memberships) do fixtureTrusted = fixtureTrusted or owner == 'feather-access-tests' end
    fixtureTrusted = fixtureTrusted or Config.Providers.TrustedReaders['feather-access-tests'] == true
    for _, group in ipairs({ 'Managers', 'Readers', 'Auditors' }) do
        fixtureTrusted = fixtureTrusted or Config.Grants[group]['feather-access-tests'] == true
    end
    local tests = {
        { 'ready', health.state == 'ready' },
        { 'migrations verified', health.migrations.verified == true },
        { 'providers supported', caps.features.targetProviders == 1 and caps.features.membershipProviders == 1 },
        { 'grant services supported', caps.features.grants == 1 and caps.features.capabilityChecks == 1 },
        { 'development disabled', Config.DevMode == false },
        { 'fixture not trusted', not fixtureTrusted },
        { 'fixture not running', GetResourceState('feather-access-tests') ~= 'started' },
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test[2] then passed = passed + 1 end
        print(('[AccessReleaseContractSmokeTest] %s %s'):format(test[2] and 'PASS' or 'FAIL', test[1]))
    end
    print(('[AccessReleaseContractSmokeTest] done %d/%d passed (read-only)'):format(passed, #tests))
end, true)
