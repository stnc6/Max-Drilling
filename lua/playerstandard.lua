local _orig_PlayerStandard_init = PlayerStandard.init
function PlayerStandard:init(...)
    _orig_PlayerStandard_init(self, ...)
    self._on_melee_restart_drill = true
end
