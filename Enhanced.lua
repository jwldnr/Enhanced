local ns, addon = ...;

local _G = _G;

local InCombat = false;

--function events:PLAYER_REGEN_ENABLED() InCombat = false; end;
--function events:PLAYER_REGEN_DISABLED() InCombat = true; end;

-- helper functions
local function DumpNameplateInfo(plate)
  local ListChildren

  local function ListRegions(object, indent)
    local count = object:GetNumRegions()

    if count > 0 then print(indent, 'Regions of ', object:GetName()) end

    for i = 1, count do
      local region = select(i,object:GetRegions())

      local name = region:GetName()
      local otype = region:GetObjectType()
      local extra = ''

      if otype == 'FontString' then extra = region:GetText()
      elseif otype == 'Texture' then extra = region:GetTexture()
      end

      print(indent, i, otype, name, extra)

    end
  end


  ListChildren = function(object, indent)

    local count = select('#',object:GetChildren())

    if count > 0 then print(indent, 'Children of ', object:GetName()) end

    for i = 1, count do
      local child = select(i,object:GetChildren())
      local name = child:GetName()
      local otype = child:GetObjectType()
      local extra
      local sublevels = child:GetNumChildren()
      local subregions = child:GetNumRegions()

      if otype == 'StatusBar' then extra = child:GetStatusBarTexture()
      end

      print(indent, i, otype, name, extra, sublevels, subregions)
      ListRegions(child, indent..'  ')

      ListChildren(child, indent..'    ')
    end
  end

  ListChildren(plate, '')

end

-- GetUnitCombatStatus: Determines if a unit is in combat by checking the name text color
local function GetUnitCombatStatus(r, g, b) return (r > .5 and g < .5) end

-- GetUnitAggroStatus: Determines if a unit is attacking, by looking at aggro glow region
local function GetUnitAggroStatus(threatRegion)
  if (not threatRegion:IsShown()) then return 'LOW', 0 end;

  local red, green, blue, alpha = threatRegion:GetVertexColor();
  local opacity = threatRegion:GetVertexColor();

  if threatRegion:IsShown() and (alpha < .9 or opacity < .9) then
  --if threatRegion:IsShown() and alpha > .9 then
    --print(unit.name, alpha, opacity)

    -- Unfinished
  end


  if red > 0 then
    if green > 0 then
      if blue > 0 then return 'MEDIUM', 1 end;
      return 'MEDIUM', 2;
    end
    return 'HIGH', 3;
  end
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
        local barFrame, nameFrame = frame:GetChildren();
        local threat, border, highlight, level, boss, raid, dragon = barFrame:GetRegions();

        local threatSituation, threatValue;

        if (InCombat) then
          threatSituation, threatValue = GetUnitAggroStatus(threat);
        else
          threatSituation = 'LOW';
          threatValue = 0 ;
        end

        frame.health = select(1, select(1, frame:GetChildren()):GetChildren());

        if (frame.health) then
          local red, green, blue = frame.health:GetStatusBarColor();

          if (threatSituation == 'HIGH') then
            frame.health:SetStatusBarColor(1, 0.5, 1);
          else
            frame.health:SetStatusBarColor(red, green, blue);
          end

          if (not frame.health.value) then
            frame.health.value = frame.health:CreateFontString(nil, 'ARTWORK');
            frame.health.value:SetPoint('CENTER', frame.health.value:GetParent(), 'CENTER', 10, 35);
            frame.health.value:SetFont(STANDARD_TEXT_FONT, 20, 'OUTLINE');
            --f.h.v:SetVertexColor(0, 1, 0, 1);
          else
            local _, maxHealth = frame.health:GetMinMaxValues();
            local value = frame.health:GetValue();
            frame.health.value:SetText(string.format(math.floor((value / maxHealth) * 100)) .. ' %');
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
        MainMenuBarTexture0,
        MainMenuBarTexture1,
        MainMenuBarTexture2,
        MainMenuBarTexture3,
        MainMenuMaxLevelBar0,
        MainMenuMaxLevelBar1,
        MainMenuMaxLevelBar2,
        MainMenuMaxLevelBar3,
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

function addon:CastBars()
  -- enable cast bar frame timer
  hooksecurefunc('CastingBarFrame_OnUpdate', function (self, elapsed)
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
