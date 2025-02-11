## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function merged_logs(log_dir = joinpath(@__DIR__, "logs"))
    _logs = Dict{String, Dict}()
    files_ = readdir(log_dir; join = true)
    N = length(files_)
    for (i, fn) in enumerate(files_)
        iszero(mod(i, N ÷ 10)) && println(i, "/", N)
        try; 
            dat0 = deserialize(fn)
            merge!(_logs, dat0)
        catch err; 
            @error err
        end
    end
    return _logs
end

function sorted_foreach(f::Function, logs)
    _dts = collect(keys(logs))
    sort!(_dts; rev = false)
    for dt in _dts
        dat = logs[dt]
        f(dt, dat) === :break && break
    end
end
sorted_foreach(f::Function) = sorted_foreach(f, merged_logs())

