# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# Arduino
SP = nothing

function find_port()
    plist = LibSerialPort.get_port_list()
    for port in plist
        # Add here more heuristics
        port == "/dev/cu.usbmodem14101" && return port
        port == "/dev/cu.usbmodem14201" && return port
    end
    error("Port not found, ports: ", plist)
end

# connect ino
function ch_try_connect(CONFIG)
    isnothing(SP) || return nothing
    portname = find_port()
    baudrate = get(CONFIG, "ino.baudrate", 19200)
    @show portname
    @show baudrate
    global SP = LibSerialPort.open(portname, baudrate)
    return SP
end


# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# Ticker 

_ticker_buffer_cl(buffsize) = () -> CircularBuffer{Float64}(buffsize)

ticsbuffer(t::Ticker, k::String) = t.buffer[k]
ticsbuffer!(t::Ticker, k::String) = get!(_ticker_buffer_cl(t.buffsize), t.buffer, k)

# returns result of f(_elp)
function tic!(f::Function, t::Ticker, k::String)
    _now = time()
    _tics = ticsbuffer!(t, k)
    _elp = isempty(_tics) ? 0.0 : _now - last(_tics) 
    ret = f(_elp)
    push!(_tics, _now)
    return ret
end

# returns _elp
tic!(t::Ticker, k::String) = tic!(identity, t, k)

function tic(t::Ticker, k::String)
    tics = ticsbuffer(t, k)
    return isempty(tics) ? 0.0 : last(tics)
end

# Run the function  if the event happend
function onelapsed!(fun::Function, t::Ticker, k::String, target::Float64)
    # up elapsed
    _elp = get!(t.elapsed, k, 0.0)
    _elp += tic!(t, k)
    t.elapsed[k] = _elp

    _elp < target && return nothing 
    ret = fun(_elp)

    t.elapsed[k] = 0
    return ret
end

# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# Frequensor

# return elps
tic!(f::Frequensor, k::String) = tic!(identity, f.ticker, k)

delays(f::Frequensor, k) = get!(f.delays, k, 0)
delays!(f, k, d) = setindex!(f.delays, d, k)

ticsbuffer(f::Frequensor, k::String) = ticsbuffer(f.ticker, k)
ticsbuffer!(f::Frequensor, k::String) = ticsbuffer!(f.ticker, k)

onelapsed!(fun::Function, f::Frequensor, k::String, target::Float64) = 
        onelapsed!(fun, f.ticker, k, target)

# Delay as much time required for enforcing the given frequency/period
function forceperiod!(delayfun::Function, f::Frequensor, k::String, 
        tperiod; rate = (tperiod * 0.1)
    )
    msdperiod = tic!(f, k) # register and get elapsed time since previous
    iszero(msdperiod) && return # ignore
    # mod delay
    err = tperiod - msdperiod
    dt = err * rate # get correction
    d = delays(f, k) # get current delay
    d += dt
    d = d > 0 ? d : zero(d)
    # @show d
    delays!(f, k, d) # up new delay
    delayfun(d)
end

function forcefrec!(delay::Function, f::Frequensor, k::String, tfrec; 
        rate = (tfrec * 0.1)
    )
    forceperiod!(delay, f, k, inv(tfrec); rate = inv(rate))
end

function msd_periods(f::Frequensor, k)
    tics = ticsbuffer(f, k)
    n = length(tics)
    n < 1 && return 0.0
    pers = diff(tics)
    return sum(pers) / (n - 1)
end

function msd_frequency(f::Frequensor, k)
    per = msd_periods(f, k)
    iszero(per) && return 0.0
    return inv(per)
end

