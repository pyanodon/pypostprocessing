-- fixes https://github.com/pyanodon/pybugreports/issues/1131
local hiddenUraniumProcessing = TECHNOLOGY("uranium-processing").hidden
if hiddenUraniumProcessing then
    if mods.SchallMachineScaling then
        TECHNOLOGY("centrifuge-MS-1"):remove_prereq("uranium-processing")
        log("Mod 'SchallMachineScaling' detected while technology 'uranium-processing' is hidden: removing as prerequisite from 'centrifuge-MS-1'.")
    end
end
