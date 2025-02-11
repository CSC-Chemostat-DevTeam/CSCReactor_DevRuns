# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
begin
    using CSCReactor_DevRuns
    const R = CSCReactor_DevRuns
    using Dates
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("config/ch.config.main.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    global sp = ch_try_connect(CONFIG)
    nothing
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
# Run protocole
let

    # sec from init -> D
    D_PROTOCOLE = [
        (1/0.5) * 1 * 60 * 60 => 0.5,

        (1/10.0) * 0.5 * 60 * 60 => 10.0,
        1 * 60 * 60 => 0,
        
        (1/1.0) * 2 * 60 * 60 => 1.0,
        
        (1/10.0) * 0.5 * 60 * 60 => 10.0,
        1 * 60 * 60 => 0,
        
        (1/1.5) * 1 * 60 * 60 => 1.333,
        
        (1/10.0) * 0.5 * 60 * 60 => 10.0,
        1 * 60 * 60 => 0,
        
        (1/2.0) * 1 * 60 * 60 => 2.0,

        (1/10.0) * 0.5 * 60 * 60 => 10.0,
        1 * 60 * 60 => 0,
        
        (1/3.0) * 1 * 60 * 60 => 3.0,

        (1/10.0) * 0.5 * 60 * 60 => 10.0,
        1 * 60 * 60 => 0,

        Int(1e10) => 6.0, # end medium
    ]

    # Dilution setting
    TARGET_DS = Dict(
        "D0" => 0.0,
        "CH3" => 581.4 / 2, # correction factor
        "CH5" => 510.6 / 2  # correction factor
    )
    # META
    CONFIG["CH3"]["ch.name"] = "CH3:50%LB.DIL.ONIGHT.RUN.$(now())"
    CONFIG["CH5"]["ch.name"] = "CH5:100%LB.DIL.ONIGHT.RUN.$(now())" 
        
    CHIDs = ["CH3", "CH5"]
    _pump_medium_in = () -> let
        for CHID in CHIDs
            _tper = TARGET_DS["D0"] * TARGET_DS[CHID] # pulses / hour
            _tper = _tper / 60.0 # pulses / min
            _tper = _tper / 60.0 # pulses / sec
            _tper = 1 / _tper # secs
            @show _tper
            ticker = get!(CONFIG[CHID], "ticker") do
                Ticker()
            end
            onelapsed!(ticker, "pump.medium.in.s.pulse", _tper) do _elp
                @show _tper
                @show _elp
                R.ch_as_pulse(CONFIG[CHID], "pump.medium.in")
            end
        end
    end
    
    t0 = time()
    for it in 1:Int(1e10)

        # CHECK D PROTOCOLE
        elpt = time() - t0 # secs
        int_t1 = 0
        @show elpt
        for (t, D0) in D_PROTOCOLE
            int_t1 += t
            if elpt < int_t1 
                @show D0
                for CHID in CHIDs
                    TARGET_DS["D0"] = D0
                end
                break
            end
        end    

        # RUN CHEMOSTAT
        for CHID in CHIDs
            _pump_medium_in()
            meassure_OD(CONFIG[CHID]; v = true)
            _pump_medium_in()
        end
        for CHID in CHIDs
            _pump_medium_in()
            R.ch_as_pulse(CONFIG[CHID], "stirrel")
            _pump_medium_in()
        end
        for CHID in CHIDs
            _pump_medium_in()
            R.ch_as_pulse(CONFIG[CHID], "pump.air.in")
            _pump_medium_in()
        end
        for CHID in CHIDs
            _pump_medium_in()
            R.ch_as_pulse(CONFIG[CHID], "pump.medium.out")
            _pump_medium_in()
            R.ch_as_pulse(CONFIG[CHID], "pump.medium.out")
            _pump_medium_in()
        end
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
