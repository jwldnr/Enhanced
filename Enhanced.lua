-- locals
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;
local unpack = unpack;
local format = string.format;
local max = math.max;
local floor = math.floor;
local print = print;

-- helper functions
local function UpdateNamePlateHealthValue(frame)
  if (not frame.healthBar.value) then
    frame.healthBar.value = frame.healthBar:CreateFontString(nil, 'ARTWORK');
    frame.healthBar.value:SetFontObject('GameFontHighlight');
    -- frame.healthBar.value:SetShadowOffset(1, 1);
    frame.healthBar.value:SetPoint('LEFT', frame.healthBar.value:GetParent(), 'RIGHT', 7, 0);
  else
    local _, maxHealth = frame.healthBar:GetMinMaxValues();
    local value = frame.healthBar:GetValue();
    frame.healthBar.value:SetText(format(floor((value / maxHealth) * 100)) .. ' %');
  end
end

local function IsTanking(unit)
  return select(1, UnitDetailedThreatSituation('player', unit));
end

function Addon:Load()
  do
    local eventHandler = CreateFrame('Frame', nil);
    eventHandler:SetScript('OnEvent', function(handler, ...)
        self:OnEvent(...);
      end)

    eventHandler:RegisterEvent('ADDON_LOADED');
    eventHandler:RegisterEvent('PLAYER_LOGIN');
  end
end

function Addon:SetupNamePlate(frame, setupOptions, frameOptions)
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border just like the one from nameplate health bar
  frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');
  frame.castBar.border:SetVertexColor(0.0, 0.0, 0.0, 1.0);

  frame.castBar.BorderShield:SetSize(20, 24);

  -- frame.castBar.Icon:SetSize(50, 50);
  -- TODO set frame.castBar.Icon size

  UpdateNamePlateHealthValue(frame);

  if (frame.optionTable.showClassificationIndicator) then
    frame.optionTable.showClassificationIndicator = nil;
  end

  -- if (NamePlatePlayerResourceFrame) then
  -- local _, class = UnitClass('player');
  -- local namePlatePlayer = C_NamePlate.GetNamePlateForUnit('player');
  --
  -- if (namePlatePlayer) then
  -- if (class == 'DEATHKNIGHT') then
  -- DeathKnightResourceOverlayFrame:Hide();
  -- DeathKnightResourceOverlayFrame.Show = function () end
  --
  -- RuneFrame:SetParent(namePlatePlayer.UnitFrame);
  -- RuneFrame:ClearAllPoints();
  -- RuneFrame:SetPoint('CENTER', namePlatePlayer.UnitFrame.healthBar, 'CENTER', 3, -36);
  -- end
  -- end
  --
  -- if (class == 'DEATHKNIGHT') then
  -- RuneFrame:SetShown(namePlatePlayer ~= nil);
  -- end
  -- end
end

function Addon:UpdateNamePlateHealth(frame)
  UpdateNamePlateHealthValue(frame);
end

function Addon:UpdateNamePlateHealthColor(frame)
  if (UnitExists(frame.unit) and frame.isTanking or IsTanking(frame.displayedUnit)) then
    -- desired tank nameplate health bar color
    local r, g, b = 1.0, 0.0, 1.0;

    if (r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b) then
      frame.healthBar:SetStatusBarColor(r, g, b);
      frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
    end
  end
end

function Addon:UpdateNamePlateHealthBorder(frame)
  if (frame.optionTable.defaultBorderColor) then
    frame.healthBar.border:SetVertexColor(0.0, 0.0, 0.0, 1.0);
    frame.castBar.border:SetVertexColor(0.0, 0.0, 0.0, 1.0);
  end
end

function Addon:UpdateNamePlateCastingBarTimer(frame, elapsed)
  if (not frame.timer) then
    frame.timer = frame:CreateFontString(nil);
    frame.timer:SetFontObject('GameFontHighlight');
    -- frame.timer:SetShadowOffset(1, 1);
    frame.timer:SetPoint('TOP', frame.timer:GetParent(), 'BOTTOM', 0, -5);
    frame.update = 0.1;
  else
    if (frame.update and frame.update < elapsed) then
      if (frame.casting) then
        frame.timer:SetText(format('%2.1f/%1.1f', max(frame.maxValue - frame.value, 0), frame.maxValue));
      elseif (frame.channeling) then
        frame.timer:SetText(format('%.1f', max(frame.value, 0)));
      else
        frame.timer:SetText(nil);
      end

      frame.update = 0.1;
    else
      frame.update = frame.update - elapsed;
    end
  end

  local r, g, b = frame:GetStatusBarColor();
  if (r > 0.7 and g > 0.7 and b > 0.7) then
    frame:SetStatusBarColor(1.0, 0.2, 0.1, 1.0);
  end
end

function Addon:UpdateUnitPortrait(frame)
  if (frame.portrait) then
    if (UnitIsPlayer(frame.unit)) then
      local tcoords = CLASS_ICON_TCOORDS[select(2, UnitClass(frame.unit))];

      if (tcoords) then
        frame.portrait:SetTexture('Interface\\TargetingFrame\\UI-Classes-Circles');
        frame.portrait:SetTexCoord(unpack(tcoords));
      end
    else
      frame.portrait:SetTexCoord(0.0, 1.0, 0.0, 1.0);
    end
  end
end

function Addon:CheckTargetLevel(frame)
  local targetLevel = UnitLevel(frame.unit);

  if (UnitCanAttack('player', frame.unit)) then
    local color = GetQuestDifficultyColor(targetLevel);

    if (color.r == 1.0 and color.g > 0.7 and color.b == 0.0) then
      frame.levelText:SetVertexColor(1.0, 1.0, 1.0);
    end
  else
    frame.levelText:SetVertexColor(1.0, 1.0, 1.0);
  end
