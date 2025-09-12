using CSCReactor_jlOs: _logfile

function _getpush!(dict, id, val, init)
    vec = get!(dict, id, init)
    push!(vec, val)
end

function _do_plot(
        CHID, CONC, LED1_VALS, LED2_VALS, LASER_PWMS,
    )
    isempty(LED1_VALS) && return
    isempty(LED2_VALS) && return
    isempty(LASER_PWMS) && return

    _size = 500
    f = Figure(; size = (1.3 * _size, 1.3 * _size))

    Label(f[2, :], string(
        "Ch: ", CHID, " ",
        "CONC: ", CONC,
    ), fontsize = 20)

    trim!(f.layout) 

    g = GridLayout(f[2, :]; width = _size, height = _size)
    
    limits = (nothing, nothing, 0, nothing)
    ax = Axis(g[1, 1]; limits, xlabel = "time", ylabel = "laser power", aspect = 1.0)
    scatter!(ax, eachindex(LASER_PWMS), LASER_PWMS; color = :red)
    
    ax = Axis(g[1, 2]; limits, xlabel = "time", ylabel = "led read", aspect = 1.0, )
    scatter!(ax, eachindex(LED1_VALS), LED1_VALS; color = :red)
    scatter!(ax, eachindex(LED2_VALS), LED2_VALS; color = :blue)
    
    ax = Axis(g[2, 1]; limits, xlabel = "led read", ylabel = "laser power", aspect = 1.0)
    scatter!(ax, LED1_VALS, LASER_PWMS; color = :red)
    scatter!(ax, LED2_VALS, LASER_PWMS; color = :blue)

    ax = Axis(g[2, 2]; limits, xlabel = "led1 read", ylabel = "led2 read", aspect = 1.0)
    scatter!(ax, LED1_VALS, LED2_VALS; color = :red)

    colgap!(g, 10)  
    rowgap!(g, 10)  
    trim!(f.layout) 

    # ax = Axis(g[2, 2]; limits, xlabel = "led1 read", ylabel = "led2 read", aspect = 1.0)
    # scatter!(ax, eachindex(LED1_VALS), log10.(LED1_VALS ./ LED2_VALS); 
    #     color = :red
    # )

    display(f)
end

function _do_write(;
        CONC, CHID, 
        LED1_VALS, LED2_VALS,
        LASER_PWMS,
        dir = joinpath(@__DIR__, "MILK")
    )
    mkpath(dir)
    fn = _logfile("C$CONC..."; dir, ext = ".csv")
    open(fn, "w") do io
        # header
        println(io, 
            join(string.([
                    "CHID", "CONC", "LED1_VALS", "LED2_VALS", "LASER_PWMS"
            ]), ";")
        )

        # dat
        iter_count = length(LASER_PWMS)
        for i in 1:iter_count
            println(io, 
                join(string.([
                    CHID, CONC, LED1_VALS[i], LED2_VALS[i], LASER_PWMS[i]
                ]), ";")
            )
        end
    end
end


function _do_plotv2()

    f = Figure(;size = (1000,1000))
    for (coli, CHID) in enumerate(CHIDs)

        LED1_VALS = get!(LED1_DICT, CHID, Float64[])
        LED2_VALS = get!(LED2_DICT, CHID, Float64[])
        LASER_PWMS = get!(LASER_DICT, CHID, Int[])
        CONC = CONC_DICT[CHID]
                        
        title = string(CHID)
        limits = (nothing, nothing, 0, nothing)
        ax = Axis(f[1, coli]; limits, title, ylabel = "laser power", aspect = 1.0)
        scatter!(ax, eachindex(LASER_PWMS), LASER_PWMS; color = :red)
        
        ax = Axis(f[2, coli]; limits, title, xlabel = "time", ylabel = "led read", aspect = 1.0)
        scatter!(ax, eachindex(LED1_VALS), LED1_VALS; color = :red)
        scatter!(ax, eachindex(LED2_VALS), LED2_VALS; color = :blue)
        
        ax = Axis(f[3, coli]; limits, title, xlabel = "led read", ylabel = "laser power", aspect = 1.0)
        scatter!(ax, LED1_VALS, LASER_PWMS; color = :red)
        scatter!(ax, LED2_VALS, LASER_PWMS; color = :blue)

        ax = Axis(f[4, coli]; limits, title, xlabel = "led1 read", ylabel = "led2 read", aspect = 1.0)
        scatter!(ax, LED1_VALS, LED2_VALS; color = :red)
    end

    display(f)
end

nothing