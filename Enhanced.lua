-- locals
local AddonName, Addon = ...;
local _G = _G;
local pairs = pairs;

local InCombat = false;

function Addon:Load()
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
  elseif (class == 'DEATHKNIGHT') then
    RuneFrame:ClearAllPoints();
    RuneFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, -150);
    RuneFrame.SetPoint = function() end;
    RuneFrame:SetScale('1.2');
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

  --self:Nameplates();

  self:Textures();

  self:CastBars();

  self:UnitFrames();

  self:Test();

end

function Addon:Test()
  -- helper functions
  local function IsTanking(unit)
    local isTanking = UnitDetailedThreatSituation('player', unit);
    return isTanking;
  end

  local function HealthPercent(frame)
    if (not frame.healthBar.value) then
      frame.healthBar.value = frame.healthBar:CreateFontString(nil, 'ARTWORK');
      frame.healthBar.value:SetPoint('LEFT', frame.healthBar.value:GetParent(), 'RIGHT', 7, 0);
      frame.healthBar.value:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
    else
      local _, maxHealth = frame.healthBar:GetMinMaxValues();
      local value = frame.healthBar:GetValue();
      frame.healthBar.value:SetText(string.format(math.floor((value / maxHealth) * 100)) .. ' %');
    end
  end

  hooksecurefunc('CompactUnitFrame_UpdateHealthColor', function (self)
    if (UnitExists(self.unit) and IsTanking(self.displayedUnit)) then
      local r, g, b = 1.0, 0.0, 1.0;

      if (r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b) then
        self.healthBar:SetStatusBarColor(r, g, b);
        self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b;
      end
    end
  end);

  hooksecurefunc('CompactUnitFrame_SetUpFrame', function (self, func)
    HealthPercent(self);

    self.healthBar.background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
    self.healthBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
    self.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");

  	if (self.castBar) then
      self.castBar.background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
      self.castBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
      self.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    end
  end);

  hooksecurefunc('CompactUnitFrame_UpdateHealth', function (self)
    HealthPercent(self);
  end);

  hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', function (self)
    if (self.optionTable.defaultBorderColor) then
      self.healthBar.border:SetVertexColor(0.0, 0.0, 0.0, 1.0);
    	if (self.castBar and self.castBar.border) then
    		self.castBar.border:SetVertexColor(0.0, 0.0, 0.0, 1.0);
    	end
  	end
  end)
end

function Addon:Buffs()
  local _, class = UnitClass('player');
  if (class == 'SHAMAN') then
    SpellActivationOverlayFrame:SetAlpha(1.0);
    SpellActivationOverlayFrame.SetAlpha = function() end;

    self:TrackTidalWaves();
    self:TrackUnleashedFury();
  end
end

function Addon:TrackTidalWaves()
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

function Addon:TrackUnleashedFury()
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

