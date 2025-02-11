# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    folder = "/Volumes/NO NAME"
    _files = String[]
    for (root, dirs, files) in walkdir(folder)
        # println("Directories in $root")
        # for dir in dirs
        #     println(joinpath(root, dir)) # path to directories
        # end
        for file in files
            path = joinpath(root, file)
            push!(_files, path)
        end
    end

    out_file = joinpath(@__DIR__, "out.txt")
    @show out_file
    open(out_file, "w") do io
        for file in _files
            file = replace(file, "/Volumes/NO NAME/" => "/")
            println(io, file)
        end
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
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
    for it in 1:20
        # for CHID in CHIDs
        #     # @show CHID
        #     ch_as_pulse(CONFIG[CHID], "pump.medium.in"; v = true)
        # end
        # for CHID in CHIDs
        #     ch_as_pulse(CONFIG[CHID], "pump.medium.out"; v = true)
        #     ch_as_pulse(CONFIG[CHID], "pump.medium.out"; v = true)
        # end
        # for CHID in CHIDs
        #     ch_as_pulse(CONFIG[CHID], "pump.air.in"; v = true)
        # end
        for CHID in CHIDs
            ch_ds_pulse(CONFIG[CHID], "stirrel"; v = true)
            # ch_as_pulse(CONFIG[CHID], "stirrel"; v = true)
            break
        end
        sleep(0.2)
    end
    println()
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
