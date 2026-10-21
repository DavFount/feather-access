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

local function ProviderExport(name, handler)
    Register(name, function(request)
        -- Capture caller before yielding. Payload fields never establish ownership.
        local caller = GetInvokingResource()
        return handler(request, caller)
    end)
end

ProviderExport('RegisterTargetProvider', Access.Providers.RegisterTarget)
ProviderExport('UnregisterTargetProvider', Access.Providers.UnregisterTarget)
ProviderExport('RegisterMembershipProvider', Access.Providers.RegisterMembership)
ProviderExport('UnregisterMembershipProvider', Access.Providers.UnregisterMembership)
ProviderExport('ResolveTargetContext', Access.Providers.ResolveTarget)
ProviderExport('ResolveMembershipContext', Access.Providers.ResolveMembership)
ProviderExport('GrantCapability', Access.Grants.Grant)
ProviderExport('RevokeGrant', Access.Grants.Revoke)
ProviderExport('CheckCapability', Access.Grants.Check)
ProviderExport('ListTargetGrants', Access.Grants.ListTarget)
ProviderExport('ListGranteeGrants', Access.Grants.ListGrantee)
ProviderExport('FindOperation', Access.Grants.Find)
ProviderExport('AuditFixtureControl', Access.Audit.Fixture)
