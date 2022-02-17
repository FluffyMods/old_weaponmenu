-- Copyright (C) 2021  DoJoMan18
-- This script is licensed under "GNU General Public License v3.0". https://www.gnu.org/licenses/gpl-3.0.html

_menuPool = NativeUI.CreatePool()
mainMenu = NativeUI.CreateMenu("Weapons", "~b~© 2021 Team Reaver")
_menuPool:Add(mainMenu)
local raw = LoadResourceFile(GetCurrentResourceName(), 'weapons.json')
local data = json.decode(raw)
local SubMenus = {}; Items = {}

SubMenus[mainMenu] = mainMenu

-- Functions
function CreateWeaponMenu(menu)

    for WeaponName, WeaponData in pairs(data) do
        if WeaponData.category and not SubMenus[WeaponData.category] then
            SubMenus[WeaponData.category] = _menuPool:AddSubMenu(menu, WeaponData.category)
            submenu_cat = SubMenus[WeaponData.category]
        elseif WeaponData.category and SubMenus[WeaponData.category] then
            submenu_cat = SubMenus[WeaponData.category]
        else
            submenu_cat = menu
        end

        if not IsWeaponValid(GetHashKey(WeaponName)) then
            local Unavailable = NativeUI.CreateItem("~m~".. WeaponData.label, "Weapon unavailable")
            Unavailable:SetRightBadge(BadgeStyle.Lock)
            submenu_cat:AddItem(Unavailable)

            table.insert(Items, {Unavailable, WeaponName, false})
        else
            if not SubMenus[WeaponName] then
                SubMenus[WeaponName] = _menuPool:AddSubMenu(submenu_cat, WeaponData.label)
            end
    
            local Spawn = NativeUI.CreateItem("~r~Equip/Remove " .. WeaponData.label, "Add or remove this weapon to/from your inventory.")
            Spawn:SetLeftBadge(BadgeStyle.Gun)
            SubMenus[WeaponName]:AddItem(Spawn)
            table.insert(Items, {Spawn, WeaponName})

            local Refill = NativeUI.CreateItem("Refill ammo", "Get max ammo for this weapon.")
            Refill:SetLeftBadge(BadgeStyle.Ammo)
            SubMenus[WeaponName]:AddItem(Refill)
            table.insert(Items, {Refill, WeaponName, "refill"})

            for attachments_key,attachments_value in pairs(WeaponData.attachments) do
                if attachments_value then
                    SubMenus[attachments_key] = _menuPool:AddSubMenu(SubMenus[WeaponName], attachments_key)
        
                    for _, attach_item  in ipairs(attachments_value) do
                        attach = NativeUI.CreateItem(attach_item.label, "Add or remove attachment to/from your weapon.")
                        SubMenus[attachments_key]:AddItem(attach)
                        table.insert(Items, {attach, WeaponName, attach_item.value})
                    end
                end
            end
        end
    end

    for SubMenuIndex, SubMenu in pairs(SubMenus) do
        SubMenu.OnItemSelect = function(Sender, Item, Index)
            for _, Value in pairs(Items) do
                if Item == Value[1] then
                    if Value[3] ~= nil then
                        if Value[3] == false then
                            ShowNotification("Buy this weapon at: https://fluffy.tebex.io/")
                        elseif Value[3] == "refill" then
                            local _, ammo = GetMaxAmmo(GetPlayerPed(-1), GetHashKey(Value[2]))
                            AddAmmoToPed(GetPlayerPed(-1), GetHashKey(Value[2]), ammo)
                        elseif HasPedGotWeaponComponent(GetPlayerPed(-1), GetHashKey(Value[2]), GetHashKey(Value[3])) then
                            RemoveWeaponComponentFromPed(GetPlayerPed(-1), GetHashKey(Value[2]), GetHashKey(Value[3]))
                        else
                            GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey(Value[2]), GetHashKey(Value[3]))
                        end
                    else
                        if HasPedGotWeapon(GetPlayerPed(-1), GetHashKey(Value[2])) then
                            RemoveWeaponFromPed(GetPlayerPed(-1), GetHashKey(Value[2]))
                        else
                            GiveWeaponToPed(GetPlayerPed(-1), GetHashKey(Value[2]), 1000, false, true)
                        end
                    end
                end
            end
        end
    end
end

-- Creating and maintaining menu
function GenerateMenu(menu) 
    mainMenu:Clear()

    CreateWeaponMenu(mainMenu)
    
    -- refresh menu index
    _menuPool:RefreshIndex()
    mainMenu:RefreshIndex()
    _menuPool:MouseControlsEnabled(false)
    _menuPool:ControlDisablingEnabled(false)
end

GenerateMenu(mainMenu)

RegisterCommand('+weapons', function()
    mainMenu:Visible(not mainMenu:Visible())
end, false)

RegisterKeyMapping('+weapons', "WeaponMenu", 'keyboard', 'F7')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        _menuPool:ProcessMenus()
    end
end)

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end