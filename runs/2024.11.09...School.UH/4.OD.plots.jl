@time begin
    using CairoMakie
    using Serialization
    using Dates
    using CSCReactor_jlOs
    using CSCReactor_DevRuns
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# TODO: 
# - OD plots
# - Laser/led response plots
# - Pump plots
#   - Accumulatives
#   - Windowed rate

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# merge
let
    log_dir = joinpath(@__DIR__, "logs")
    @time global LOGS = merged_logs(log_dir)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Utils
function _is_match(reg::Regex, txt)
    m = match(reg, txt)
    return !isnothing(m)
end

function _hours(dt)
    DateTime(Dates.format(dt, "HH:MM:SS"), "HH:MM:SS")
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    _obj = Dict(
        "led1.cmt" => [],
        "led1.time" => [],
        "led1.val" => [],
        "led2.time" => [],
        "led2.val" => [],
        "led2.cmt" => [],
        "laser.pwm" => [],
        "pump.media.in.time" => [],
    )
    global OD_POOL = Dict(
        "CH3" => deepcopy(_obj),
        "CH5" => deepcopy(_obj),
    )

    val0 = 10000
    sorted_foreach(LOGS) do dt_str, dat
        dt = DateTime(dt_str)

        haskey(dat, "log.cmt") || return :continue
        cmt = dat["log.cmt"]
        haskey(dat, "responses") || return :continue
        haskey(dat, "echo") || return :continue

        # Filter pwn
        if contains(cmt, ".laser-on.")
            if _is_match(r"CH3:.*\.laser-on", cmt)
                pwm = parse(Int, dat["echo"]["tokens"][4])
                push!(OD_POOL["CH3"]["laser.pwm"], pwm)
            elseif _is_match(r"CH5:.*\.laser-on", cmt)
                pwm = parse(Int, dat["echo"]["tokens"][4])
                push!(OD_POOL["CH5"]["laser.pwm"], pwm)
            end
        end
        
        
        if contains(cmt, "pump.medium.in")
            if _is_match(r"CH5:.*", cmt)
                push!(OD_POOL["CH5"]["pump.media.in.time"], dt)
            end
            if _is_match(r"CH3:.*", cmt)
                push!(OD_POOL["CH3"]["pump.media.in.time"], dt)
            end
        end
        
        if contains(cmt, ".pulse-in.")
            if _is_match(r"CH5:.*\.pulse-in.led1", cmt)
                val = parse(Int, dat["responses"][0]["data"][2])
                push!(OD_POOL["CH5"]["led1.val"], val)
                push!(OD_POOL["CH5"]["led1.time"], dt)
                push!(OD_POOL["CH5"]["led1.cmt"], cmt)
            end
            if _is_match(r"CH5:.*\.pulse-in.led2", cmt)
                val = parse(Int, dat["responses"][0]["data"][2])
                push!(OD_POOL["CH5"]["led2.val"], val)
                push!(OD_POOL["CH5"]["led2.time"], dt)
                push!(OD_POOL["CH5"]["led2.cmt"], cmt)
            end
            if _is_match(r"CH3:.*\.pulse-in.led1", cmt)
                val = parse(Int, dat["responses"][0]["data"][2])
                push!(OD_POOL["CH3"]["led1.val"], val)
                push!(OD_POOL["CH3"]["led1.time"], dt)
                push!(OD_POOL["CH3"]["led1.cmt"], cmt)
            end
            if _is_match(r"CH3:.*\.pulse-in.led2", cmt)
                val = parse(Int, dat["responses"][0]["data"][2])
                push!(OD_POOL["CH3"]["led2.val"], val)
                push!(OD_POOL["CH3"]["led2.time"], dt)
                push!(OD_POOL["CH3"]["led2.cmt"], cmt)
            end
            return :continue
        end
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Align
let
    for (k, ser) in OD_POOL["CH5"]
        k == "laser.pwm" && continue
        k == "pump.media.in.time" && continue
        k == "led2.val" && continue
        t1 = 24420
        t2 = t1 + 1
        OD_POOL["CH5"][k] = [ser[1:t1]; ser[t2+1:end]]
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# TODO: 
# write
let
    # OD
    # for CHID in ["CH5"]
    for CHID in ["CH3", "CH5"]

        dat0 = OD_POOL[CHID]
        cmt = dat0["led1.cmt"]
        timetag = dat0["led1.time"]
        val1 = dat0["led1.val"]
        val2 = dat0["led2.val"]
        
        # Nt = length(timetag)
        # @show Nt
        # N1 = length(val1)
        # @show N1
        # N2 = length(val2)
        # @show N2
        # N = min(N1, N2, Nt)

        # fil = findall(val1 .> 000 .&& val1 .< 1500)

        fn = joinpath("data", string(CHID, ".OD.all.csv"))
        rm(fn; force = true)
        mkpath(dirname(fn))
        N = length(timetag)
        open(fn, "w") do io
            write(io,
                "time, control_led, measurred_led, comment"
            )
            for i in 1:N
                _cmt = replace(cmt[i], ".pulse-in.led1" => "")
                write(io, string(
                    timetag[i], ",", 
                    val1[i], ",", 
                    val2[i], ",", 
                    _cmt, "\n"
                ))     
            end
        end
        @show fn
    end

    # PUMP.IN
    for CHID in ["CH3", "CH5"]
        global dat0 = OD_POOL[CHID]
        timetag = dat0["pump.media.in.time"]

        # fil = findall(val1 .> 000 .&& val1 .< 1500)

        fn = joinpath("data", string(CHID, ".media.in.all.csv"))
        rm(fn; force = true)
        mkpath(dirname(fn))
        open(fn, "w") do io
            write(io,
                "pulse.time"
            )
            for i in eachindex(timetag)
                write(io, string(
                    timetag[i], "\n"
                ))     
            end
        end
        @show fn
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Plts
let
    f = Figure(; size = (500,800))
    
    for (i, CHID) in enumerate(["CH3", "CH5"])
        
        timetag = OD_POOL[CHID]["led1.time"]
        val1 = float.(OD_POOL[CHID]["led1.val"])
        val2 = OD_POOL[CHID]["led2.val"]
        
        N = length(timetag)
        
        # align
        # if CHID == "CH5"
        #     t1 = 24420
        #     t2 = t1 + 1
        #     timetag = [timetag[1:t1]; timetag[t2+1:end]]
        #     val1 = [val1[1:t1]; val1[t2+1:end]]
        #     val2 = [val2[1:t1]; val2[t2:end]]
        #     N = length(timetag)
        # end
        
        # # trim
        # @show Nt = length(timetag)
        # @show N1 = length(val1)
        # @show N2 = length(val2)
        # N = min(N1, N2, Nt)

        # timetag = timetag[1:N]
        # val1 = val1[1:N]
        # val2 = val2[1:N]

        # filter
        fil = findall(val1 .> 1000 .&& val1 .< 2500)
        timetag = timetag[fil]
        val1 = val1[fil]
        val2 = val2[fil]

        N = length(timetag)
        
        # window
        @show N
        win = floor(Int, N * 0.4):N
        xs = timetag[win]
        led1 = val1[win]
        led2 = val2[win]
        N = length(timetag)
        
        ax = Axis(f[i, 1]; 
            title = CHID,
            xlabel = "time",
            ylabel = "control/culture", 
            xticklabelrotation=45.0,
            # limits = (nothing, nothing, 0.8, 1.0)
        )
        scatter!(ax, 
            xs,
            # _hours.(xs),
            # xs .- first(xs), 
            led1 ./ led2,
            alpha = 0.5
        )
    end
    f
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    tts = OD_POOL["CH3"]["pump.media.in.time"]
    _diff = diff(tts)
    _diff = getfield.(_diff, :value)
    # _diff = _diff[600:1000]
    f = Figure()
    ax = Axis(f[1,1]; 
        xlabel = "time",
        ylabel = "T [secs]",
        limits = (nothing, nothing, 0, 30)
    )

    scatter!(ax, tts[1:end - 1], _diff / 1000)
    f
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    f = Figure()
    ax = Axis(f[1,1])

    CHID = "CH3"
    timetag = OD_POOL[CHID]["led1.time"]
    val1 = OD_POOL[CHID]["led1.val"]
    val2 = OD_POOL[CHID]["led2.val"]
    N1 = length(val1)
    N2 = length(val2)

    scatter!(ax, 
        val2,
        val1,
        alpha = 0.5
    )
    f
    
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# include("0.utils.jl")
# include("0.ch.configs.jl")
# ALL_CHS = [CH1, CH2, CH3, CH4, CH5]

# ## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# ch = CH1

# ## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# # load nad parse
# let
#     DIR = "/Users/Pereiro/.julia/dev/CSCReactor_DevRuns/runs/2024.07.01...Milano/logs"
#     global led1_date_vec = DateTime[]
#     global led1_read_vec = Int[]

#     global led2_date_vec = DateTime[]
#     global led2_read_vec = Int[]


#     for file in readdir(DIR; join = true)
#         # @show file
#         try
#             min_dat = deserialize(file)
#             for (date_str, dat0) in min_dat
#                 # filter log
#                 # "INO:PULSE-IN:29:100 -> control
#                 csvline = dat0["echo"]["csvline"]
#                 led1_pin = ch["led1.pin"]
#                 if startswith(csvline, "INO:PULSE-IN:$(led1_pin)")
#                     date = DateTime(date_str)
#                     led_read = parse(Int, dat0["responses"][0]["data"][2])
#                     push!(led1_date_vec, date)
#                     push!(led1_read_vec, led_read)
#                 end
#                 # "INO:PULSE-IN:33:100 -> vial
#                 csvline = dat0["echo"]["csvline"]
#                 led2_pin = ch["led2.pin"]
#                 if startswith(csvline, "INO:PULSE-IN:$(led2_pin)")
#                     date = DateTime(date_str)
#                     led_read = parse(Int, dat0["responses"][0]["data"][2])
#                     push!(led2_date_vec, date)
#                     push!(led2_read_vec, led_read)
#                 end
#             end
#         catch err
#             rm(file; force = true)
#         end
#     end

