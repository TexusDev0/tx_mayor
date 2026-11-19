local isUiOpen = false
local isOpeningTablet = false
local tabletEntity = nil

local function getActiveLocale()
    local lang = Config.Locale or 'th'
    local loc = Config.Locales and (Config.Locales[lang] or Config.Locales.th) or {}
    local licenses = {}

    for _, item in ipairs(Config.Licenses or {}) do
        licenses[#licenses + 1] = {
            value = item.value,
            label = (lang == 'en') and (item.labelEn or item.labelTh or item.value) or (item.labelTh or item.labelEn or item.value)
        }
    end

    return {
        strings = loc,
        licenses = licenses
    }
end

local function loadModelSafe(model, timeoutMs)
    if not IsModelValid(model) then return false end
    if HasModelLoaded(model) then return true end

    RequestModel(model)
    local deadline = GetGameTimer() + (timeoutMs or 3000)
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(10)
    end
    return true
end

local function loadAnimDictSafe(dict, timeoutMs)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)
    local deadline = GetGameTimer() + (timeoutMs or 3000)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(10)
    end
    return true
end

local function stopTabletEffect()
    local ped = PlayerPedId()

    if tabletEntity and DoesEntityExist(tabletEntity) then
        DetachEntity(tabletEntity, true, true)
        DeleteEntity(tabletEntity)
    end
    tabletEntity = nil

    if ped and DoesEntityExist(ped) then
        ClearPedTasks(ped)
    end
end

local function startTabletEffect()
    local cfg = Config.TabletAnimation
    if not cfg or not cfg.enabled then return end

    stopTabletEffect()

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end

    local coords = GetEntityCoords(ped)
    local loadedModel = loadModelSafe(cfg.propModel, cfg.loadTimeoutMs)
    local loadedAnim = loadAnimDictSafe(cfg.animDict, cfg.loadTimeoutMs)

    if loadedModel then
        local obj = CreateObject(cfg.propModel, coords.x, coords.y, coords.z + 0.2, true, true, false)
        if DoesEntityExist(obj) then
            local boneIdx = GetPedBoneIndex(ped, cfg.boneIndex or 60309)
            local off = cfg.offset or vector3(0.03, 0.002, -0.0)
            local rot = cfg.rotation or vector3(10.0, 160.0, 0.0)

            AttachEntityToEntity(obj, ped, boneIdx, off.x, off.y, off.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(cfg.propModel)
            tabletEntity = obj
        end
    end

    if loadedAnim then
        TaskPlayAnim(ped, cfg.animDict, cfg.animName, 3.0, 3.0, -1, 49, 0.0, false, false, false)
        RemoveAnimDict(cfg.animDict)
    end
end

local function closeMayorUi()
    isUiOpen = false
    isOpeningTablet = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUi'
    })
    stopTabletEffect()
end

local function openMayorUi(stateData)
    if isOpeningTablet then return end
    isOpeningTablet = true
    isUiOpen = true

    startTabletEffect()

    local payload = getActiveLocale()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUi',
        locale = payload.strings,
        licenses = payload.licenses,
        data = stateData or {}
    })

    isOpeningTablet = false
end

RegisterNetEvent('tx_mayor:client:openMenu', function(stateData)
    openMayorUi(stateData)
end)

RegisterNetEvent('tx_mayor:client:syncState', function(stateData)
    local payload = getActiveLocale()
    SendNUIMessage({
        action = 'syncState',
        locale = payload.strings,
        licenses = payload.licenses,
        data = stateData or {}
    })
end)

RegisterNetEvent('tx_mayor:client:announce', function(message)
    if not message or message == '' then return end
    lib.notify({
        title = 'ประกาศคำสั่งเมือง',
        description = message,
        type = 'inform',
        duration = 8000
    })
end)

RegisterNetEvent('tx_mayor:client:forceClose', function()
    closeMayorUi()
end)

RegisterNUICallback('closeUi', function(_, cb)
    closeMayorUi()
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('submitAction', function(payload, cb)
    TriggerServerEvent('tx_mayor:server:handleAction', payload)
    if cb then cb({ ok = true }) end
end)

CreateThread(function()
    if not exports or not exports.ox_target then return end

    for _, loc in ipairs(Config.TargetLocations or {}) do
        exports.ox_target:addBoxZone({
            coords = loc.coords,
            size = loc.size or vec3(1.5, 1.5, 2.0),
            rotation = loc.rotation or 0.0,
            debug = loc.debug or false,
            options = {
                {
                    name = 'tx_mayor_open_dashboard',
                    icon = 'fa-solid fa-tablet-screen-button',
                    label = 'เปิดแท็บเล็ตบริหารเมือง',
                    groups = Config.MayorJob,
                    onSelect = function()
                        TriggerServerEvent('tx_mayor:server:requestOpen')
                    end
                }
            }
        })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isUiOpen then
            SetNuiFocus(false, false)
        end
        stopTabletEffect()
    end
end)