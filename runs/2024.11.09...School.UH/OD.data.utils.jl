function _do_plot()

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
