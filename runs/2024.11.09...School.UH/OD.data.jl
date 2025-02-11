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
include("OD.data.utils.jl")

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

CHIDs = [
    "CH2", 
    "CH3", 
    "CH4", 
    "CH5"
]
nothing

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PinMode
let
    for CHID in CHIDs
        pkg = send_csvcmd(sp, "INO", "PIN-MODE", 
            STIRREL_PIN, OUTPUT,

            CONFIG[CHID]["laser.pin"], OUTPUT,
            CONFIG[CHID]["led2.pin"], INPUT_PULLUP,
            CONFIG[CHID]["led1.pin"], INPUT_PULLUP;
            log = false
        )
        @assert !isempty(pkg["done_ack"])
    end
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DATA TO WRITE

# meta
CONC_DICT = Dict(
    "CH2" => "dev", 
    "CH3" => "dev", 
    "CH4" => "dev", 
    "CH5" => "dev", 
)

@assert all(haskey(CONC_DICT, id) for id in CHIDs)

# read
LED1_DICT = Dict()
LED2_DICT = Dict()
LASER_DICT = Dict()

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
            for CHID in CHIDs

                LED1_VALS = get!(LED1_DICT, CHID, Float64[])
                LED2_VALS = get!(LED2_DICT, CHID, Float64[])
                LASER_PWMS = get!(LASER_DICT, CHID, Int[])
                CONC = CONC_DICT[CHID]

                # laser on
                @show CONC
                @show iter_count
                @show laser_pwm

                laser_pwm = mod(laser_pwm + 10, laser_pwm1)
                @time send_csvcmd(sp, 
                    "INO", "ANALOG-WRITE", 
                    CONFIG[CHID]["laser.pin"], laser_pwm;
                    log = false
                )

                # stirrel
                if time() - stirrel_last_time > stirrel_frec
                    # $INO:ANALOG-S-PULSE:PIN1:VAL01:TIME1:VAL11...%
                    @time pkg1 = send_csvcmd(sp, "INO", "ANALOG-S-PULSE", 
                        CONFIG[CHID]["stirrel.pin"], 100, 50, 100,
                        CONFIG[CHID]["stirrel.pin"], 150, 50, 150,
                        CONFIG[CHID]["stirrel.pin"], 200, 50, 200,
                        CONFIG[CHID]["stirrel.pin"], 200, 500, 0;
                        log = false
                    )
                    stirrel_last_time = time()
                    sleep(0.5) # relax
                end

                # read sensors 1
                @time pkg1 = send_csvcmd(sp, 
                    "INO", "PULSE-IN", 
                    CONFIG[CHID]["led1.pin"], 100;
                    log = false
                )
                isempty(pkg1["done_ack"]) && continue
                val1 = parse(Int, pkg1["responses"][0]["data"][2])

                # read sensors 2
                @time pkg2 = send_csvcmd(sp, 
                    "INO", "PULSE-IN", 
                    CONFIG[CHID]["led2.pin"], 100;
                    log = false
                )
                isempty(pkg2["done_ack"]) && continue
                val2 = parse(Int, pkg2["responses"][0]["data"][2])

                # laser off
                @time send_csvcmd(sp, 
                    "INO", "DIGITAL-WRITE", 
                    CONFIG[CHID]["laser.pin"], 0;
                    log = false
                )
                
                # push
                push!(LED1_VALS, val1)
                push!(LED2_VALS, val2)
                push!(LASER_PWMS, laser_pwm)

                iter_count += 1
                iter_count < iter_max || break

                # plot
                _do_plot_flag = time() - plot_last_time > plot_frec
                _do_plot_flag = _do_plot_flag && isinteractive()
                _do_plot_flag && _do_plot()
                
            end # for CHID
        end # loop

        # write
        dir = joinpath(@__DIR__, "MILK")
        mkpath(dir)
        for CHID in CHIDs
            CONC = CONC_DICT[CHID]
            LED1_VALS = get!(LED1_DICT, CHID, Float64[])
            LED2_VALS = get!(LED2_DICT, CHID, Float64[])
            LASER_PWMS = get!(LASER_DICT, CHID, Int[])

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
        end

    catch err; 
        err isa InterruptException || rethrow(err)
        @error err
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# # PULSESES
# # stirrel       D8
# # pump          D12
# let
#     # send_csvcmd(sp, "INO", "ANALOG-PULSE", CONFIG[CHID]["stirrel.pin"], 250, 0, 5)
#     send_csvcmd(sp, "INO", "ANALOG-PULSE", 
#         PUMP_PWMPIN, 
#         255, # POWER 
#         0, 
#         1    # PULSE DURATION (ms)
#     )
#     nothing
# end