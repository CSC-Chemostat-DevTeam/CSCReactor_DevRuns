## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Setup
function ch_set_pin_modes!(ch::Dict)
    ch["run.dry"] && return
    chname = get(ch, "ch.name", "?")
    for (pinid, mode) in [
            ("pump.air.in.pin", OUTPUT),
            ("pump.medium.in.pin", OUTPUT),
            ("stirrel.pin", OUTPUT),
            ("pump.medium.out.pin", OUTPUT),
            ("pump.medium.out.pin", OUTPUT),
            ("laser.pin", OUTPUT),
            ("led1.pin", INPUT_PULLUP),
            ("led2.pin", INPUT_PULLUP),
        ]
        pin = ch[pinid]
        isnothing(pin) && continue
        isempty(pin) && continue
        # $INO:PIN-MODE:PIN:MODE%
        logcmt = string(chname, ".pin-mode.pin.", pinid)
        res = send_csvcmd(SP, "INO", "PIN-MODE", pin, mode; logcmt)
        @assert ch_success(res)
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# OD System
function _meassure_OD(ch::Dict; v = true)
    get(ch, "laser.enable", true) || return
    chname = get(ch, "ch.name", "?")

    if ch["run.dry"] 
        v && @info("READING OD [DRY]", 
            ch = chname,
        )
        sleep(0.1 + 0.1 + 0.1 + 0.1)
        return
    end
    
    # turn on laser (two for savety)
    laser_pwm = rand(20:10:ch["laser.pwm.max"])
    for it in 1:2
        logcmt = string(chname, ".laser-on.attempt$it")
        send_csvcmd(SP, "INO", "ANALOG-WRITE", 
            ch["laser.pin"], laser_pwm; 
            logcmt
        ) 
    end
    sleep(get(ch, "laser.estabilization.time", 0.05))

    # meassure leds
    ## led1 
    logcmt = string(chname, ".pulse-in.led1")
    msr_time_led1 = get(ch, "led1.meassure.time", 100) # ms
    # $INO:PULSE-IN:PIN:TIME%
    res1 = send_csvcmd(SP, "INO", "PULSE-IN", ch["led1.pin"], msr_time_led1; logcmt)
    
    ## led2 
    logcmt = string(chname, ".pulse-in.led2")
    msr_time_led2 = get(ch, "led2.meassure.time", 100) # ms
    # $INO:PULSE-IN:PIN:TIME%
    res2 = send_csvcmd(SP, "INO", "PULSE-IN", ch["led2.pin"], msr_time_led2; logcmt)

    # turn off laser
    for it in 1:2
        logcmt = string(chname, ".laser-off.attempt$it")
        send_csvcmd(SP, "INO", "ANALOG-WRITE", 
            ch["laser.pin"], 0; 
            logcmt
        )
    end

    # Info
    val1 = ch_success(res1) ? tryparse(Int, res1["responses"][0]["data"][2]) : nothing
    val2 = ch_success(res2) ? tryparse(Int, res2["responses"][0]["data"][2]) : nothing
    v && @info("OD.MEASSURED", 
        ch = chname,
        laser_pwm,
        msr_time_led1, 
        msr_time_led2, 
        val1, val2
    )

    return nothing
end

function meassure_OD(ch; v = true)
    @_handle_err let
        _meassure_OD(ch; v)
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# pump.air
function ch_air_pulse(ch; v = true)
    ch_periodic_s_pulse(ch, "pump.air"; v)
end

# pump.medium.out
function ch_media_out_pulse(ch; v = true)
    ch_periodic_s_pulse(ch, "pump.medium.out"; v)
end

# pump.medium.in
function ch_media_in_pulse(ch; v = true)
    ch_periodic_s_pulse(ch, "pump.medium.in"; v)
end

