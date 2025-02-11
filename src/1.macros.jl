## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Utils
macro _handle_err(ex)
    quote
        try; $(esc(ex))
        catch err
            rethrow(err)
            err isa InterruptException && rethrow(err)
            print(sprint(showerror, err, catch_backtrace()))
            @error err
        end
    end
end
