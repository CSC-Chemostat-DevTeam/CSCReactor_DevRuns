@time begin
    using CairoMakie
    using Serialization
    using Dates
    using CSCReactor_jlOs
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0.utils.jl")
include("0.ch.configs.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# TODO: 
# - OD plots
# - Laser/led response plots
# - Pump plots
#   - Accumulatives
#   - Windowed rate

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# 
let
    
end
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# 
let
    # hint = "INO:PULSE-IN:51:"
    # parse(Int, _dat["responses"][0]["data"][2])

    _sorted_foreach() do dt, dat
        csvline = dat["echo"]["csvline"]
        contains(csvline, hint) || return :continue
        global _dat = dat
        println(dt, "\t",  dat["echo"]["csvline"])
    end
end

# # ---.-.- ...- -- .--- . .- .-. . ..- .--.-
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