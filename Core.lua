-- loot macros, butterbot logging, notebook, presets, and MD/Tricks/Major CD announce/macros

Order65 = LibStub("AceAddon-3.0"):NewAddon("Order65", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0", "AceSerializer-3.0");

Order65.Defaults = {
    profile = {
        min_gs = "4300",
        num_missing_enchants = 3,
        num_missing_gems = 3,
        num_pvp_items = 3,
        quest_list = "24874, 24879, 24869, 24875, 24873, 24878, 24872, 24880, 24870, 24871, 24876, 24877",
        addons = {
            DBM = {filename = "DBM-Core", version = "7.10.cf"}, 
            Order65 = {filename = "Order65", version = "1.0"},
            Omen = {filename = "Omen", version = "3.0.9"}
        }
    }
}

Order65.OptionsTable = {
    type = "group",
    name = "Order65",
    args = {
        general = {
            type = "group",
            name = "General Settings",
            args = {
                intro = {
                    type = "description",
                    name = "Chosen Few Raid Utilities."
                },
                check = {
                    type = "execute",
                    name = "Requirement Check",
                    desc = "Check the raid for requirements. ( /reqcheck )",
                    func = function() Order65:ReqCheck() end,
                },
            }
        },
        quests = {
            type = "group",
            name = "Disallowed Quests",
            args = {
                intro = {
                    order = 0,
                    type = "description",
                    name = "A list of quests that raiders are not allowed to have in their log during the raid check.",
                },
                quest_list = {
                    order = 1,
                    type = "input",
                    name = "A list of quest IDs, comma seperated. Spaces are allowed.",
                    usage = "24874, 24879",
                    -- pattern = "(%d+,? ?)*",
                    multiline = 14,
                    width = "full",
                    set = function(info, val) db.profile.quest_list = val end,
                    get = function(info) return db.profile.quest_list end,
                },
            },
        },
        notebook = {
            type = "group",
            name = "Raid Notebook",
            args = {
                intro = {
                    type = "description",
                    name = "A notebook full of raid information for raid leaders to pass to raiders.",
                },
            },
        },
        addons = {
            type = "group",
            name = "Addon Checker",
            args = {
                intro = {
                    order = 0,
                    type = "description",
                    width = "full",
                    name = "Ensure your raiders have required addons and the correct version.",
                },
                add_addon_name = {
                    order = 1,
                    width = "full",
                    type = "input",
                    name = "Add Addon",
                    desc = "Add the descriptive name of the addon.",
                    set = function(info, val) Order65:AddAddonOptionTable(val) end,
                    get = function(info) return '' end,
                },
            },
        },
        gear = {
            type = "group",
            name = "Gear Requirements",
            args = {
                min_gs = {
                    name = "GearScore Requirement",
                    desc = "Minimum GearScore for the raider for this raid.",
                    type = "input",
                    usage = "5300",
                    pattern = "%d+",
                    multiline = false,
                    set = function(info, val) db.profile.min_gs = val end,
                    get = function(info) return db.profile.min_gs end,
                },
                num_missing_enchants = {
                    name = "Missing Enchants",
                    desc = "How many enchants a raider is allowed to be missing.",
                    type = "range",
                    min = 0,
                    max = 18,
                    step = 1,
                    set = function(info,val) db.profile.num_missing_enchants = val end,
                    get = function(info) return db.profile.num_missing_enchants end
                },
                num_missing_gems = {
                    name = "Missing Gems",
                    desc = "How many gems a raider is allowed to be missing.",
                    type = "range",
                    min = 0,
                    max = 50,
                    step = 1,
                    set = function(info,val) db.profile.num_missing_gems = val end,
                    get = function(info) return db.profile.num_missing_gems end
                },
                num_pvp_items = {
                    name = "PvP Items",
                    desc = "How many PvP items a raider is allowed to use.",
                    type = "range",
                    min = 0,
                    max = 18,
                    step = 1,
                    set = function(info,val) db.profile.num_pvp_items = val end,
                    get = function(info) return db.profile.num_pvp_items end
                },
            }
        }
    }
}

local AceGUI = LibStub("AceGUI-3.0")


function Order65:OnEnable()
    -- self:openEditBook()
    -- self:openNoteBook()
end

function Order65:OnInitialize()
    self:RegisterComm("ORDER65")
    self.is_checking = false
    self.raid_data = {}
    self.notebook = ""
    self:GetScore()
    self.db = LibStub("AceDB-3.0"):New("Order65DB", Order65.Defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    db = self.db
    self:SetupOptions()

    self:RegisterChatCommand("o65", "ShowConfig")
    self:RegisterChatCommand("order65", "ShowConfig")
    self:RegisterChatCommand("reqcheck", "ReqCheck")
    self:RegisterChatCommand("requirementcheck", "ReqCheck")
    self:RegisterChatCommand("requirementcheck", "OpenNoteBook")
end

function Order65:RefreshConfig()
    db = self.db
end

function Order65:SetupOptions()
    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local AceConfigReg = LibStub("AceConfigRegistry-3.0")
    Order65.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    AceConfigReg:RegisterOptionsTable("Order65", Order65.OptionsTable);

    self.OptionsFrames = {}
    self.OptionsFrames.Order65 = AceConfigDialog:AddToBlizOptions("Order65", "Order65", nil, 'general');
    self.OptionsFrames.Quests = AceConfigDialog:AddToBlizOptions("Order65", "Quests", "Order65", 'quests');
    self.OptionsFrames.Notebook = AceConfigDialog:AddToBlizOptions("Order65", "Notebook", "Order65", 'notebook');
    self.OptionsFrames.Gear = AceConfigDialog:AddToBlizOptions("Order65", "Gear", "Order65", 'gear');
    self.OptionsFrames.Addons = AceConfigDialog:AddToBlizOptions("Order65", "Addon Checker", "Order65", 'addons');
    self.OptionsFrames.Profiles = AceConfigDialog:AddToBlizOptions("Order65", "Profiles", "Order65", "profiles")

    for k, v in pairs(db.profile.addons) do
        self:AddAddonOptionTable(k)
    end

    self.SetupOptions = nil;
end

function Order65:AddAddonOptionTable(name)
    if db.profile.addons[name] == nil then
        db.profile.addons[name] = {filename = '', version = ''}
    end
    self.OptionsTable.args.addons.args[name] = {
        type = "group",
        name = name,
        args = {
            filename = {
                order = 0,
                type = "input",
                name = "Addon Filename",
                set = function(info, val) db.profile.addons[name].filename = val end,
                get = function(val) return db.profile.addons[name].filename end,
            },
            version = {
                order = 1,
                type = "input",
                name = "Addon Version",
                set = function(info, val) db.profile.addons[name].version = val end,
                get = function(val) return db.profile.addons[name].version end,
            },
            delete = {
                order = 15,
                type = "execute",
                name = "Delete",
                width = "full",
                func = function() Order65.OptionsTable.args.addons.args[name] = nil; db.profile.addons[name] = nil; end,
            },
        },
    }
end

function Order65:ShowConfig()
    InterfaceOptionsFrame_OpenToCategory(self.OptionsFrames.Profiles);
    InterfaceOptionsFrame_OpenToCategory(self.OptionsFrames.Order65);
end

function Order65:GatherDataRequest()
    local request = {Quests = {}, Addons = {}}
    for questID in string.gmatch(self.db.profile.quest_list, "([^%s,]+)") do tinsert(request.Quests, questID); end
    for descr in pairs(self.db.profile.addons) do tinsert(request.Addons, self.db.profile.addons[descr].filename) end
    return request
end

function Order65:ReqCheck()
    self:Print("Starting Requirement Check...")
    local channel = ((IsInRaid() == false) and "PARTY") or "RAID"
    if self.is_checking == false then
        self:SendCommMessage("ORDER65", self:Serialize("REQCHECK", self:GatherDataRequest()), channel)
        self.is_checking = true
        self.raid_data = {}
        self:ScheduleTimer("CheckTimer", 1)
    else
        self:Print("You are already querying your group.")
    end
end

function Order65:OpenNoteBook()
    local noteBook = AceGUI:Create("Window")
    noteBook:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    noteBook:SetTitle("Raid Notebook")
    noteBook:SetLayout("Fill")
    noteBook:SetHeight(200)
    noteBook:SetWidth(200)
    local text = AceGUI:Create("Label")
    text:SetFont("Arial Narrow", 10)
    noteBook:AddChild(text)

    text:SetText("|TInterface\\Icons\\INV_Misc_Coin_01:16|t Coins")
end

function Order65:CheckTimer()
    self.is_checking = false
    local had_response = false

    local num_group = 4
    local unit_type = "party"
    if IsInRaid() then
        num_group = 40
        unit_type = "raid"
    end

    if unit_type == "party" then  -- This covers both if we're alone AND if we're in a party
        local name = GetUnitName("player")
        self.raid_data[name] = self:GatherData(self:GatherDataRequest())
        had_response = self:GenerateReportFor(name) or had_response
    end

    -- Check if we got a response from everyone, then report all bad responses
    for i=1,num_group,1 do
        local name = GetUnitName(unit_type..i)
        had_response = self:GenerateReportFor(name) or had_response
    end
    if not had_response then
        self:Print("Everyone meets requirements.")
    end
end

function Order65:GenerateReportFor(name)
    local had_response = false
    if name == nil then
        -- Do nothing
    elseif self.raid_data[name] == nil then
        self:Print(name..": Does not have Order65 or is offline.")
        had_response = true
    else
        local message = {}

        for desc, config in pairs(db.profile.addons) do 
            local found = false
            for _, reported in pairs(Order65.raid_data["Rahuum"].Addons) do
                if reported.name == config.filename then found = reported.version; end;
            end
            if found == false then
                tinsert(message, "Missing "..desc)
            elseif found ~= config.version then
                tinsert(message, desc.. ' is version '..found)
            end
        end

        local check_quests = {}
        for questID in string.gmatch(self.db.profile.quest_list, "([^%s,]+)") do check_quests[questID] = true; end
        for i, questID in pairs(self.raid_data[name].Quests) do
            if check_quests[tostring(questID)] == true then
                tinsert(message, "Bad Quest ("..tostring(questID)..")")
            end
        end
        local gear= self.raid_data[name].Gear;
        if gear.gs < tonumber(self.db.profile.min_gs) then
            tinsert(message, "GS Low ("..gear.gs..")")
        end
        if gear.missing_gems > self.db.profile.num_missing_gems then 
            tinsert(message, gear.missing_gems .. " missing gems")
        end
        if gear.missing_enchants > self.db.profile.num_missing_enchants then 
            tinsert(message, gear.missing_enchants .. " missing enchants")
        end
        if gear.pvp_items > self.db.profile.num_pvp_items then 
            tinsert(message, gear.pvp_items .. " PvP items"); 
        end
        local msg = ""
        for k, v in pairs(message) do
            msg = msg..', '.. v
        end
        if msg ~= "" then
            self:Print(name..": "..msg:sub(3)..".")
            had_response = true
        end
    end
    return had_response
end

function Order65:GatherData(request)
    local response = {Addons={}, Quests={}, Gear={}}
    -- Check Addons
    for i=1,GetNumAddOns(),1 do
        name, _, _, enabled = GetAddOnInfo(i)
        if enabled == 1 then
            version = GetAddOnMetadata(name, "Version")
            for k, v in pairs(request.Addons) do 
                if name == v then
                    tinsert(response.Addons, {name = name, version = version})
                end
            end
        end
    end
    -- Check ICC Quests
    ExpandQuestHeader(0)
    numEntries, numQuests = GetNumQuestLogEntries()
    for i=1, numEntries,1 do
        title, level, tag, shouldGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)
        table.insert(response.Quests, questID)
    end
    -- Check gear
    response.Gear = self.GetScore();
    return response
end

function Order65:OnCommReceived(prefix, message, distribution, sender)
    result, code, data = self:Deserialize(message)
    if code == "REQCHECK" then
        self:SendCommMessage("ORDER65", self:Serialize("REQRESP", self:GatherData(data)), "WHISPER", sender)
    elseif code == "REQRESP" then
        self.raid_data[sender] = data
    end
end
