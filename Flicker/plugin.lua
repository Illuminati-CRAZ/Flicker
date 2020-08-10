--all this code and messy and probably very bad
--i think
--im assuming its bad
-- so probably do not be like this
function flicker(START, STOP, CYCLE_TIME, DESTINATION_START, TRANSITION_TIME, AVG_SV, PASSIVE_SV, SKIP_END_SV)
    local svs = {}

    for i = START, STOP, CYCLE_TIME do
        local skipsv = (DESTINATION_START - START) / TRANSITION_TIME
        local returnsv = -((DESTINATION_START - START) / TRANSITION_TIME) + (2 * AVG_SV + ((CYCLE_TIME / TRANSITION_TIME - 2) * (AVG_SV - PASSIVE_SV)))
        if i == STOP then --probably better to do a for loop with STOP - CYCLE_TIME for ending the loop then adding this but this causes slightly different behavior when length mod cycle time doesn't equal 0
            if not SKIP_END_SV then
                table.insert(svs, utils.CreateScrollVelocity(i, AVG_SV))
            end
        else
            table.insert(svs, utils.CreateScrollVelocity(i, skipsv))
            if TRANSITION_TIME != CYCLE_TIME / 2 then
                table.insert(svs, utils.CreateScrollVelocity(i + TRANSITION_TIME, PASSIVE_SV))
                table.insert(svs, utils.CreateScrollVelocity(i + CYCLE_TIME / 2 + TRANSITION_TIME, PASSIVE_SV))
            end
            table.insert(svs, utils.CreateScrollVelocity(i + CYCLE_TIME / 2, returnsv))
        end
    end

    actions.PlaceScrollVelocityBatch(svs)
end

