local QBOX_AVAILABLE = GetResourceState('qbx_core') == 'started'

local CityState = {
    treasury = Config.DefaultTreasury or 1000000,
    taxRate = Config.DefaultTaxRate or 20,
    logs = {}
}

local isDbReady = false
local isSavingState = false
local pendingSave = false

local function getLocale()
    local loc = Config.Locale or 'th'
    return Config.Locales and Config.Locales[loc] or Config.Locales.th
end

local function trimText(val)
    if type(val) ~= 'string' then
        return ''
    end
    return (val:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function formatClockNow()
    return os.date('%H:%M')
end

local function pushLog(logType, text)
    local cleanText = trimText(text)
    if cleanText == '' then
        return
    end

    table.insert(CityState.logs, 1, {
        type = logType or 'system',
        text = cleanText,
        time = formatClockNow()
    })

    local maxLogs = Config.MaxLogs or 15
    while #CityState.logs > maxLogs do
        table.remove(CityState.logs)
    end
end

local function getPublicState()
    local copiedLogs = {}
    for i = 1, #CityState.logs do
        local entry = CityState.logs[i]
        copiedLogs[i] = {
            type = entry.type,
            text = entry.text,
            time = entry.time
        }
    end

    return {
        treasury = CityState.treasury,
        taxRate = CityState.taxRate,
        logs = copiedLogs
    }
end

local function saveStateToDb()
    if not isDbReady then
        return
    end

    if isSavingState then
        pendingSave = true
        return
    end

    isSavingState = true
    local payloadLogs = json.encode(CityState.logs or {})

    MySQL.update(
        'UPDATE `tx_mayor_data` SET `treasury` = ?, `tax_rate` = ?, `logs` = ? WHERE `id` = 1',
        { CityState.treasury, CityState.taxRate, payloadLogs },
        function()
            isSavingState = false
            if pendingSave then
                pendingSave = false
                saveStateToDb()
            end
        end
    )
end

local function initDatabase()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `tx_mayor_data` (
            `id` INT NOT NULL PRIMARY KEY,
            `treasury` BIGINT NOT NULL DEFAULT 1000000,
            `tax_rate` INT NOT NULL DEFAULT 20,
            `logs` LONGTEXT NULL
        )
    ]], {}, function(createResult)
        if not createResult then
            print('^1[tx_mayor] Failed to initialize tx_mayor_data table.^7')
            return
        end

        MySQL.query('SELECT `treasury`, `tax_rate`, `logs` FROM `tx_mayor_data` WHERE `id` = 1', {}, function(rows)
            if rows and rows[1] then
                CityState.treasury = tonumber(rows[1].treasury) or (Config.DefaultTreasury or 1000000)
                CityState.taxRate = tonumber(rows[1].tax_rate) or (Config.DefaultTaxRate or 20)

                if rows[1].logs and rows[1].logs ~= '' then
                    local ok, decoded = pcall(json.decode, rows[1].logs)
                    if ok and type(decoded) == 'table' then
                        CityState.logs = decoded
                    end
                end
            else
                local defaultLogs = json.encode(CityState.logs or {})
                MySQL.insert(
                    'INSERT INTO `tx_mayor_data` (`id`, `treasury`, `tax_rate`, `logs`) VALUES (1, ?, ?, ?)',
                    { CityState.treasury, CityState.taxRate, defaultLogs }
                )
            end

            isDbReady = true
            TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())
        end)
    end)
end

local function isPlayerMayor(source)
    if source == 0 then
        return true
    end

    if not QBOX_AVAILABLE then
        return IsPlayerAceAllowed(source, 'command')
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return false
    end

    local job = player.PlayerData.job
    local requiredJob = Config.MayorJob or 'mayor'
    if job.name ~= requiredJob then
        return false
    end

    if Config.MinMayorGrade and (job.grade and job.grade.level or 0) < Config.MinMayorGrade then
        return false
    end

    return true
end

local function getPlayerDisplayName(source)
    if QBOX_AVAILABLE then
        local player = exports.qbx_core:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            local first = trimText(player.PlayerData.charinfo.firstname or '')
            local last = trimText(player.PlayerData.charinfo.lastname or '')
            local full = trimText((first .. ' ' .. last))
            if full ~= '' then
                return full
            end
        end
    end

    return GetPlayerName(source) or ('ID ' .. tostring(source))
end

