## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# #TODO Make SetupLoop.jl package for managing sketch-like applications
#   - Add Ticker/Frequensor
#   - Event registration
#   - Multi-treaded update loop
#       - Maybe divide it on main thread/helpers thread

module CSCReactor_DevRuns

    using MassExport
    using DataStructures
    using Serialization
    using CSCReactor_jlOs
    using CSCReactor_jlOs: LibSerialPort

    #! include .
    include("0.types.jl")
    include("1.macros.jl")
    include("ch.base.jl")
    include("log.base.jl")
    include("sim.base.jl")

    @exportall_non_underscore()

end