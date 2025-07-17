local helper = {}

if script.active_mods.pyalienlife then
  local parity = require("__pyalienlife__/scripts/parity")
  
  function helper.select_turd(master_tech_name, sub_tech_name)
    local fake_event = {
      skip_gui = true,
      player = game.player,
      master_tech_name = master_tech_name,
      sub_tech_name = sub_tech_name,
    }

    remote.call("pywiki_turd_page", "new_turd", fake_event)
    -- gui_events[defines.events.on_gui_click]["py_turd_confirm_button"](fake_event)
  end
end

return helper
