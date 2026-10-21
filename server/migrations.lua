Access.Migrations = {}
Access.MigrationStatus = { total = 1, applied = 0, verified = false }

local definitions = {
    { id = '001_access_receipts', statements = {
        [[CREATE TABLE IF NOT EXISTS `feather_access_receipts` (
            `source_resource` VARCHAR(100) NOT NULL,
            `request_id` VARCHAR(128) NOT NULL,
            `operation` VARCHAR(64) NOT NULL,
            `request_fingerprint` LONGTEXT NOT NULL,
            `result_json` LONGTEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`source_resource`,`request_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin]],
    } },
}

local function Checksum(statements)
    local input, hash = table.concat(statements, '\n-- next statement --\n'), 2166136261
    for index = 1, #input do hash = ((hash ~ input:byte(index)) * 16777619) & 0xffffffff end
    return ('fnv1a32:%08x'):format(hash)
end

function Access.Migrations.Run()
    DB.exec([[CREATE TABLE IF NOT EXISTS `feather_access_schema_migrations` (
        `id` VARCHAR(100) NOT NULL, `checksum` VARCHAR(64) NOT NULL,
        `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin]])
    local known, appliedCount = {}, 0
    for _, migration in ipairs(definitions) do known[migration.id] = true end
    for _, row in ipairs(DB.query('SELECT `id` FROM `feather_access_schema_migrations`')) do
        if not known[row.id] then
            return Access.Err('migration_unknown', 'Database contains a newer or unknown Access migration.',
                { migrationId = row.id })
        end
    end
    for _, migration in ipairs(definitions) do
        local checksum = Checksum(migration.statements)
        local applied = DB.one('SELECT `checksum` FROM `feather_access_schema_migrations` WHERE `id`=?', migration.id)
        if applied and applied.checksum ~= checksum then
            return Access.Err('migration_checksum_mismatch', 'An applied Access migration changed.',
                { migrationId = migration.id })
        end
        if not applied then
            -- MariaDB DDL autocommits. Statements must be restart-safe; record only after all succeed.
            for _, statement in ipairs(migration.statements) do DB.exec(statement) end
            DB.insert('INSERT INTO `feather_access_schema_migrations` (`id`,`checksum`) VALUES (?,?)',
                migration.id, checksum)
            appliedCount = appliedCount + 1
        end
    end
    Access.MigrationStatus = { total = #definitions, applied = appliedCount, verified = true }
    return Access.Ok(Access.Copy(Access.MigrationStatus))
end