local function giveSpecialLicenseItem(source, citizenId, licenseType)
    if not Config.GiveLicenseItem or not Config.LicenseItems then
        return
    end

    local itemName = Config.LicenseItems[licenseType]
    if not itemName or itemName == '' then
        return
    end

    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:AddItem(source, itemName, 1, {
                issuedBy = getPlayerDisplayName(source),
                citizenId = citizenId,
                licenseType = licenseType
            })
        end)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if GetResourceState('oxmysql') == 'started' then
        initDatabase()
    else
        AddEventHandler('onResourceStart', function(startedRes)
            if startedRes == 'oxmysql' then
                initDatabase()
            end
        end)
    end
end)

RegisterNetEvent('tx_mayor:server:requestOpen', function()
    local src = source
    local loc = getLocale()

    if not isPlayerMayor(src) then
        TriggerClientEvent('tx_mayor:client:notify', src, loc.not_mayor or 'คุณไม่มีสิทธิ์เข้าถึงระบบนายกเทศมนตรี', 'error')
        return
    end

    TriggerClientEvent('tx_mayor:client:openMenu', src, getPublicState())
end)

lib.callback.register('tx_mayor:server:submitAction', function(source, payload)
    local loc = getLocale()

    if not isPlayerMayor(source) then
        return {
            ok = false,
            message = loc.not_mayor or 'คุณไม่มีสิทธิ์ดำเนินการในระบบนายกเทศมนตรี'
        }
    end

    if type(payload) ~= 'table' or type(payload.action) ~= 'string' then
        return {
            ok = false,
            message = loc.invalid_input or 'ข้อมูลที่ส่งมาไม่ถูกต้อง'
        }
    end

    local action = payload.action
    local actorName = getPlayerDisplayName(source)

    if action == 'deposit' then
        local amount = math.floor(tonumber(payload.amount) or 0)
        if amount <= 0 then
            return { ok = false, message = loc.invalid_amount or 'กรุณาระบุจำนวนเงินให้ถูกต้อง' }
        end

        if QBOX_AVAILABLE then
            local player = exports.qbx_core:GetPlayer(source)
            if not player then
                return { ok = false, message = loc.player_not_found or 'ไม่พบข้อมูลผู้เล่น' }
            end

            local moneyType = Config.MoneyType or 'cash'
            local currentMoney = (player.PlayerData.money and player.PlayerData.money[moneyType]) or 0
            if currentMoney < amount then
                return { ok = false, message = loc.insufficient_funds or 'เงินในตัวไม่เพียงพอ' }
            end

            local removed = player.Functions.RemoveMoney(moneyType, amount, 'tx_mayor_deposit')
            if not removed then
                return { ok = false, message = loc.insufficient_funds or 'ไม่สามารถหักเงินได้' }
            end
        end

        CityState.treasury = CityState.treasury + amount
        pushLog('deposit', ('%s ฝากเงินเข้าคลัง +$%s'):format(actorName, amount))
        saveStateToDb()
        TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())

        return {
            ok = true,
            message = (loc.deposit_success or 'ฝากเงินเข้าคลังสำเร็จ $%s'):format(amount),
            state = getPublicState()
        }

    elseif action == 'withdraw' then
        local amount = math.floor(tonumber(payload.amount) or 0)
        if amount <= 0 then
            return { ok = false, message = loc.invalid_amount or 'กรุณาระบุจำนวนเงินให้ถูกต้อง' }
        end

        if CityState.treasury < amount then
            return { ok = false, message = loc.treasury_low or 'งบประมาณในคลังเมืองไม่เพียงพอ' }
        end

        CityState.treasury = CityState.treasury - amount

        if QBOX_AVAILABLE then
            local player = exports.qbx_core:GetPlayer(source)
            if player then
                local moneyType = Config.MoneyType or 'cash'
                player.Functions.AddMoney(moneyType, amount, 'tx_mayor_withdraw')
            end
        end

        pushLog('withdraw', ('%s ถอนเงินจากคลัง -$%s'):format(actorName, amount))
        saveStateToDb()
        TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())

        return {
            ok = true,
            message = (loc.withdraw_success or 'ถอนเงินจากคลังสำเร็จ $%s'):format(amount),
            state = getPublicState()
        }

    elseif action == 'set_tax' then
        local newTax = math.floor(tonumber(payload.taxRate) or -1)
        local minTax = Config.MinTaxRate or 0
        local maxTax = Config.MaxTaxRate or 50

        if newTax < minTax or newTax > maxTax then
            return {
                ok = false,
                message = (loc.invalid_tax or 'อัตราภาษีต้องอยู่ระหว่าง %d%% - %d%%'):format(minTax, maxTax)
            }
        end

        CityState.taxRate = newTax
        pushLog('tax', ('%s ปรับอัตราภาษีเป็น %d%%'):format(actorName, newTax))
        saveStateToDb()
        TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())

        return {
            ok = true,
            message = (loc.tax_updated or 'อัปเดตอัตราภาษีเป็น %d%% เรียบร้อยแล้ว'):format(newTax),
            state = getPublicState()
        }

    elseif action == 'issue_license' then
        local citizenId = string.upper(trimText(payload.citizenId or ''))
        local licenseType = trimText(payload.licenseType or '')

        if citizenId == '' or licenseType == '' then
            return { ok = false, message = loc.license_missing_fields or 'กรุณากรอก Citizen ID และประเภทใบอนุญาต' }
        end

        if QBOX_AVAILABLE then
            local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(citizenId)
            if targetPlayer and targetPlayer.Functions and targetPlayer.Functions.SetMetaData then
                local licenses = targetPlayer.PlayerData.metadata and targetPlayer.PlayerData.metadata.licences or {}
                licenses[licenseType] = true
                targetPlayer.Functions.SetMetaData('licences', licenses)
                giveSpecialLicenseItem(targetPlayer.PlayerData.source, citizenId, licenseType)
            else
                local rows = MySQL.query.await('SELECT `metadata` FROM `players` WHERE `citizenid` = ? LIMIT 1', { citizenId })
                if not rows or not rows[1] then
                    return { ok = false, message = loc.citizen_not_found or 'ไม่พบข้อมูลพลเมืองตาม Citizen ID ที่ระบุ' }
                end

                local ok, meta = pcall(json.decode, rows[1].metadata or '{}')
                if type(meta) ~= 'table' or not ok then
                    meta = {}
                end
                meta.licences = type(meta.licences) == 'table' and meta.licences or {}
                meta.licences[licenseType] = true

                MySQL.update.await(
                    'UPDATE `players` SET `metadata` = ? WHERE `citizenid` = ?',
                    { json.encode(meta), citizenId }
                )
            end
        end

        pushLog('license', ('%s ออกใบอนุญาต [%s] ให้ %s'):format(actorName, licenseType, citizenId))
        saveStateToDb()
        TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())

        return {
            ok = true,
            message = (loc.license_issued or 'ออกใบอนุญาต %s ให้ %s เรียบร้อยแล้ว'):format(licenseType, citizenId),
            state = getPublicState()
        }

    elseif action == 'announce' then
        local message = trimText(payload.message or '')
        if message == '' then
            return { ok = false, message = loc.empty_announcement or 'กรุณาพิมพ์ข้อความประกาศคำสั่งเมือง' }
        end

        local maxLen = Config.MaxAnnouncementLength or 180
        if #message > maxLen then
            message = string.sub(message, 1, maxLen)
        end

        pushLog('announce', ('%s ประกาศ: %s'):format(actorName, message))
        saveStateToDb()
        TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())

        if Config.BroadcastAnnouncement ~= false then
            TriggerClientEvent('tx_mayor:client:cityAnnouncement', -1, {
                title = loc.announcement_title or 'ประกาศคำสั่งเมือง',
                author = actorName,
                message = message
            })
        end

        return {
            ok = true,
            message = loc.announcement_sent or 'ส่งประกาศคำสั่งเมืองเรียบร้อยแล้ว',
            state = getPublicState()
        }
    end

    return {
        ok = false,
        message = loc.unknown_action or 'ไม่พบคำสั่งที่ร้องขอ'
    }
end)

exports('GetTreasury', function()
    return CityState.treasury
end)

exports('GetTaxRate', function()
    return CityState.taxRate
end)

exports('AddTreasuryTax', function(amount, sourceLabel)
    local taxAmount = math.floor(tonumber(amount) or 0)
    if taxAmount <= 0 then
        return false
    end

    CityState.treasury = CityState.treasury + taxAmount

    local label = trimText(sourceLabel or '')
    if label ~= '' then
        pushLog('tax', ('ภาษีเข้าคลัง +$%s (%s)'):format(taxAmount, label))
    else
        pushLog('tax', ('ภาษีเข้าคลัง +$%s'):format(taxAmount))
    end

    saveStateToDb()
    TriggerClientEvent('tx_mayor:client:syncState', -1, getPublicState())
    return true
end)