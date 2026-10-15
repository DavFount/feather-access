Access = {}

local health = { state = 'starting', phase = 'not_started', contract = 1 }

function Access.Copy(value)
    if type(value) ~= 'table' then return value end
    local snapshot = {}
    for key, child in pairs(value) do snapshot[key] = Access.Copy(child) end
    return snapshot
end

function Access.Ok(value) return { ok = true, value = value } end

function Access.Err(code, message, details)
    return { ok = false, code = code, message = message, details = details }
end

function Access.Integer(value, minimum, maximum)
    return type(value) == 'number' and value == value and value % 1 == 0
        and value >= minimum and value <= maximum
end

function Access.SetState(state, phase, failure)
    -- Dependency loss requires an explicit restart, even if startup later resumes.
    if health.state == 'failed' and state ~= 'failed' and state ~= 'stopped' then return end
    health.state, health.phase, health.failure = state, phase, Access.Copy(failure)
    print(('[feather-access] event=lifecycle.changed state=%s phase=%s'):format(state, phase))
end

function Access.Fail(result)
    Access.SetState('failed', 'dependency_or_startup_failure', result)
    return result
end

function Access.GetHealth() return Access.Ok(Access.Copy(health)) end

function Access.GetCapabilities()
    return Access.Ok({
        resource = GetCurrentResourceName(),
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
        contract = 1,
        state = health.state,
        features = {
            lifecycle = 1, health = 1,
            migrations = 0, targetProviders = 0, membershipProviders = 0,
            grants = 0, revocation = 0, capabilityChecks = 0,
            grantLists = 0, auditRecords = 0, outbox = 0,
            inventoryIntegration = 0, propertyIntegration = 0, assetsIntegration = 0,
        },
    })
end

function Access.AwaitReady(timeoutMs)
    if timeoutMs == nil then timeoutMs = Config.ReadinessTimeoutMs end
    if not Access.Integer(timeoutMs, 0, 60000) then
        return Access.Err('invalid_input', 'Timeout must be an integer from 0 to 60000 ms.')
    end
    local started = GetGameTimer()
    while health.state ~= 'ready' and health.state ~= 'failed' and health.state ~= 'stopped'
        and GetGameTimer() - started < timeoutMs do Wait(25) end
    if health.state == 'ready' then
        local dependencies = Access.CheckDependencies()
        if not dependencies.ok then return Access.Fail(dependencies) end
        return Access.GetHealth()
    end
    if health.state == 'failed' then
        return Access.Err('startup_failed', 'Access requires restart after its dependencies are ready.',
            { health = Access.Copy(health) })
    end
    return Access.Err('not_ready', 'Access foundation is not ready.')
end

function Access.ValidateConfig()
    if type(Config) ~= 'table' or Config.Contract ~= 1 or Config.RequiredCoreContract ~= 1
        or not Access.Integer(Config.ReadinessTimeoutMs, 0, 60000) then
        return Access.Err('invalid_config', 'Contract 1 and a readiness timeout from 0 to 60000 ms are required.')
    end
    return Access.Ok(true)
end
