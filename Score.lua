
-------------------------------------------------------------------------------
--                    Pulled from GearScoreLite                              --
--                             Version 3x04                                  --
--								Mirrikat45                                   --
-------------------------------------------------------------------------------

--Change Log 3x04
--Fixed an error with GS less over 6000.
--GS will now be reduced on un-enchanted items that are enchantable. 
--Remember that gems are always shown as empty by initial API calls so I cant determine if gems are missing or not.

Order65.tooltip = CreateFrame("GameTooltip", "Order65ScanTooltip", UIParent, "GameTooltipTemplate")
Order65.tooltip:SetOwner(UIParent, "ANCHOR_NONE")

function Order65:GetScore()
	local PlayerClass, PlayerEnglishClass = UnitClass("player");
	local GearScore = 0; local TitanGrip = 1;
	local missing_gems = 0; local missing_enchants = 0; local pvp_items = 0;

	local link16 = GetInventoryItemLink("player", 16);
	local link17 = GetInventoryItemLink("player", 17);
	if link16 and link17 then  -- We're setting titan's grip's value if we're dual-wielding and the first hand is a 2h
		local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(link16);
		if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) then TitanGrip = 0.5; end
	end

	if link17 then
		local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(link17);
		if ( ItemEquipLoc == "INVTYPE_2HWEAPON" ) then TitanGrip = 0.5; end
		TempScore, temp_gems, temp_enchants, temp_pvp = Order65:GetItemScore(link17);
		if ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 0.3164; end
		GearScore = GearScore + TempScore * TitanGrip;	
		missing_gems = missing_gems + temp_gems; missing_enchants = missing_enchants + temp_enchants; pvp_items = pvp_items + pvp_items;
	end
		
	for i = 1, 18 do
		if ( i ~= 4 ) and ( i ~= 17 ) then
			ItemLink = GetInventoryItemLink("player", i);
			if ( ItemLink ) then
				local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink);
				TempScore, temp_gems, temp_enchants, temp_pvp = Order65:GetItemScore(ItemLink);
				if ( i == 16 ) and ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 0.3164; end
				if ( i == 18 ) and ( PlayerEnglishClass == "HUNTER" ) then TempScore = TempScore * 5.3224; end
				if ( i == 16 ) then TempScore = TempScore * TitanGrip; end
				GearScore = GearScore + TempScore;
				missing_gems = missing_gems + temp_gems; missing_enchants = missing_enchants + temp_enchants; pvp_items = pvp_items + temp_pvp;
			end
		end;
	end
	return {gs=floor(GearScore), missing_gems=missing_gems, missing_enchants=missing_enchants, pvp_items=pvp_items};
end

function Order65:GetItemScore(ItemLink)
	if not ( ItemLink ) then 
		return 0, 0; 
	end
	local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink); 
	local QualityScale = 1;
	local GearScore = 0;
	local Table = {};
	local Scale = 1.8618;
	local missing_enchants = 0;
	local missing_gems = 0
	local pvp_items = 0;

	if ItemRarity == 5 then  -- Legendary
		QualityScale = 1.3; 
		ItemRarity = 4;  -- Epic
	elseif ItemRarity == 1 then  -- Common
		QualityScale = 0.005;  
		ItemRarity = 2;  -- Uncommon
	elseif ItemRarity == 0 then  -- Poor
		QualityScale = 0.005;  
		ItemRarity = 2;  -- Uncommon
	elseif ItemRarity == 7 then 
		ItemRarity = 3;  -- Rare
		ItemLevel = 187.05;  -- Hardcode the heirlooms item level
	end
	if ( Order65.GS_ItemTypes[ItemEquipLoc] ) then
		if ( ItemLevel > 120 ) then Table = Order65.GS_Formula["A"]; else Table = Order65.GS_Formula["B"]; end
		if ( ItemRarity >= 2 ) and ( ItemRarity <= 4 ) then  -- Uncommon to Epic
			GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale);
			if ( ItemLevel == 187.05 ) then ItemLevel = 0; end
			local percent, temp_enchants = Order65:GetEnchantInfo(ItemLink, ItemEquipLoc);
			local temp_gems, temp_pvp = Order65:GetGemsAndPvP(ItemLink);
			GearScore = floor(GearScore * percent );
			missing_enchants = missing_enchants + temp_enchants;
			missing_gems = missing_gems + temp_gems;
			pvp_items = pvp_items + temp_pvp;
			return GearScore, missing_gems, missing_enchants, pvp_items;
		end
  	end
  	return -1, 0, 0, 0
