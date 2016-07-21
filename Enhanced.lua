local ns, addon = ...;

local _G = _G;

local InCombat = false;

-- helper functions
local function IsTanking(unit)
  local isTanking = UnitDetailedThreatSituation('player', unit);
  return isTanking;
end

local function IsOnThreatList(threatStatus)
  return threatStatus ~= nil;
end

local function IsOnThreatListWithPlayer(unit)
  local _, threatStatus = UnitDetailedThreatSituation('player', unit);
  return IsOnThreatList(threatStatus);
end

function addon:Load()
  -- once
  LoadAddOn('Blizzard_CombatText');

  COMBAT_TEXT_TYPE_INFO['PERIODIC_HEAL'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['HEAL_CRIT'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['HEAL'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['PERIODIC_HEAL_ABSORB'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['HEAL_CRIT_ABSORB'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['HEAL_ABSORB'] = { var = nil, show = nil };

  COMBAT_TEXT_TYPE_INFO['DAMAGE_CRIT'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['DAMAGE'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['SPELL_DAMAGE_CRIT'] = { var = nil, show = nil };
  COMBAT_TEXT_TYPE_INFO['SPELL_DAMAGE'] = { var = nil, show = nil };

  local _, class = UnitClass('player');
  if (class == 'SHAMAN') then
    TotemFrame:ClearAllPoints();
    TotemFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -140);
    TotemFrame.SetPoint = function() end;
    TotemFrame:SetScale('1.2');
  end

  PlayerName:SetVertexColor(1, 1, 1);
  PlayerName.SetVertexColor = function() end;

  PlayerLevelText:SetVertexColor(1, 1, 1);
  PlayerLevelText.SetVertexColor = function() end;

  TargetFrameToTTextureFrameName:SetVertexColor(1, 1, 1);
  TargetFrameToTTextureFrameName.SetVertexColor = function() end;

  for i=1, 4, 1 do
    -- party member name
    local partyMemberName = 'PartyMemberFrame'..i..'Name';
    local playerName = _G[partyMemberName];

    playerName:SetVertexColor(1, 1, 1);
    playerName.SetVertexColor = function() end;

    -- party member pet name
    local petFrameName = 'PartyMemberFrame'..i..'PetFrameName';
    local petName = _G[petFrameName];

    petName:Hide();
    petName.Show = function() end;
  end

  TargetFrameTextureFrameName:SetVertexColor(1, 1, 1);
  TargetFrameTextureFrameName.SetVertexColor = function() end;

  CompactRaidFrameContainerBorderFrameBorderTopLeft:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderTop:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderTopRight:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderRight:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderBottomRight:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderBottom:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderBottomLeft:SetVertexColor(0,0,0);
  CompactRaidFrameContainerBorderFrameBorderLeft:SetVertexColor(0,0,0);

  -- adjust the player cast bar position and scale
  CastingBarFrame:ClearAllPoints();
  CastingBarFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -235);
  CastingBarFrame.SetPoint = function() end;
  CastingBarFrame:SetScale(1.1);

  -- timer text for player cast bar
  CastingBarFrame.timer = CastingBarFrame:CreateFontString(nil);
  CastingBarFrame.timer:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
  CastingBarFrame.timer:SetPoint('TOP', CastingBarFrame, 'BOTTOM', 0, -10);
  CastingBarFrame.update = .1;

  -- timer text for target cast bar
  TargetFrameSpellBar.timer = TargetFrameSpellBar:CreateFontString(nil);
  TargetFrameSpellBar.timer:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
  TargetFrameSpellBar.timer:SetPoint('TOP', TargetFrameSpellBar, 'BOTTOM', 0, -10);
  TargetFrameSpellBar.update = .1;

  -- timer text for spell activation overlay
  SpellActivationOverlayFrame.timer = SpellActivationOverlayFrame:CreateFontString(nil);
  SpellActivationOverlayFrame.timer:SetFont(STANDARD_TEXT_FONT, 22, 'OUTLINE');
  SpellActivationOverlayFrame.timer:SetPoint('TOP', SpellActivationOverlayFrame, 'BOTTOM', 0, -10);
  SpellActivationOverlayFrame.update = .1;

  -- disable damage on player frame
  PlayerHitIndicator:SetText(nil);
  PlayerHitIndicator.SetText = function() end;

  -- disable damage on player pet frame
  PetHitIndicator:SetText(nil);
  PetHitIndicator.SetText = function() end;

  TargetFrameSpellBar:SetScale(1.2);

  self:Buffs();

  self:Nameplates();

  self:Textures();

  self:CastBars();

  self:UnitFrames();

end

function addon:Buffs()
  local _, class = UnitClass('player');
  if (class == 'SHAMAN') then
    SpellActivationOverlayFrame:SetAlpha(1.0);
    SpellActivationOverlayFrame.SetAlpha = function() end;

    addon:TrackTidalWaves();
    addon:TrackUnleashedFury();
  end
end

function addon:TrackTidalWaves()
  local frame = CreateFrame('FRAME');
  local buffName = 'Tidal Waves';

  frame.timer = SpellActivationOverlayFrame:CreateFontString(nil);
  frame.timer:SetFont(STANDARD_TEXT_FONT, 22, 'OUTLINE');
  frame.timer:SetPoint('LEFT', SpellActivationOverlayFrame, 'LEFT', 0, 0);
  frame.update = 1.0;

  frame:RegisterEvent('UNIT_AURA');

  local function handler(self, elapsed)
    if (not self.timer) then return end;

    if (self.update and self.update < elapsed) then
      local name, _, _, count, _, _, expirationTime, _, _, _ = UnitBuff('player', buffName);

      self.timer:SetText(string.format('%.0f s', math.floor(expirationTime - GetTime())));

      self.update = 1.0;
    else
      self.update = self.update - elapsed;
    end

  end

  frame:SetScript('OnEvent', function(self, event, ...)
    local unit = ...;

    if (unit ~= 'player') then return end;

    if (event == 'UNIT_AURA') then
      local name, _, _, count, _, _, expirationTime, _, _, _ = UnitBuff('player', buffName);
      if (name) then
        -- set timer text to buff duration
        self.timer:SetText(string.format('%.0f s', math.floor(expirationTime - GetTime())));
        -- set update script
        self:SetScript('OnUpdate', handler);
        -- show buff
        SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, 51564, 'TEXTURES\\SPELLACTIVATIONOVERLAYS\\genericarc_04.BLP', 'LEFT', 1.0, 125, 155, 255, false, false);
      else
        -- reset timer text
        self.timer:SetText(nil);
        -- remove update script
        self:SetScript('OnUpdate', nil);
        SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, 51564);
      end
    end
  end);
end

function addon:TrackUnleashedFury()
  local frame = CreateFrame('FRAME');
  local buffName = 'Unleashed Fury';

  frame.timer = SpellActivationOverlayFrame:CreateFontString(nil);
  frame.timer:SetFont(STANDARD_TEXT_FONT, 22, 'OUTLINE');
  frame.timer:SetPoint('CENTER', SpellActivationOverlayFrame, 'TOP', 0, 0);
  frame.update = 1.0;

  frame:RegisterEvent('UNIT_AURA');

  local function handler(self, elapsed)
    if (not self.timer) then return end;

    if (self.update and self.update < elapsed) then
      local name, _, _, count, _, _, expirationTime, _, _, _ = UnitBuff('player', buffName);

      self.timer:SetText(string.format('%.0f s', math.floor(expirationTime - GetTime())));

      self.update = 1.0;
    else
      self.update = self.update - elapsed;
    end

  end

  frame:SetScript('OnEvent', function(self, event, ...)
    local unit = ...;

    if (unit ~= 'player') then return end;

    if (event == 'UNIT_AURA') then
      local name, _, _, count, _, _, expirationTime, _, _, _ = UnitBuff('player', buffName);
      if (name) then
        -- set timer text to buff duration
        self.timer:SetText(string.format('%.0f s', math.floor(expirationTime - GetTime())));
        -- set update script
        self:SetScript('OnUpdate', handler);
        -- show buff
        SpellActivationOverlay_ShowOverlay(SpellActivationOverlayFrame, 165479, 'TEXTURES\\SPELLACTIVATIONOVERLAYS\\generictop_01.BLP', 'TOP', 1.0, 125, 255, 125, false, false);
      else
        -- reset timer text
        self.timer:SetText(nil);
        -- remove update script
        self:SetScript('OnUpdate', nil);
        SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, 165479);
      end
    end
  end);
end

function addon:Nameplates()
  local frame = CreateFrame('Frame');

  -- in and out of combat detection
  frame:RegisterEvent('PLAYER_REGEN_DISABLED');
  frame:RegisterEvent('PLAYER_REGEN_ENABLED');

  frame:SetScript('OnEvent', function (self, event, ...)
    if (event == 'PLAYER_REGEN_DISABLED') then
      InCombat = true;
    elseif (event == 'PLAYER_REGEN_ENABLED') then
      InCombat = false;
    end
  end);

  -- nameplate percentage
  frame:SetScript('OnUpdate', function (self, elapsed)
    for index = 1, select('#', WorldFrame:GetChildren()) do
      local frame = select(index, WorldFrame:GetChildren());

      if (frame:GetName() and frame:GetName():find('NamePlate%d')) then
        local barFrame = frame:GetChildren();

        if (barFrame) then
          local health = select(1, select(1, barFrame):GetChildren());

          if (health) then
            -- color health bar
            if (UnitExists(barFrame.displayedUnit)) then
              local r, g, b;

              local _, class = UnitClass(barFrame.unit);
        			local color = RAID_CLASS_COLORS[class];

              if (UnitIsPlayer(barFrame.unit) and color and barFrame.optionTable.useClassColors) then
                r, g, b = color.r, color.g, color.b;
              elseif (barFrame.optionTable.colorHealthBySelection) then
                if (barFrame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatListWithPlayer(barFrame.displayedUnit)) then
                  if (IsTanking(barFrame.displayedUnit)) then
                    r, g, b = 1.0, 0.0, 1.0;
                  else
                    r, g, b = 1.0, 0.0, 0.0;
                  end
                else
                  r, g, b = UnitSelectionColor(barFrame.unit, barFrame.optionTable.colorHealthWithExtendedColors);
                end

                if (r ~= health.r or g ~= health.g or b ~= health.b) then
                  health:SetStatusBarColor(r, g, b);

                  health.r, health.g, health.b = r, g, b;
                end
              elseif (UnitIsFriend('player', barFrame.unit)) then
                r, g, b = 0.0, 1.0, 0.0;
              else
                r, g, b = 1.0, 0.0, 0.0;
              end
            end

            -- set health percentage value
            if (not health.value) then
              health.value = health:CreateFontString(nil, 'ARTWORK');
              health.value:SetPoint('CENTER', health.value:GetParent(), 'CENTER', 0, 35);
              health.value:SetFont(STANDARD_TEXT_FONT, 20, 'OUTLINE');
            else
              local _, maxHealth = health:GetMinMaxValues();
              local value = health:GetValue();
              health.value:SetText(string.format(math.floor((value / maxHealth) * 100)) .. ' %');
            end
          end
        end
      end
    end
  end);
end

function addon:Textures()
  local frame = CreateFrame('Frame');
  frame:RegisterEvent('ADDON_LOADED');

  -- darken the user interface textures
  frame:SetScript('OnEvent', function(self, event, addon)
    if (addon == 'Blizzard_TimeManager') then
      for i, v in pairs({
        PlayerFrameTexture,
        TargetFrameTextureFrameTexture,
        PetFrameTexture,
        PartyMemberFrame1Texture,
        PartyMemberFrame2Texture,
        PartyMemberFrame3Texture,
        PartyMemberFrame4Texture,
        PartyMemberFrame1PetFrameTexture,
        PartyMemberFrame2PetFrameTexture,
        PartyMemberFrame3PetFrameTexture,
        PartyMemberFrame4PetFrameTexture,
        FocusFrameTextureFrameTexture,
        TargetFrameToTTextureFrameTexture,
        FocusFrameToTTextureFrameTexture,
        BonusActionBarFrameTexture0,
        BonusActionBarFrameTexture1,
        BonusActionBarFrameTexture2,
        BonusActionBarFrameTexture3,
        BonusActionBarFrameTexture4,
        MainMenuBarLeftEndCap,
        MainMenuBarRightEndCap,
        MainMenuBarTexture0,
        MainMenuBarTexture1,
        MainMenuBarTexture2,
        MainMenuBarTexture3,
        MainMenuMaxLevelBar0,
        MainMenuMaxLevelBar1,
        MainMenuMaxLevelBar2,
        MainMenuMaxLevelBar3,
        MainMenuXPBarTextureMid,
        MainMenuXPBarDiv1,
        MainMenuXPBarDiv2,
        MainMenuXPBarDiv3,
        MainMenuXPBarDiv4,
        MainMenuXPBarDiv5,
        MainMenuXPBarDiv6,
        MainMenuXPBarDiv7,
        MainMenuXPBarDiv8,
        MainMenuXPBarDiv9,
        MainMenuXPBarDiv10,
        MainMenuXPBarDiv11,
        MainMenuXPBarDiv12,
        MainMenuXPBarDiv13,
        MainMenuXPBarDiv14,
        MainMenuXPBarDiv15,
        MainMenuXPBarDiv16,
        MainMenuXPBarDiv17,
        MainMenuXPBarDiv18,
        MainMenuXPBarDiv19,
        MinimapBorder,
        CastingBarFrameBorder,
        FocusFrameSpellBarBorder,
        TargetFrameSpellBarBorder,
        MiniMapTrackingButtonBorder,
        MiniMapLFGFrameBorder,
        MiniMapBattlefieldBorder,
        MiniMapMailBorder,
        MinimapBorderTop,
        select(1, TimeManagerClockButton:GetRegions())
      }) do
        v:SetVertexColor(0.33, 0.33, 0.33);
      end

      for i, v in pairs({
        select(2, TimeManagerClockButton:GetRegions())
      }) do
        v:SetVertexColor(1.0, 1.0, 1.0);
      end

      -- unload
      self:UnregisterEvent('ADDON_LOADED');
      frame:SetScript('OnEvent', nil);
    end
  end);
end

-- NOTE do not work
function addon:CastBars()
  -- enable cast bar frame timer
  hooksecurefunc('CastingBarFrame_OnUpdate', function (self, elapsed)
    --print('ev');
    if (not self.timer) then return end;

    if (self.update and self.update < elapsed) then
      if (self.casting) then
        self.timer:SetText(format('%2.1f/%1.1f', max(self.maxValue - self.value, 0), self.maxValue));
      elseif (self.channeling) then
        self.timer:SetText(format('%.1f', max(self.value, 0)));
      else
        self.timer:SetText(nil);
      end

      self.update = .1;
    else
      self.update = self.update - elapsed;
    end
  end);
end

function addon:UnitFrames()
  -- class icons
  hooksecurefunc('UnitFramePortrait_Update',function (self)
    if self.portrait then
      if UnitIsPlayer(self.unit) then
        local t = CLASS_ICON_TCOORDS[select(2, UnitClass(self.unit))];

        if t then
          self.portrait:SetTexture('Interface\\TargetingFrame\\UI-Classes-Circles');
          self.portrait:SetTexCoord(unpack(t));
        end
      else
        self.portrait:SetTexCoord(0.0, 1.0, 0.0, 1.0);
      end
    end
  end);

  -- set the level text color
  hooksecurefunc('TargetFrame_CheckLevel', function (self)
    local targetLevel = UnitLevel(self.unit);

    if (UnitCanAttack('player', self.unit)) then
      local color = GetQuestDifficultyColor(targetLevel);

      if (color.r == 1 and color.g == 0.82 and color.b == 0) then
        self.levelText:SetVertexColor(1.0, 1.0, 1.0);
      end
    else
      self.levelText:SetVertexColor(1.0, 1.0, 1.0);
    end
  end);

  local frame = CreateFrame('Frame');

  frame:RegisterEvent('GROUP_ROSTER_UPDATE');
  frame:RegisterEvent('PLAYER_TARGET_CHANGED');
  frame:RegisterEvent('PLAYER_FOCUS_CHANGED');
  frame:RegisterEvent('UNIT_FACTION');

  local function handler(self, event, ...)
    if UnitIsPlayer('target') then
      local c = RAID_CLASS_COLORS[select(2, UnitClass('target'))];
      TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b);
    end
    if UnitIsPlayer('focus') then
      local c = RAID_CLASS_COLORS[select(2, UnitClass('focus'))];
      FocusFrameNameBackground:SetVertexColor(c.r, c.g, c.b);
    end
  end

  frame:SetScript('OnEvent', handler);

  for _, BarTextures in pairs({
    TargetFrameNameBackground,
    FocusFrameNameBackground
  }) do
    BarTextures:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  end
end

-- load addon
addon:Load();
