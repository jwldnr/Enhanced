function Addon:Load()

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
  local eventHandler = CreateFrame('FRAME', nil);
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

    if (unit ~= 'player') then return end

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
