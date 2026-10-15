local function Register(name, handler)
    exports(name, function(...)
        local called, result = pcall(handler, ...)
        if not called then
            print(('[feather-access] event=export.failed operation=%s'):format(name))
            return Access.Err('internal_error', 'Access operation failed.')
        end
        return result
    end)
end

Register('GetCapabilities', Access.GetCapabilities)
Register('GetHealth', Access.GetHealth)
Register('AwaitReady', Access.AwaitReady)
