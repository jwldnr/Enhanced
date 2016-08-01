-- locals
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;

-- helper functions
local function SetNamePlateHealthValue(frame)
  if (not frame.healthBar.value) then
    frame.healthBar.value = frame.healthBar:CreateFontString(nil, 'ARTWORK');
    frame.healthBar.value:SetPoint('LEFT', frame.healthBar.value:GetParent(), 'RIGHT', 7, 0);
    frame.healthBar.value:SetFontObject('GameFontHighlight');
  else
    local _, maxHealth = frame.healthBar:GetMinMaxValues();
    local value = frame.healthBar:GetValue();
    frame.healthBar.value:SetText(string.format(math.floor((value / maxHealth) * 100)) .. ' %');
  end
end

local function IsTanking(unit)
  local isTanking = UnitDetailedThreatSituation('player', unit);
  return isTanking;
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

function Addon:SetUpNamePlateFrame(frame)
  frame.healthBar.background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
  frame.healthBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
  frame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");

  if (frame.castBar) then
    frame.castBar.background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
    frame.castBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
    frame.castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");

    --frame.castBar:SetStatusBarColor(1.0, 0.7, 0.0);
    --frame.castBar.SetStatusBarColor = function () end
  end

  SetNamePlateHealthValue(frame);

  if (frame.optionTable.showClassificationIndicator) then
    frame.optionTable.showClassificationIndicator = false;
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
  SetNamePlateHealthValue(frame);
end

function Addon:UpdateNamePlateHealthColor(frame)
  if (UnitExists(frame.unit) and frame.isTanking or IsTanking(frame.displayedUnit)) then
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

    if (frame.castBar and not frame.castBar.barBorder) then
      frame.castBar.barBorder = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');

      frame.castBar.barBorder:SetVertexColor(0.0, 0.0, 0.0, 1.0);

      frame.castBar.BorderShield:SetSize(20, 24);
    end
  end
end

function Addon:UpdateNamePlateCastingBarTimer(frame, elapsed)
  if (not frame.timer) then
    frame.timer = frame:CreateFontString(nil);
    frame.timer:SetFont(STANDARD_TEXT_FONT, 14, 'OUTLINE');
    frame.timer:SetPoint('TOP', frame.timer:GetParent(), 'BOTTOM', 0, -3);
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
    frame:SetStatusBarColor(0.5, 0.5, 0.5);
  end
end

function Addon:UpdateFramePortrait(frame)
  if (frame.portrait) then
    if (UnitIsPlayer(frame.unit)) then
      local t = CLASS_ICON_TCOORDS[select(2, UnitClass(frame.unit))];

      if (t) then
        frame.portrait:SetTexture('Interface\\TargetingFrame\\UI-Classes-Circles');
        frame.portrait:SetTexCoord(unpack(t));
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

    if (color.r == 1.0 and color.g == 0.82 and color.b == 0.0) then
      frame.levelText:SetVertexColor(1.0, 1.0, 1.0);
    end
  else
    frame.levelText:SetVertexColor(1.0, 1.0, 1.0);
  end
end

function Addon:CheckTargetFaction(frame)
  if (UnitIsPlayer(frame.unit)) then
    local c = RAID_CLASS_COLORS[select(2, UnitClass(frame.unit))];
    frame.nameBackground:SetVertexColor(c.r, c.g, c.b);
  end
end

function Addon:HookActionEvents()
  local function Frame_SetUpFrame(frame)
    Addon:SetUpNamePlateFrame(frame);
  end

  local function Frame_UpdateHealth(frame)
    Addon:UpdateNamePlateHealth(frame);
  end

  local function Frame_UpdateHealthColor(frame)
    Addon:UpdateNamePlateHealthColor(frame);
  end

  local function Frame_UpdateHealthBorder(frame)
    Addon:UpdateNamePlateHealthBorder(frame);
  end

  local function CastingBarFrame_Update(frame, elapsed)
    Addon:UpdateNamePlateCastingBarTimer(frame, elapsed);
  end

  local function UnitFrame_PortraitUpdate(frame)
    Addon:UpdateFramePortrait(frame);
  end

  local function Target_CheckLevel(frame)
    Addon:CheckTargetLevel(frame);
  end

  local function Target_CheckFaction(frame)
    Addon:CheckTargetFaction(frame);
  end

  hooksecurefunc('CompactUnitFrame_SetUpFrame', Frame_SetUpFrame);
  hooksecurefunc('CompactUnitFrame_UpdateHealth', Frame_UpdateHealth);
  hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateHealthColor);
  hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', Frame_UpdateHealthBorder);
  hooksecurefunc('CastingBarFrame_OnUpdate', CastingBarFrame_Update);

  hooksecurefunc('UnitFramePortrait_Update', UnitFrame_PortraitUpdate);
  hooksecurefunc('TargetFrame_CheckLevel', Target_CheckLevel);
  hooksecurefunc('TargetFrame_CheckFaction', Target_CheckFaction);
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
    RuneFrame:ClearAllPoints();
    RuneFrame:SetPoint('CENTER', PlayerFrame, 'BOTTOM', 27, 0);
    RuneFrame:SetScale(1.3);
  end

  -- set up alias reload slash command
  SLASH_RL1 = '/rl';
  function SlashCmdList.RL(msg, editbox)
    ReloadUI();
  end

  SetConsoleKey('<');
end

-- load addon
Addon:Load();
