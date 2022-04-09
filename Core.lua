Order65 = LibStub("AceAddon-3.0"):NewAddon("Order65", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0", "AceSerializer-3.0");

local AceGUI = LibStub("AceGUI-3.0")

local addons_required = {
    {name="DBM-Core", version="1.0.dalawow"},
    {name="Order65", version="1.0"}
}

local quests_check = {24612, 24652}

-- loot macros, butterbot logging, quest/addon report, gear/requirement checker

function Order65:OnEnable()
    self:openEditBook()
    self:openNoteBook()
end

function Order65:OnInitialize()
    self:RegisterChatCommand("o65", "SlashCommand")
    self:RegisterChatCommand("order65", "SlashCommand")
    self:RegisterComm("ORDER65")
    self.is_checking = false
    self.raid_data = {}
    self.notebook = ""
end

function Order65:SlashCommand(msg)
    if IsRaidOfficer() ~= nil and self.is_checking == false then
        self:SendCommMessage("ORDER65", "CHECKIN", "RAID")
        self.is_checking = true
        self.raid_data = {}
        self:ScheduleTimer("CheckTimer", 1)
    else
        self:Print("You are not raid leader or assistant, or are busy.")
    end
end

function Order65:openEditBook()
    local editBook = AceGUI:Create("Window")
    editBook:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    editBook:SetTitle("Edit Raid Notebook")
    editBook:SetLayout("Fill")
    editBook:SetHeight(480)
    editBook:SetWidth(640)
    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBook:AddChild(editBox)
    editBox:SetCallback("OnEnterPressed", function(widget, event, text) Order65:setNoteBook(text) end)
end

function Order65:setNoteBook(msg)
    msg = msg:gsub("%||", "|")
    self.notebook = msg
    self.noteBookText:SetText(msg)
end

function Order65:openNoteBook()
    local noteBook = AceGUI:Create("Window")
    noteBook:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    noteBook:SetTitle("Raid Notebook")
    noteBook:SetLayout("Fill")
    noteBook:SetHeight(200)
    noteBook:SetWidth(200)
    self.noteBookText = AceGUI:Create("Label")
    self.noteBookText:SetFont("Arial Narrow", 10)
    noteBook:AddChild(self.noteBookText)

    text:SetText("|TInterface\\Icons\\INV_Misc_Coin_01:16|t Coins")
end

function Order65:CheckTimer()
    self.is_checking = false
    -- Check if we got a response from everyone, then report all bad responses
    for i=1,40,1 do
        local name = GetRaidRosterInfo(i)
        if name == nil then
            -- Do nothing
        elseif self.raid_data[name] == nil then
            self:Print(name.." does not have Order65.")
        else
            self:Print(name.." responded.")
            for k in pairs(self.raid_data[name].Addons) do
                self:Print(self.raid_data[name].Addons[k].name, self.raid_data[name].Addons[k].version)
            end
            self:Print(self.raid_data[name].Quests)
        end
    end
end

function Order65:OnCommReceived(prefix, message, distribution, sender)
    if distribution == 'WHISPER' then
        result, code, data = self:Deserialize(message)
        self.raid_data[sender] = data
    elseif distribution == 'RAID' then
        local response = {Addons={}, Quests=false}
        -- Check Addons
        for i=1,GetNumAddOns(),1 do
            name, _, _, enabled = GetAddOnInfo(i)
            if enabled == 1 then
                version = GetAddOnMetadata(name, "Version")
                for k in pairs(addons_required) do 
                    if name == addons_required[k].name then
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
            if tContains(quests_check, questID) == 1 then
                response.Quests = true
            end
        end
        self:SendCommMessage("ORDER65", self:Serialize("CHECK", response), "WHISPER", sender)
    end
end
