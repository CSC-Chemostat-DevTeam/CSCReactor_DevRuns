@time begin
    using CSCReactor_DevRuns
    const R = CSCReactor_DevRuns
    using CairoMakie
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

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Setup

CHIDX = rand(1:5)
CHID = string("CH", CHIDX)
LASER_PWMPIN = CONFIG[CHID]["laser.pin"]
STIRREL_PWMPIN = CONFIG["R1"]["stirrel.pin"]
LED1_INPIN = CONFIG[CHID]["led.control.pin"]
LED2_INPIN = CONFIG[CHID]["led.sample.pin"]
nothing

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PinMode
let
    pkg = send_csvcmd(SP, "INO", "PIN-MODE", 
        STIRREL_PIN, OUTPUT,

        LASER_PWMPIN, OUTPUT,
        LED2_INPIN, INPUT_PULLUP,
        LED1_INPIN, INPUT_PULLUP;
        log = false
    )
    @assert !isempty(pkg["done_ack"]) 
    nothing
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
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
LED1_VALS = Float64[]
LED2_VALS = Float64[]
LASER_PWMS = Int[]

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    try

        iter_count = 0
        iter_max = 6

        plot_frec = 1
        plot_last_time = 0
        
        laser_pwm = 0
        laser_pwm1 = 255
        
        stirrel_frec = 0.5
        stirrel_last_time = 0

        while true
            # laser on
            @show CONC
            @show iter_count
            @show laser_pwm

            laser_pwm = mod(laser_pwm + 10, laser_pwm1)
            @time send_csvcmd(SP, 
                "INO", "ANALOG-WRITE", 
                LASER_PWMPIN, laser_pwm;
                log = false
            )

            # stirrel
            if time() - stirrel_last_time > stirrel_frec
                # $INO:DIGITAL-C-PULSE:PIN:VAL0:TIME:[VAL1]%
                @time pkg1 = send_csvcmd(SP, "INO", "DIGITAL-S-PULSE", 
                    STIRREL_PWMPIN, 1, 500, 0;
                    log = false
                )
                stirrel_last_time = time()
                sleep(0.5) # relax
            end

            # read sensors 1
            @time pkg1 = send_csvcmd(SP, 
                "INO", "PULSE-IN", 
                LED1_INPIN, 100;
                log = false
            )
            isempty(pkg1["done_ack"]) && continue
            val1 = parse(Int, pkg1["responses"][0]["data"][2])

            # read sensors 2
            @time pkg2 = send_csvcmd(SP, 
                "INO", "PULSE-IN", 
                LED2_INPIN, 100;
                log = false
            )
            isempty(pkg2["done_ack"]) && continue
            val2 = parse(Int, pkg2["responses"][0]["data"][2])

            # laser off
            @time send_csvcmd(SP, 
                "INO", "DIGITAL-WRITE", 
                LASER_PWMPIN, 0;
                log = false
            )
            
            # push
            push!(LED1_VALS, val1)
            push!(LED2_VALS, val2)
            push!(LASER_PWMS, laser_pwm)

            iter_count += 1
            iter_count < iter_max || break

            # MARK: plot
            _do_plot(
                CHID, CONC, LED1_VALS, LED2_VALS, LASER_PWMS,
            )
            
        end # loop

        # MARK: write
        _do_write(;
            CONC, CHID, 
            LED1_VALS, LED2_VALS,
            LASER_PWMS,
            dir = joinpath(@__DIR__, "MILK")
        )

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
#     # send_csvcmd(SP, "INO", "ANALOG-PULSE", STIRREL_PWMPIN, 250, 0, 5)
#     send_csvcmd(SP, "INO", "ANALOG-PULSE", 
#         PUMP_PWMPIN, 
#         255, # POWER 
#         0, 
#         1    # PULSE DURATION (ms)
#     )
#     nothing
# end