function Addon:Textures()
  local frame = CreateFrame('Frame');
  frame:RegisterEvent('ADDON_LOADED');

  -- darken the user interface textures
  frame:SetScript('OnEvent', function(self, event, addon)
    if (addon == 'Blizzard_TimeManager') then
      for i, v in pairs({
        -- UNIT FRAMES
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
        Boss1TargetFrameTextureFrameTexture,
      	Boss2TargetFrameTextureFrameTexture,
      	Boss3TargetFrameTextureFrameTexture,
      	Boss4TargetFrameTextureFrameTexture,
      	Boss5TargetFrameTextureFrameTexture,
      	Boss1TargetFrameSpellBarBorder,
      	Boss2TargetFrameSpellBarBorder,
      	Boss3TargetFrameSpellBarBorder,
      	Boss4TargetFrameSpellBarBorder,
      	Boss5TargetFrameSpellBarBorder,
        CastingBarFrameBorder,
        FocusFrameSpellBarBorder,
        TargetFrameSpellBarBorder,
        RuneButtonIndividual1BorderTexture,
        RuneButtonIndividual2BorderTexture,
        RuneButtonIndividual3BorderTexture,
        RuneButtonIndividual4BorderTexture,
        RuneButtonIndividual5BorderTexture,
        RuneButtonIndividual6BorderTexture,
        PaladinPowerBarBG,
        PaladinPowerBarBankBG,
        --MAIN MENU
        SlidingActionBarTexture0,
        SlidingActionBarTexture1,
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
        MainMenuXPBarTextureLeftCap,
      	MainMenuXPBarTextureRightCap,
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
        ReputationWatchBarTexture0,
      	ReputationWatchBarTexture1,
      	ReputationWatchBarTexture2,
      	ReputationWatchBarTexture3,
      	ReputationXPBarTexture0,
      	ReputationXPBarTexture1,
      	ReputationXPBarTexture2,
      	ReputationXPBarTexture3,
        ReputationWatchBar.StatusBar.WatchBarTexture0,
        ReputationWatchBar.StatusBar.WatchBarTexture1,
        ReputationWatchBar.StatusBar.WatchBarTexture2,
        ReputationWatchBar.StatusBar.WatchBarTexture3,
        StanceBarLeft,
      	StanceBarMiddle,
      	StanceBarRight,
        --ARENA FRAMES
      	ArenaEnemyFrame1Texture,
      	ArenaEnemyFrame2Texture,
      	ArenaEnemyFrame3Texture,
      	ArenaEnemyFrame4Texture,
      	ArenaEnemyFrame5Texture,
      	ArenaEnemyFrame1SpecBorder,
      	ArenaEnemyFrame2SpecBorder,
      	ArenaEnemyFrame3SpecBorder,
      	ArenaEnemyFrame4SpecBorder,
      	ArenaEnemyFrame5SpecBorder,
      	ArenaEnemyFrame1PetFrameTexture,
      	ArenaEnemyFrame2PetFrameTexture,
      	ArenaEnemyFrame3PetFrameTexture,
      	ArenaEnemyFrame4PetFrameTexture,
      	ArenaEnemyFrame5PetFrameTexture,
      	ArenaPrepFrame1Texture,
      	ArenaPrepFrame2Texture,
      	ArenaPrepFrame3Texture,
      	ArenaPrepFrame4Texture,
      	ArenaPrepFrame5Texture,
      	ArenaPrepFrame1SpecBorder,
      	ArenaPrepFrame2SpecBorder,
      	ArenaPrepFrame3SpecBorder,
      	ArenaPrepFrame4SpecBorder,
      	ArenaPrepFrame5SpecBorder,
        -- PANES
      	CharacterFrameTitleBg,
      	CharacterFrameBg,
      	ObjectiveTrackerBlocksFrame.QuestHeader.Background,
      	-- MINIMAP
      	MinimapBorder,
      	MinimapBorderTop,
      	MiniMapTrackingButtonBorder,
        MiniMapLFGFrameBorder,
        MiniMapBattlefieldBorder,
        MiniMapMailBorder,
        select(1, MinimapZoomIn:GetRegions()),
        select(3, MinimapZoomIn:GetRegions()),
        select(1, MinimapZoomOut:GetRegions()),
        select(3, MinimapZoomOut:GetRegions()),
        QueueStatusMinimapButtonBorder,
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
function Addon:CastBars()
  -- enable cast bar frame timer
  hooksecurefunc('CastingBarFrame_OnUpdate', function (self, elapsed)
    if (not self.timer) then
      self.timer = self:CreateFontString(nil);
      self.timer:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
      self.timer:SetPoint('TOP', self, 'BOTTOM', 0, -3);
      self.update = 0.1;
    else
      if (self.update and self.update < elapsed) then
        if (self.casting) then
          self.timer:SetText(format('%2.1f/%1.1f', max(self.maxValue - self.value, 0), self.maxValue));
        elseif (self.channeling) then
          self.timer:SetText(format('%.1f', max(self.value, 0)));
        else
          self.timer:SetText(nil);
        end

        self.update = 0.1;
      else
        self.update = self.update - elapsed;
      end
    end
  end);
end

function Addon:UnitFrames()
  -- class icons
  hooksecurefunc('UnitFramePortrait_Update', function (self)
    if (self.portrait) then
      if (UnitIsPlayer(self.unit)) then
        local t = CLASS_ICON_TCOORDS[select(2, UnitClass(self.unit))];

        if (t) then
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
    if (UnitIsPlayer('target')) then
      local c = RAID_CLASS_COLORS[select(2, UnitClass('target'))];
      TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b);
    end
    if (UnitIsPlayer('focus')) then
      local c = RAID_CLASS_COLORS[select(2, UnitClass('focus'))];
      FocusFrameNameBackground:SetVertexColor(c.r, c.g, c.b);
    end
  end

  frame:SetScript('OnEvent', handler);

  for i, v in pairs({
    TargetFrameNameBackground,
    FocusFrameNameBackground
  }) do
    v:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  end
end

-- load addon
Addon:Load();
