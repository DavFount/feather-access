RegisterCommand('AccessStatus', function(source)
    if source ~= 0 then return end
    local health = Access.GetHealth().value
    print(('[AccessStatus] state=%s phase=%s migrationsVerified=%s targets=%d memberships=%d inFlight=%d devMode=%s'):format(
        health.state, health.phase, tostring(health.migrations.verified),
        health.providers.targets, health.providers.memberships, health.providers.inFlight, tostring(Config.DevMode)))
    if health.failure then print('[AccessStatus] failure=' .. tostring(health.failure.code)) end
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
    local tests = {
        { 'ready', health.state == 'ready' },
        { 'migrations verified', health.migrations.verified == true },
        { 'providers supported', caps.features.targetProviders == 1 and caps.features.membershipProviders == 1 },
        { 'grants unavailable', caps.features.grants == 0 and caps.features.capabilityChecks == 0 },
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
