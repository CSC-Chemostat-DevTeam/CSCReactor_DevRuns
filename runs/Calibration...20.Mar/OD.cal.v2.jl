@time begin
    using CSCReactor_DevRuns
    const R = CSCReactor_DevRuns
    using CairoMakie
    using Random
    # using LibSerialPort
    # using InteractiveUtils
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("config/ch.config.main.jl")
include("OD.cal.utils.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    ch_try_connect(CONFIG)
    nothing
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Setup

CHIDXs = [1,2,3,4,5]
nothing

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PinMode
let
    pkg = send_csvcmd(SP, "INO", "PIN-MODE", 
        CONFIG["R1"]["stirrel.pin"], OUTPUT,
        log = false
    )

    for CHIDX in CHIDXs
        CHID = string("CH", CHIDX)
        pkg = send_csvcmd(SP, "INO", "PIN-MODE", 
            CONFIG[CHID]["laser.pin"], OUTPUT,
            CONFIG[CHID]["led.control.pin"], INPUT_PULLUP,
            CONFIG[CHID]["led.sample.pin"], INPUT_PULLUP;
            log = false
        )
        @assert !isempty(pkg["done_ack"]) 
    end
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DATA TO WRITE

# meta
CONC = "test"
# CONC = "0.0-r1"
# CONC = "0.1-r1"
# CONC = "0.2-r1"
# CONC = "0.3-r1"
# CONC = "0.4-r1"
# CONC = "0.5-r1"
# CONC = "0.6-r1"
# CONC = "0.7-r1"
# CONC = "0.8-r1"
# CONC = "0.9-r1"
# CONC = "1.0-r1"

# read
LED1_VALS = Dict()
LED2_VALS = Dict()
LASER_PWMS = Dict()

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    try

        iter_count = 0
        iter_max = 30

        plot_frec = 1
        plot_last_time = 0
        
        laser_pwm = 0
        laser_pwm1 = 255
        
        stirrel_frec = 3.0
        stirrel_last_time = 0

        while true
            # laser on
            @show CONC
            @show iter_count
            # @show laser_pwm

            shuffle!(CHIDXs)
            CHIDtoplot = string("CH", rand(CHIDXs))
            for CHIDX in CHIDXs
                CHID = string("CH", CHIDX)
                laser_pwm = rand(1:255)

                # MARK: stirrel
                if time() - stirrel_last_time > stirrel_frec
                    # $INO:DIGITAL-C-PULSE:PIN:VAL0:TIME:[VAL1]%
                    @time pkg1 = send_csvcmd(SP, "INO", "DIGITAL-S-PULSE", 
                        CONFIG["R1"]["stirrel.pin"], 1, 500, 0;
                        log = false
                    )
                    stirrel_last_time = time()
                    sleep(0.5) # relax
                end
                
                # MARK: Read
                laser_pwm = mod(laser_pwm + 10, laser_pwm1)
                @time send_csvcmd(SP, 
                    "INO", "ANALOG-WRITE", 
                    CONFIG[CHID]["laser.pin"], laser_pwm;
                    log = false
                )
                sleep(0.1); # relax

                # read sensors 1
                @time pkg1 = send_csvcmd(SP, 
                    "INO", "PULSE-IN", 
                    CONFIG[CHID]["led.control.pin"], 100;
                    log = false
                )
                isempty(pkg1["done_ack"]) && continue
                val1 = parse(Int, pkg1["responses"][0]["data"][2])

                # read sensors 2
                @time pkg2 = send_csvcmd(SP, 
                    "INO", "PULSE-IN", 
                    CONFIG[CHID]["led.sample.pin"], 100;
                    log = false
                )
                isempty(pkg2["done_ack"]) && continue
                val2 = parse(Int, pkg2["responses"][0]["data"][2])

                # laser off
                @time send_csvcmd(SP, 
                    "INO", "DIGITAL-WRITE", 
                    CONFIG[CHID]["laser.pin"], 0;
                    log = false
                )
                
                # push
                LED1_VALS
                _getpush!(LED1_VALS, CHID, val1, Float64[])
                _getpush!(LED2_VALS, CHID, val2, Float64[])
                _getpush!(LASER_PWMS, CHID, laser_pwm, Int[])

                # MARK: plot
                if CHID == CHIDtoplot
                    _do_plot(
                        CHID, CONC, LED1_VALS[CHID], LED2_VALS[CHID], LASER_PWMS[CHID],
                    )
                end
            end

            iter_count += 1
            iter_count < iter_max || break
            
        end # main loop

        # MARK: write
        # _do_write(;
        #     CONC, CHID, 
        #     LED1_VALS, LED2_VALS,
        #     LASER_PWMS,
        #     dir = joinpath(@__DIR__, "MILK")
        # )

    catch err; 
        err isa InterruptException || rethrow(err)
        @error err
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# # PULSESES
# # stirrel       D8
# # pump          D12
# let
#     # send_csvcmd(SP, "INO", "ANALOG-PULSE", CONFIG["R1"]["stirrel.pin"], 250, 0, 5)
#     send_csvcmd(SP, "INO", "ANALOG-PULSE", 
#         PUMP_PWMPIN, 
#         255, # POWER 
#         0, 
#         1    # PULSE DURATION (ms)
#     )
#     nothing
# end