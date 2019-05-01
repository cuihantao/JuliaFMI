"""
Callback functions for logging and memory managment passed to FMU instance.
"""

include("FMI2Types.jl")
using Printf

@enum fmi2Status fmi2OK=0 fmi2Warning=1 fmi2Discard=2 fmi2Error=3 fmi2Fatal=4 fmi2Pending=5

# Callback logger for FMU
function fmi2CallbackLogger(componentEnvironment::Ptr{Cvoid},
                            instanceName::Cstring,
                            status::Cint,
                            category::Cstring,
                            message) :: Cvoid
    instanceName = unsafe_string(instanceName)
    category = unsafe_string(category)
    message = map(unsafe_string, message)
    @info "Logger: [$instanceName] [$status] [$category]: $message "
end


# Allocate with zeroes initialized memory
function fmi2AllocateMemory(nitems::Csize_t, size::Csize_t)
    ptr = Libc.calloc(nitems, size)
    @debug "Allocate Memory at $ptr."
    return ptr
end


# Free memory allocated with fmi2AllocateMemory
function fmi2FreeMemory(ptr::Ptr{Nothing})
    @debug "Freeing pointer $ptr."
    Libc.free(ptr)
end


"""
Helper functions
"""
function fmi2StatusToString(status::Real)
    if(fmi2OK)
        "fmi2OK"
    elseif(fmi2Warning)
        "fmi2Warning"
    elseif(fmi2Discard)
        "fmi2Discard"
    elseif(fmi2Error)
        "fmi2Error"
    elseif(fmi2Fatal)
        "fmi2Fatal"
    elseif(fmi2Pending)
        "fmi2Pending"
    else
        "Unknown fmi2Status"
    end
end
