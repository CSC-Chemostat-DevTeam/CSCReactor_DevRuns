# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
begin
    using CSCReactor_DevRuns
    const R = CSCReactor_DevRuns
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("config/ch.config.main.jl")

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    ch_try_connect(CONFIG)
    nothing
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Wash protocole
let
    CHIDs = ["CH3", "CH5"]

    for CHID in CHIDs
        CH = CONFIG[CHID]
        ch_set_pin_modes!(CH)
    end
    
    # for it in 1:Int(1e10)
    for it in 1:80
        for CHID in CHIDs
            # @show CHID
            ch_as_pulse(CONFIG[CHID], "pump.medium.in"; v = true)
        end
        for CHID in CHIDs
            ch_as_pulse(CONFIG[CHID], "pump.medium.out"; v = true)
            ch_as_pulse(CONFIG[CHID], "pump.medium.out"; v = true)
        end
        for CHID in CHIDs
            ch_as_pulse(CONFIG[CHID], "pump.air.in"; v = true)
        end
        # for CHID in CHIDs
        #     ch_as_pulse(CONFIG[CHID], "stirrel"; v = true)
        #     ch_as_pulse(CONFIG[CHID], "stirrel"; v = true)
        # end
        # sleep(1)
    end
    println()
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