#     # align
#     sidx1 = sortperm(led1_date_vec)
#     sidx2 = sortperm(led2_date_vec)
#     _common = min(length(sidx1), length(sidx2))
#     sidx1 = first(sidx1, _common)
#     sidx2 = first(sidx2, _common)
#     led1_date_vec = led1_date_vec
#     led2_date_vec = led2_date_vec
#     led1_read_vec = led1_read_vec
#     led2_read_vec = led2_read_vec
#     nothing
# end

# ## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# function _hours(dt)
#     DateTime(Dates.format(dt, "HH:MM:SS"))
# end

# ## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# # plot
# let
#     f = Figure(;)
#     # Label(f[1:1, 1:2], 
#     #     halign = :center, 
#     #     fontsize = 24
#     # )

#     ax = Axis(f[1,1]; 
#         xlabel = "time", 
#         ylabel = "Transmittance (AU)",
#         limits = (nothing, nothing, 0, nothing),
#         xticklabelrotation=45.0
#     )
    
#     scatter!(ax, 
#         (led1_date_vec .- led1_date_vec[1]), led1_read_vec; 
#         label = "$(ch["ch.name"]).l1"
#     )
#     scatter!(ax, 
#         (led1_date_vec .- led1_date_vec[1]), led2_read_vec; 
#         label = "$(ch["ch.name"]).l2"
#     )
#     axislegend(ax, position = :lb)

#     ax = Axis(f[2,1]; 
#         xlabel = "time", 
#         ylabel = "OD (AU)",
#         # limits = (nothing, nothing, 0, nothing),
#         xticklabelrotation=45.0
#     )
#     scatter!(ax, (led2_date_vec .- led2_date_vec[1]), led1_read_vec ./ led2_read_vec; 
#         label = "l1/l2"
#     )
#     axislegend(ax, position = :lb)
#     f

#     fn = joinpath(@__DIR__, "plots", string(now(), ".png"))
#     mkpath(dirname(fn))
#     save(fn, f)
#     @show fn
#     f
    
# end