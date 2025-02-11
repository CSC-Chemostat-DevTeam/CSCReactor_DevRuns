using CSCReactor_jlOs

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# INCLUDES
include("ch.pin.layout.jl")
include("ch1.config.jl")
include("ch2.config.jl")
include("ch3.config.jl")
include("ch4.config.jl")
include("ch5.config.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# CONFIG
CONFIG = Dict(
    # Arduino
    "ino.baudrate" => 19200,

    # Chemostats
    "CH1" => CH1, 
    "CH2" => CH2, 
    "CH3" => CH3, 
    "CH4" => CH4,
    "CH5" => CH5,
)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Enable CHs
empty!(CH1)
empty!(CH2)
empty!(CH4)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# LOG
logdir!(abspath(joinpath(@__DIR__, "..", "logs")))

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
nothing