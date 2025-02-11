# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# TODO: Move to SetupLoop.jl

# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# keep track of the time between tics
struct Ticker
    buffer::Dict{String, CircularBuffer{Float64}} # stores the time of tics
    elapsed::Dict{String, Float64}                # 
    buffsize::Int
    Ticker(buffsize = 30) = new(Dict(), Dict(), buffsize)
end

# --.- - . .-- .-. -. -. -- - -. . .- - - .- .-.--
# Try to enfore a frequency ;)
# - it has a feedback loop for trying to be around the frequency
struct Frequensor
    ticker::Ticker
    delays::Dict{String, Float64}
    Frequensor(buffsize = 30) = new(Ticker(buffsize), Dict())
end