# stirrel
function ch_stirrel_pulse(ch; v = true)
    ch_periodic_s_pulse(ch, "stirrel"; v)
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Compute the pulse period from standard Chemostat parameters
# function ch_compute_pulse_period!(ch)
function ch_compute_pump_medium_in_pulse_period!(ch)
    _abs_flux = ch["dilution.target"] * ch["vial.working_volume"] # mL / h
    _abs_flux = _abs_flux / ch["pump.medium.in.per_pulse_volume"] # pulses / h
    _pulse_period = 1 / _abs_flux # h
    _pulse_period = _pulse_period * 60 * 60 # second
    ch["pump.medium.in.pulse_period.target"] = _pulse_period
    return _pulse_period
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Base
function __ch_ds_pulse(ch::Dict, sysid::String; deft_dur = 100, v = true)
    get(ch, "$sysid.enable", true) || return
    chname = get(ch, "ch.name", "?")

    ptime = get!(ch, "$sysid.pulse_duration", deft_dur) # ms
    pin = get(ch, "$sysid.pin", nothing)
    if !get(ch, "run.dry", false)
        isnothing(pin) && return
        logcmt = string(chname, ".ds-pulse.", sysid)
        # $INO:DIGITAL-S-PULSE:PIN1:VAL01:TIME1:VAL11...%
        res = send_csvcmd(SP, "INO", "DIGITAL-S-PULSE", 
            pin, 1, ptime, 0;
            logcmt
        )
        @assert ch_success(res)
    end

    v && @info(uppercase(sysid), 
        ch = get(ch, "ch.name", "?"),
        pin, ptime
    )
end

function ch_ds_pulse(ch::Dict, sysid::String; deft_dur = 100, v = true)
    @_handle_err let
        __ch_ds_pulse(ch, sysid; deft_dur, v)
    end
end

function __ch_as_pulse(ch::Dict, sysid::String, pwm0, dur, pwm1)
    chname = get(ch, "ch.name", "?")
    pin = get(ch, "$sysid.pin", nothing)
    isnothing(pin) && return
    logcmt = string(chname, ".as-pulse.", sysid)
    # $INO:ANALOG-S-PULSE:PIN1:VAL01:TIME1:VAL11...%
    res = send_csvcmd(SP, "INO", "ANALOG-S-PULSE", 
        pin, pwm0, dur, pwm1;
        logcmt
    )
    @assert ch_success(res)
end

function _ch_as_pulse(ch::Dict, sysid::String; deft_dur = 100, deft_pwm = 255, v = true)
    get(ch, "$sysid.enable", true) || return
    chname = get(ch, "ch.name", "?")

    dur = get!(ch, "$sysid.pulse_duration", deft_dur) # ms
    pwm0 = get!(ch, "$sysid.pulse_pwm0", deft_pwm) # 0:255
    pin = get(ch, "$sysid.pin", nothing)
    if !get(ch, "run.dry", false)
        __ch_as_pulse(ch, sysid, pwm0, dur, 0)
    end

    v && @info(uppercase(sysid), 
        ch = chname,
        pin, dur, pwm0
    )
end

function ch_as_pulse(ch::Dict, sysid::String; deft_dur = 100, deft_pwm = 255, v = true)
    @_handle_err let
        _ch_as_pulse(ch, sysid; deft_dur, deft_pwm, v)
    end
end


function __ch_periodic_s_pulse(ch, sysid; v = true)
    
    get(ch, "$sysid.enable", true) || return

    # check period
    ticker = get!(ch, "ticker") do
        Ticker()
    end
    _tper = get!(ch, "$sysid.pulse_period.min", 0.0)::Float64 # secs
    onelapsed!(ticker, "$sysid.s.pulse", _tper) do _elp
        # pulse
        __ch_ds_pulse(ch, sysid; v = false)
        
        # info
        chname = get(ch, "ch.name", "?")
        v && @info(uppercase(sysid), 
            ch = chname,
            target_period = _tper,
            meassured_period = _elp
        )
    end
end

function ch_periodic_s_pulse(ch, sysid; v = true)
    @_handle_err let
        __ch_periodic_s_pulse(ch, sysid; v)
    end
end

function ch_success(res)
    haskey(res, "done_ack") || return false
    isempty(res["done_ack"]) && return false
    return true
end

