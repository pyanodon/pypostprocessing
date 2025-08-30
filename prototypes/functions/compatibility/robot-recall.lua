if mods[ "robot-recall" ] and mods[ "pyindustry" ] then
    -- The robot distribution chest should be available when construction bots are researched
    RECIPE("robot-redistribute-chest"):remove_unlock("logistic-robotics"):remove_ingredient("advanced-circuit")
    -- The robot recall chest can wait until mk02 robots are researched
    RECIPE("robot-recall-chest"):remove_unlock("construction-robotics"):remove_unlock("logistic-robotics"):add_unlock("robotics")
end