end

-------------------------------------------------------------------------------

function Order65:GetEnchantInfo(ItemLink, ItemEquipLoc)
	local found, _, ItemSubString = string.find(ItemLink, "^|c%x+|H(.+)|h%[.*%]");
	local ItemSubStringTable = {};

	for v in string.gmatch(ItemSubString, "[^:]+") do 
		tinsert(ItemSubStringTable, v); 
	end
	ItemSubString = ItemSubStringTable[2]..":"..ItemSubStringTable[3], ItemSubStringTable[2]
	local StringStart, StringEnd = string.find(ItemSubString, ":") 
	ItemSubString = string.sub(ItemSubString, StringStart + 1)
	if ( ItemSubString == "0" ) and ( GS_ItemTypes[ItemEquipLoc]["Enchantable"] )then
		local percent = ( floor((-2 * ( GS_ItemTypes[ItemEquipLoc]["SlotMOD"] )) * 100) / 100 );
		return (1 + (percent/100)), 1;
	else
		return 1, 0;
	end
end

function Order65:GetGemsAndPvP(ItemLink)
    Order65.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    Order65.tooltip:SetHyperlink(ItemLink)
    local pvp = 0
    local missing = 0;
    for i=1, 4 do
        local texture = _G["Order65ScanTooltipTexture" .. i]
        if texture and texture:IsVisible() then
            missing = missing + 1;
            name = GetItemGem(ItemLink, i)
            if name ~= nil then
                missing = missing - 1;
            end
        end
    end
    for i=1, Order65.tooltip:NumLines() do
        if string.match(_G['Order65ScanTooltipTextLeft'..i]:GetText(), "resilience") then
            pvp = 1
        end
    end

    return missing, pvp
end

-------------------------------------------------------------------------------

Order65.GS_ItemTypes = {
        ["INVTYPE_RELIC"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
        ["INVTYPE_TRINKET"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false },
        ["INVTYPE_2HWEAPON"] = { ["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true },
        ["INVTYPE_WEAPONMAINHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true },
        ["INVTYPE_WEAPONOFFHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
        ["INVTYPE_RANGED"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true },
        ["INVTYPE_THROWN"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
        ["INVTYPE_RANGEDRIGHT"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
        ["INVTYPE_SHIELD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
        ["INVTYPE_WEAPON"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true },
        ["INVTYPE_HOLDABLE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false },
        ["INVTYPE_HEAD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true },
        ["INVTYPE_NECK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false },
        ["INVTYPE_SHOULDER"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true },
        ["INVTYPE_CHEST"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
        ["INVTYPE_ROBE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
        ["INVTYPE_WAIST"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false },
        ["INVTYPE_LEGS"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true },
        ["INVTYPE_FEET"] = { ["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true },
        ["INVTYPE_WRIST"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true },
        ["INVTYPE_HAND"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true },
        ["INVTYPE_FINGER"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false },
        ["INVTYPE_CLOAK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true },
        ["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
}

Order65.GS_Formula = {
        ["A"] = {
                [4] = { ["A"] = 91.4500, ["B"] = 0.6500 },
                [3] = { ["A"] = 81.3750, ["B"] = 0.8125 },
                [2] = { ["A"] = 73.0000, ["B"] = 1.0000 }
        },
        ["B"] = {
                [4] = { ["A"] = 26.0000, ["B"] = 1.2000 },
                [3] = { ["A"] = 0.7500, ["B"] = 1.8000 },
                [2] = { ["A"] = 8.0000, ["B"] = 2.0000 },
                [1] = { ["A"] = 0.0000, ["B"] = 2.2500 }
        }
}