end

function Addon:CheckTargetFaction(frame)
  if (UnitIsPlayer(frame.unit)) then
    local color = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))];
    frame.nameBackground:SetVertexColor(color.r, color.g, color.b);
  end
end

function Addon:HookActionEvents()
  local function Frame_SetupNamePlate(frame, setupOptions, frameOptions)
    Addon:SetupNamePlate(frame, setupOptions, frameOptions);
  end

  local function Frame_UpdateNamePlateHealth(frame)
    Addon:UpdateNamePlateHealth(frame);
  end

  local function Frame_UpdateNamePlateHealthColor(frame)
    Addon:UpdateNamePlateHealthColor(frame);
  end

  local function Frame_UpdateNamePlateHealthBorder(frame)
    Addon:UpdateNamePlateHealthBorder(frame);
  end

  local function CastingBarFrame_Update(frame, elapsed)
    Addon:UpdateNamePlateCastingBarTimer(frame, elapsed);
  end

  local function Frame_UpdateUnitPortrait(frame)
    Addon:UpdateUnitPortrait(frame);
  end

  local function Frame_CheckTargetLevel(frame)
    Addon:CheckTargetLevel(frame);
  end

  local function Frame_CheckTargetFaction(frame)
    Addon:CheckTargetFaction(frame);
  end

  hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlate);
  hooksecurefunc('CompactUnitFrame_UpdateHealth', Frame_UpdateNamePlateHealth);
  hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateNamePlateHealthColor);
  hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', Frame_UpdateNamePlateHealthBorder);
  hooksecurefunc('CastingBarFrame_OnUpdate', CastingBarFrame_Update);

  hooksecurefunc('UnitFramePortrait_Update', Frame_UpdateUnitPortrait);
  hooksecurefunc('TargetFrame_CheckLevel', Frame_CheckTargetLevel);
  hooksecurefunc('TargetFrame_CheckFaction', Frame_CheckTargetFaction);

  CastingBarFrame:HookScript('OnUpdate', CastingBarFrame_Update);
  TargetFrameSpellBar:HookScript('OnUpdate', CastingBarFrame_Update);
end

-- frame events
function Addon:OnEvent(event, ...)
  local action = self[event];

  if (action) then
    action(self, event, ...);
  end
end

function Addon:ADDON_LOADED(self, event, ...)
  local addonName = ...;

  if (addonName and addonName == 'Blizzard_CombatText') then
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
  end
end

function Addon:PLAYER_LOGIN()
  self:HookActionEvents();

  for i, v in pairs({
      -- unit frames
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
      -- main menu
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
      -- arena frames
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
      -- panes
      CharacterFrameTitleBg,
      CharacterFrameBg,
      ObjectiveTrackerBlocksFrame.QuestHeader.Background,
      -- minimap
      MinimapBorder,
      MinimapBorderTop,
      MiniMapTrackingButtonBorder,
      MiniMapLFGFrameBorder,
      MiniMapBattlefieldBorder,
      MiniMapMailBorder,
      -- raid frame
      CompactRaidFrameContainerBorderFrameBorderTopLeft,
      CompactRaidFrameContainerBorderFrameBorderTop,
      CompactRaidFrameContainerBorderFrameBorderTopRight,
      CompactRaidFrameContainerBorderFrameBorderRight,
      CompactRaidFrameContainerBorderFrameBorderBottomRight,
      CompactRaidFrameContainerBorderFrameBorderBottom,
      CompactRaidFrameContainerBorderFrameBorderBottomLeft,
      CompactRaidFrameContainerBorderFrameBorderLeft,
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

  for i, v in pairs({
      TargetFrameNameBackground,
      FocusFrameNameBackground
    }) do
    v:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  end

  for i, v in pairs({
      PlayerName,
      PlayerLevelText,
      TargetFrameTextureFrameName,
      TargetFrameToTTextureFrameName,
      FocusFrameTextureFrameName,
      FocusFrameToTTextureFrameName,
      PartyMemberFrame1Name,
      PartyMemberFrame2Name,
      PartyMemberFrame3Name,
      PartyMemberFrame4Name,
    }) do
    v:SetVertexColor(1.0, 1.0, 1.0);
    v.SetVertexColor = function () end
  end

  for i, v in pairs({
      PartyMemberFrame1PetFrameName,
      PartyMemberFrame2PetFrameName,
      PartyMemberFrame3PetFrameName,
      PartyMemberFrame4PetFrameName,
    }) do
    v:Hide();
    v.Show = function() end
  end

  -- adjust the player and target cast bar scale
  -- CastingBarFrame:SetScale(1.2);
  TargetFrameSpellBar:SetScale(1.2);

  -- disable damage on player frame
  PlayerHitIndicator:SetText(nil);
  PlayerHitIndicator.SetText = function() end

  -- disable damage on player pet frame
  PetHitIndicator:SetText(nil);
  PetHitIndicator.SetText = function() end

  local _, class = UnitClass('player');
  if (class == 'DEATHKNIGHT') then
    RuneFrame:SetMovable(true);
    RuneFrame:ClearAllPoints();
    RuneFrame:SetPoint('CENTER', PlayerFrame, 'BOTTOM', 27, 0);
    RuneFrame:SetScale(1.3);
    RuneFrame:SetUserPlaced(true);
    RuneFrame:SetMovable(false);
  end

  -- set up alias reload slash command
  SLASH_RL1 = '/rl';
  function SlashCmdList.RL(msg, editbox)
    ReloadUI();
  end

  -- set console key
  SetConsoleKey('<');

  -- set status text
  SetCVar('statusText', '0');
end

-- load addon
Addon:Load();
