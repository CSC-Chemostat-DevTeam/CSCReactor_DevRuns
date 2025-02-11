@time begin
    using CSCReactor_jlOs
    using CSCReactor_jlOs: _logfile
    using CairoMakie
    using LibSerialPort
    using InteractiveUtils
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("0.ch.configs.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    portname = find_port()
    @show portname
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Setup

CHIDX = 2
CHID = string("CH", CHIDX)
LASER_PWMPIN = CONFIG[CHID]["laser.pin"]
STIRREL_PWMPIN = CONFIG[CHID]["stirrel.pin"]
LED1_INPIN = CONFIG[CHID]["led1.pin"]
LED2_INPIN = CONFIG[CHID]["led2.pin"]
nothing

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PinMode
let
    pkg = send_csvcmd(sp, "INO", "PIN-MODE", 
        STIRREL_PIN, OUTPUT,

        LASER_PWMPIN, OUTPUT,
        LED2_INPIN, INPUT_PULLUP,
        LED1_INPIN, INPUT_PULLUP;
        log = false
    )
    @assert !isempty(pkg["done_ack"]) 
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DATA TO WRITE

# meta
CONC = "0.0-r1"
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
        iter_max = 600

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
            @time send_csvcmd(sp, 
                "INO", "ANALOG-WRITE", 
                LASER_PWMPIN, laser_pwm;
                log = false
            )

            # stirrel
            if time() - stirrel_last_time > stirrel_frec
                # $INO:DIGITAL-C-PULSE:PIN:VAL0:TIME:[VAL1]%
                @time pkg1 = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                    STIRREL_PWMPIN, 1, 350, 0;
                    log = false
                )
                stirrel_last_time = time()
                sleep(0.5) # relax
            end

            # read sensors 1
            @time pkg1 = send_csvcmd(sp, 
                "INO", "PULSE-IN", 
                LED1_INPIN, 100;
                log = false
            )
            isempty(pkg1["done_ack"]) && continue
            val1 = parse(Int, pkg1["responses"][0]["data"][2])

            # read sensors 2
            @time pkg2 = send_csvcmd(sp, 
                "INO", "PULSE-IN", 
                LED2_INPIN, 100;
                log = false
            )
            isempty(pkg2["done_ack"]) && continue
            val2 = parse(Int, pkg2["responses"][0]["data"][2])

            # laser off
            @time send_csvcmd(sp, 
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

            # plot
            _doplot = time() - plot_last_time > plot_frec
            _doplot = _doplot && isinteractive()
            if _doplot
                plot_last_time = time()
                
                isempty(LED1_VALS) && continue
                isempty(LED2_VALS) && continue
                isempty(LASER_PWMS) && continue

                f = Figure()
                
                limits = (nothing, nothing, 0, nothing)
                ax = Axis(f[1, 1]; limits, ylabel = "laser power", aspect = 1.0)
                scatter!(ax, eachindex(LASER_PWMS), LASER_PWMS; color = :red)
                
                ax = Axis(f[1, 2]; limits, xlabel = "time", ylabel = "led read", aspect = 1.0)
                scatter!(ax, eachindex(LED1_VALS), LED1_VALS; color = :red)
                scatter!(ax, eachindex(LED2_VALS), LED2_VALS; color = :blue)
                
                ax = Axis(f[2, 1]; limits, xlabel = "led read", ylabel = "laser power", aspect = 1.0)
                scatter!(ax, LED1_VALS, LASER_PWMS; color = :red)
                scatter!(ax, LED2_VALS, LASER_PWMS; color = :blue)

                ax = Axis(f[2, 2]; limits, xlabel = "led1 read", ylabel = "led2 read", aspect = 1.0)
                scatter!(ax, LED1_VALS, LED2_VALS; color = :red)

                # ax = Axis(f[2, 2]; limits, xlabel = "led1 read", ylabel = "led2 read", aspect = 1.0)
                # scatter!(ax, eachindex(LED1_VALS), log10.(LED1_VALS ./ LED2_VALS); 
                #     color = :red
                # )

                display(f)
            end
        end # loop

        # write
        dir = joinpath(@__DIR__, "MILK")
        mkpath(dir)
        fn = _logfile("C$CONC..."; dir, ext = ".csv")
        open(fn, "w") do io
            # header
            println(io, 
                join(string.([
                        "CHIDX", "CONC", "LED1_VALS", "LED2_VALS", "LASER_PWMS"
                ]), ";")
            )

            # dat
            for i in 1:iter_count
                println(io, 
                    join(string.([
                        CHIDX, CONC, LED1_VALS[i], LED2_VALS[i], LASER_PWMS[i]
                    ]), ";")
                )
            end
        end

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
#     # send_csvcmd(sp, "INO", "ANALOG-PULSE", STIRREL_PWMPIN, 250, 0, 5)
#     send_csvcmd(sp, "INO", "ANALOG-PULSE", 
#         PUMP_PWMPIN, 
#         255, # POWER 
#         0, 
#         1    # PULSE DURATION (ms)
#     )
#     nothing
# end