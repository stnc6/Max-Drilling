local MAX_UPGRADES = {
    auto_repair_level_1 = 1,
    auto_repair_level_2 = 1,
    speed_upgrade_level = 2,
    silent_drill = true,
    reduced_alert = true
}

local _orig_Drill_init = Drill.init
function Drill:init(...)
    _orig_Drill_init(self, ...)
    self._skill_upgrades = table.deep_map_copy and table.deep_map_copy(MAX_UPGRADES) or clone(MAX_UPGRADES)
    local sess = managers.network:session()
    if sess then
        sess:send_to_peers_synched(
            "sync_drill_upgrades",
            self._unit,
            self._skill_upgrades.auto_repair_level_1,
            self._skill_upgrades.auto_repair_level_2,
            self._skill_upgrades.speed_upgrade_level,
            self._skill_upgrades.silent_drill,
            self._skill_upgrades.reduced_alert
        )
    end
end

local _orig_Drill_get_upgrades = Drill.get_upgrades
function Drill:get_upgrades(unit, ...)
    local ub = unit and unit:base()
    if ub and (ub.is_saw or ub.is_drill) then
        return clone(MAX_UPGRADES)
    end
    return _orig_Drill_get_upgrades(self, unit, ...)
end

local _orig_Drill_on_melee_hit = Drill.on_melee_hit
function Drill:on_melee_hit(...)
    local unit = self._unit
    local sess = managers.network:session()
    local gui = alive(unit) and unit:timer_gui()

    if not gui then
        return
    end

    if gui._jammed then
        if Network:is_client() and sess then
            sess:send_to_host("sync_unit_event_id_16", unit, "base", Drill.EVENT_IDS.melee_restart_client)
        else
            self:on_melee_hit_success()
        end

        unit:set_skill_upgrades(self._skill_upgrades or MAX_UPGRADES)
        if sess then
            local s = self._skill_upgrades or MAX_UPGRADES
            sess:send_to_peers_synched(
                "sync_drill_upgrades",
                unit, s.auto_repair_level_1, s.auto_repair_level_2,
                s.speed_upgrade_level, s.silent_drill, s.reduced_alert
            )
        end

        gui:set_jammed(false)
    else
        local decrease = 10
        local timer = gui._current_timer
        local floorv = math.floor(timer or -1)
        if timer and floorv ~= -1 and floorv > decrease then
            local newvalue = timer - decrease
            gui:_start(newvalue)
            if sess then
                sess:send_to_peers_synched("start_timer_gui", gui._unit, newvalue)
            end
        end
    end

end
