AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Access.SetState('stopped', 'resource_stopped')
    elseif resource == 'feather-core' or resource == 'feather-mysql' then
        Access.Fail(Access.Err('dependency_unavailable',
            'A required dependency stopped. Restart Access after it is ready.', { resource = resource }))
    end
end)

CreateThread(function()
    local called, result = xpcall(function()
        local valid = Access.ValidateConfig()
        if not valid.ok then return valid end
        local dependencies = Access.StartDependencies()
        if not dependencies.ok then return dependencies end
        -- A stop event during a yielding startup must not be overwritten by ready.
        if Access.GetHealth().value.state == 'failed' then
            return Access.Err('dependency_unavailable', 'A dependency stopped during startup; restart Access.')
        end
        Access.SetState('ready', 'foundation_ready')
        return Access.Ok(true)
    end, debug.traceback)
    if not called then
        print('[feather-access] startup traceback: ' .. tostring(result))
        Access.Fail(Access.Err('startup_failed', 'Access startup raised an exception.'))
    elseif not result.ok then
        Access.Fail(result)
    end
end)
