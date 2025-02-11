# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
begin
    using CSCReactor_DevRuns
    const R = CSCReactor_DevRuns
    using Dates
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("config/ch.config.main.jl")

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    global sp = ch_try_connect(CONFIG)
    nothing
end

# D meassure
# Ch5
#    [ml] / 20 mins

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# META
let
    CONFIG["CH3"]["ch.name"] = "CH3:10%LB.BASH.$(now())"
    CONFIG["CH5"]["ch.name"] = "CH5:1.0%LB.BASH.$(now())"
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PinMode
let
    CHIDs = ["CH3", "CH5"]

    for CHID in CHIDs
        CH = CONFIG[CHID]
        ch_set_pin_modes!(CH)
    end
end
    
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    CHIDs = ["CH3", "CH5"]

    for it in 1:Int(1e10)
        for CHID in CHIDs
            meassure_OD(CONFIG[CHID]; v = true)
        end
        for CHID in CHIDs
            R.ch_as_pulse(CONFIG[CHID], "pump.air.in")
        end
        for CHID in CHIDs
            R.ch_as_pulse(CONFIG[CHID], "stirrel")
            break
        end
    end
end