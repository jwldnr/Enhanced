-- locals
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;
local unpack = unpack;
local max = math.max;
local ceil = math.ceil;
local print = print;

local buttonFlash = {};

-- helper functions
local function IsTanking(unit)
  return select(1, UnitDetailedThreatSituation('player', unit));
end

local function ShowHealthText(frame)
  Addon:UpdateHealthText(frame);
end

local function HideHealthText(frame)
  frame.healthBar.healthText:SetText(nil);
  frame.healthBar.healthText:Hide();
end

function Addon:Load()
  do
    local eventHandler = CreateFrame('Frame', nil);

    -- set OnEvent handler
    eventHandler:SetScript('OnEvent', function(handler, event, ...)
        self:OnEvent(event);
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
  frame.castBar.BorderShield:ClearAllPoints();
  frame.castBar.BorderShield:SetPoint('RIGHT', frame.castBar, 'LEFT', 0, 0);

  frame.castBar.Icon:SetSize(20, 20);
  frame.castBar.Icon:ClearAllPoints();
  frame.castBar.Icon:SetPoint('RIGHT', frame.castBar, 'LEFT', 0, 0);

  if (frame.optionTable.showClassificationIndicator) then
    frame.optionTable.showClassificationIndicator = nil;
  end

  if (not frame.healthBar.healthText) then
    frame.healthBar.healthText = frame.healthBar:CreateFontString(nil, 'ARTWORK');
    -- frame.healthBar.healthText:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
    frame.healthBar.healthText:SetFontObject('GameFontHighlight');
    frame.healthBar.healthText:SetPoint('LEFT', frame.healthBar, 'RIGHT', 7, 0);

    frame:HookScript('OnShow', ShowHealthText);
    frame:HookScript('OnHide', HideHealthText);

    frame.healthBar.update = 0.5;
  end
end

function Addon:UpdateNamePlate(frame, elapsed)
  if (frame.healthBar.update) then
    frame.healthBar.update = frame.healthBar.update + elapsed;

    if (frame.healthBar.update > 0.5) then
      frame.healthBar.update = 0;
      self:UpdateHealthText(frame);
    end
  end
end

function Addon:UpdateHealthText(frame)
  if (not frame.healthBar.healthText) then return end

  if (UnitHealthMax(frame.displayedUnit) > 0) then
    local percent = ceil(100 * (UnitHealth(frame.displayedUnit) / UnitHealthMax(frame.displayedUnit)));
    frame.healthBar.healthText:SetFormattedText("%d%%", percent);
    frame.healthBar.healthText:Show();
  else
    frame.healthBar.healthText:Hide();
  end
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

function Addon:LoadCastingBar(frame, unit, showTradeSkills, showShield)
  if (not frame.text) then
    frame.text = frame:CreateFontString(nil, 'ARTWORK');
    -- frame.castBar.castText:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
    frame.text:SetFontObject('GameFontHighlight');
    frame.text:SetPoint('LEFT', frame, 'RIGHT', 7, 0);

    -- frame:HookScript('OnShow', ShowCastBarText);
    -- frame:HookScript('OnHide', HideCastBarText);

    frame.update = 0.2;
  end
end

function Addon:UpdateCastingBarText(frame)
  if (frame.casting) then
    frame.castText:SetFormattedText('%2.1f/%1.1f', max(frame.maxValue - frame.value, 0), frame.maxValue);
  elseif (frame.channeling) then
    frame.castText:SetFormattedText('%.1f', max(frame.value, 0));
  else
    frame.castText:SetText(nil);
  end
end

function Addon:UpdateCastingBarTimer(frame, elapsed)
  if (not frame.castText) then
    frame.castText = frame:CreateFontString(nil, 'ARTWORK');
    -- frame.castBar.castText:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
    frame.castText:SetFontObject('GameFontHighlight');
    frame.castText:SetPoint('TOP', frame, 'BOTTOM', 0, -5);

    frame.update = 0.2;
  else
    if (frame.update) then
      frame.update = frame.update + elapsed;

      if (frame.update > 0.2) then
        frame.update = 0;
        self:UpdateCastingBarText(frame);
      end
    end
  end

  local r, g, b = frame:GetStatusBarColor();
  if (r > 0.5 and g > 0.5 and b > 0.5) then
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

function Addon:ActionButtonDown(id)
  local button;

  if (C_PetBattles.IsInBattle()) then
    if (PetBattleFrame) then
      if (id > NUM_BATTLE_PET_HOTKEYS) then return end

      button = PetBattleFrame.BottomFrame.abilityButtons[id];
      if (id == BATTLE_PET_ABILITY_SWITCH) then
        button = PetBattleFrame.BottomFrame.SwitchPetButton;
      elseif (id == BATTLE_PET_ABILITY_CATCH) then
        button = PetBattleFrame.BottomFrame.CatchButton;
      end

      if (not button) then return end
    end
  end

  if (OverrideActionBar and OverrideActionBar:IsShown()) then
    if (id > NUM_OVERRIDE_BUTTONS) then return end

    button = _G['OverrideActionBarButton'..id];
  else
    button = _G['ActionButton'..id];
  end

  if (not button) then return end
  self:AnimateButton(button);
end

function Addon:MultiActionButtonDown(bar, id)
  local button = _G[bar..'Button'..id];
  self:AnimateButton(button);
end

function Addon:AnimateButton(button)
  if (not button:IsVisible()) then return end

  buttonFlash.frame:SetPoint('TOPLEFT', button ,'TOPLEFT', -3, 3);
  buttonFlash.frame:SetPoint('BOTTOMRIGHT', button ,'BOTTOMRIGHT', 3, -3);

  -- buttonFlash.frame:SetFrameStrata(button:GetFrameStrata());
  buttonFlash.frame:SetFrameStrata('HIGH');
  buttonFlash.frame:SetFrameLevel(button:GetFrameLevel());
  -- buttonFlash.frame:SetAllPoints(button);

  buttonFlash.animation:Stop();
  buttonFlash.animation:Play();
end

function Addon:UpdateActionButton(button)
  local texture = button:GetPushedTexture();
  if (texture ~= nil) then
    button:SetPushedTexture(nil);
  end
end

function Addon:HookActionEvents()
  local function Frame_SetupNamePlate(frame, setupOptions, frameOptions)
    Addon:SetupNamePlate(frame, setupOptions, frameOptions);
  end

  local function Frame_NamePlateOnUpdate(frame, elapsed)
    Addon:UpdateNamePlate(frame, elapsed);
  end

  local function Frame_UpdateHealthText(frame, ...)
    Addon:UpdateHealthText(frame);
  end

  local function Frame_UpdateNamePlateHealthColor(frame)
    Addon:UpdateNamePlateHealthColor(frame);
  end

  local function Frame_UpdateNamePlateHealthBorder(frame)
    Addon:UpdateNamePlateHealthBorder(frame);
  end

  local function Frame_LoadCastingBar(frame, unit, showTradeSkills, showShield)
    Addon:LoadCastingBar(frame, unit, showTradeSkills, showShield);
  end

  local function CastingBarFrame_Update(frame, elapsed)
    Addon:UpdateCastingBarTimer(frame, elapsed);
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

  local function Button_ActionButtonDown(id)
    Addon:ActionButtonDown(id);
  end

  local function Button_MultiActionButtonDown(bar, id)
    Addon:MultiActionButtonDown(bar, id);
  end

  local function Button_UpdateActionButton(button)
    Addon:UpdateActionButton(button);
  end

  hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlate);
  hooksecurefunc('CompactUnitFrame_OnUpdate', Frame_NamePlateOnUpdate);
  -- hooksecurefunc('CompactUnitFrame_UpdateHealth', Frame_UpdateHealthText);
  hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateNamePlateHealthColor);
  hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', Frame_UpdateNamePlateHealthBorder);

  -- hooksecurefunc('CastingBarFrame_OnUpdate', CastingBarFrame_Update);

  hooksecurefunc('UnitFramePortrait_Update', Frame_UpdateUnitPortrait);
  hooksecurefunc('TargetFrame_CheckLevel', Frame_CheckTargetLevel);
  hooksecurefunc('TargetFrame_CheckFaction', Frame_CheckTargetFaction);

  CastingBarFrame:HookScript('OnUpdate', CastingBarFrame_Update);
  TargetFrameSpellBar:HookScript('OnUpdate', CastingBarFrame_Update);

  hooksecurefunc('ActionButtonDown', Button_ActionButtonDown);
  hooksecurefunc('MultiActionButtonDown', Button_MultiActionButtonDown);
  hooksecurefunc('ActionButton_OnUpdate', Button_UpdateActionButton);
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

  -- set up button flash frame/animation
  buttonFlash.frame = CreateFrame('Frame', nil);
  local texture = buttonFlash.frame:CreateTexture();
  texture:SetTexture('Interface\\Cooldown\\star4');
  texture:SetAlpha(0);
  texture:SetAllPoints(buttonFlash.frame);
  texture:SetBlendMode('ADD');
  texture:SetDrawLayer('BACKGROUND', 7);

  buttonFlash.animation = texture:CreateAnimationGroup();
  local alpha1 = buttonFlash.animation:CreateAnimation('Alpha');
  alpha1:SetFromAlpha(0);
  alpha1:SetToAlpha(1);
  alpha1:SetDuration(0);
  alpha1:SetOrder(1);

  local scale1 = buttonFlash.animation:CreateAnimation('Scale');
  scale1:SetScale(1.5, 1.5);
  scale1:SetDuration(0);
  scale1:SetOrder(1);

  local scale2 = buttonFlash.animation:CreateAnimation('Scale');
  scale2:SetScale(0, 0);
  scale2:SetDuration(0.3);
  scale2:SetOrder(2);

  local rotation2 = buttonFlash.animation:CreateAnimation('Rotation');
  rotation2:SetDegrees(90);
  rotation2:SetDuration(0.3);
  rotation2:SetOrder(2);

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

  -- set status text
  SetCVar('statusText', '0');

  -- ensure key press on key down
  SetCVar('ActionButtonUseKeyDown', '1');
end

-- load addon
Addon:Load();