function draw()
    imgui.Begin("Flicker")

    state.IsWindowHovered = imgui.IsWindowHovered()

    local START = state.GetValue("START") or 0
    local STOP = state.GetValue("STOP") or 0
    local TRANSITION_TIME = state.GetValue("TRANSITION_TIME") or .125 if TRANSITION_TIME <= 0 then TRANSITION_TIME = .125 end
    local AVG_SV = state.GetValue("AVG_SV") or 1
    local PASSIVE_SV = state.GetValue("PASSIVE_SV") or 1
    local DESTINATION_START = state.GetValue("DESTINATION_START") or 0
    local CYCLE_TIME = state.GetValue("CYCLE_TIME") or 2 if CYCLE_TIME <= 0 then CYCLE_TIME = 2 end

    local confirm = state.GetValue("confirm") or false
    local response = state.GetValue("response") or ""

    local USE_BEAT_SNAP = state.GetValue("USE_BEAT_SNAP") or false

    local SKIP_END_SV = state.GetValue("SKIP_END_SV") or false

    --local debug = state.GetValue("debug") or "hi"

    --this is terrible lmfao
    local thing1 = {START, STOP, TRANSITION_TIME, AVG_SV, PASSIVE_SV, DESTINATION_START, CYCLE_TIME, USE_BEAT_SNAP, SKIP_END_SV}

    --completely perfectly 100% readable
    --copied the current button hack(?) from iceSV
    if imgui.Button("Current", {70, 20}) then START = state.SongTime end imgui.SameLine(0,4) _, START = imgui.InputInt("Start", START)
    if imgui.Button(" Current ", {70, 20}) then STOP = state.SongTime end imgui.SameLine(0,4) _, STOP = imgui.InputInt("Stop", STOP)
    if imgui.Button("  Current  ", {70, 20}) then DESTINATION_START = state.SongTime end imgui.SameLine(0,4) _, DESTINATION_START = imgui.InputInt("Destination", DESTINATION_START)

    --imgui.Separator()
    imgui.Text("")
    if imgui.Button("   Current   ", {70, 20}) then if map.GetScrollVelocityAt(state.SongTime) then AVG_SV = map.GetScrollVelocityAt(state.SongTime).Multiplier else AVG_SV = 1 end end imgui.SameLine(0,4) _, AVG_SV = imgui.InputFloat("Average SV", AVG_SV, .05)
    if imgui.Button("    Current    ", {70, 20}) then if map.GetScrollVelocityAt(state.SongTime) then PASSIVE_SV = map.GetScrollVelocityAt(state.SongTime).Multiplier else PASSIVE_SV = 1 end end imgui.SameLine(0,4) _, PASSIVE_SV = imgui.InputFloat("Passive SV", PASSIVE_SV, .05)

    --imgui.Separator()
    imgui.Text("")
    _, TRANSITION_TIME = imgui.InputFloat("Transition Time", TRANSITION_TIME, .125)
    _, CYCLE_TIME = imgui.InputFloat("Cycle Time", CYCLE_TIME, 1)

    imgui.Text("")
    _, SKIP_END_SV = imgui.Checkbox("Skip End SV", SKIP_END_SV)
    imgui.SameLine(0, 10)
    _, USE_BEAT_SNAP = imgui.Checkbox("Use Number of Beats for Cycle Time (" .. 60000 / state.CurrentTimingPoint.Bpm * CYCLE_TIME .. " ms)", USE_BEAT_SNAP)

    --continuation of terribleness
    --it's jank but it works
    local thing2 = {START, STOP, TRANSITION_TIME, AVG_SV, PASSIVE_SV, DESTINATION_START, CYCLE_TIME, USE_BEAT_SNAP, SKIP_END_SV}
    for i, j in ipairs(thing1) do
        if j != thing2[i] then
            confirm = false
            response = ""
            break
        end
    end

    imgui.Text("")
    if not confirm then
        buttontext = "Flicker"
    else
        buttontext = "Confirm"
    end
    if imgui.Button(buttontext) then
        --[[if (STOP - START) % CYCLE_TIME != 0 then
            response = "The length of the flicker effect is not cleanly divisble by the cycle time."
        end]]--

        if USE_BEAT_SNAP then
            --mspb multiplied by number of beats to get ms per cycle
            NEW_CYCLE_TIME = 60000 / state.CurrentTimingPoint.Bpm * CYCLE_TIME
        else
            NEW_CYCLE_TIME = CYCLE_TIME
        end

        local num_svs = math.floor((STOP - START) / NEW_CYCLE_TIME) * 4
        if not SKIP_END_SV then num_svs = num_svs + 1 end

        if num_svs >= 5000 then
            if not confirm then
                confirm = true
                response = "Are you sure you want to place " .. num_svs .. " SVs?"
            else
                confirm = false
                response = num_svs .. " SVs placed."
                flicker(START, STOP, NEW_CYCLE_TIME, DESTINATION_START, TRANSITION_TIME, AVG_SV, PASSIVE_SV)
            end
        else
            confirm = false
            response = num_svs .. " SVs placed."
            flicker(START, STOP, NEW_CYCLE_TIME, DESTINATION_START, TRANSITION_TIME, AVG_SV, PASSIVE_SV)
        end
    end
    imgui.SameLine(0, 4)
    imgui.TextWrapped(response)

    --imgui.TextWrapped(debug)

    state.SetValue("START", START)
    state.SetValue("STOP", STOP)
    state.SetValue("TRANSITION_TIME", TRANSITION_TIME)
    state.SetValue("AVG_SV", AVG_SV)
    state.SetValue("PASSIVE_SV", PASSIVE_SV)
    state.SetValue("DESTINATION_START", DESTINATION_START)
    state.SetValue("CYCLE_TIME", CYCLE_TIME)

    state.SetValue("confirm", confirm)
    state.SetValue("response", response)

    state.SetValue("USE_BEAT_SNAP", USE_BEAT_SNAP)

    state.SetValue("SKIP_END_SV", SKIP_END_SV)

    --state.SetValue("debug", debug)

    imgui.End()
end
