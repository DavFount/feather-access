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

RegisterCommand('AccessAuditStatus', function(source)
    if source ~= 0 then return end
    CreateThread(function()
        local called, failure = pcall(function()
            local state, counts = Access.Audit.State(), Access.Audit.Counts()
            print(('[AccessAuditStatus] running=%s paused=%s busy=%s auditAvailable=%s transportActive=%s pending=%d leased=%d delivered=%d quarantined=%d'):format(
                tostring(state.running), tostring(state.paused), tostring(state.busy), tostring(state.auditAvailable), tostring(state.transportActive),
                counts.pending, counts.leased, counts.delivered, counts.quarantined))
            if state.lastError then print('[AccessAuditStatus] error=' .. state.lastError) end
        end)
        if not called then print('[AccessAuditStatus] unavailable; verify database/resource readiness') end
    end)
end, true)

RegisterCommand('AccessAuditRetry', function(source, args)
    if source ~= 0 then return end
    CreateThread(function()
        local called, result = pcall(Access.Audit.RetryQuarantine, args[1])
        print('[AccessAuditRetry] ' .. (called and result.ok and 'PASS event requeued without changing payload'
            or 'FAIL ' .. tostring(called and result.code or 'database_unavailable')))
    end)
end, true)

RegisterCommand('AccessAuditInspect', function(source, args)
    if source ~= 0 then return end
    if not Access.Uuid(args[1]) then print('[AccessAuditInspect] usage: AccessAuditInspect <event-UUID>'); return end
    CreateThread(function()
        local called = pcall(function()
            local row = DB.one([[SELECT `event_id`,`event_type`,`status`,`attempt_count`,`last_result`,`audit_event_id`
                FROM `feather_access_outbox` WHERE `event_id`=?]], args[1]:lower())
            if not row then print('[AccessAuditInspect] not found'); return end
            print(('[AccessAuditInspect] eventId=%s type=%s state=%s attempts=%s result=%s auditId=%s'):format(
                row.event_id, row.event_type, row.status, tostring(row.attempt_count), tostring(row.last_result), tostring(row.audit_event_id)))
        end)
        if not called then print('[AccessAuditInspect] database unavailable') end
    end)
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
