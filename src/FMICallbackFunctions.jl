"""
Callback functions for logging and memory managment passed to FMU instance.
"""

include("FMI2Types.jl")

# Macro to identify standard C library
macro libc()
    if Sys.iswindows()#
        return "msvcrt"
    else
        return "libc"
    end
end

# Macro to identify logger library
macro libLogger()
    if Sys.iswindows()
        return string(dirname(dirname(Base.source_path())),"\\bin\\win64\\logger.dll")
    elseif Sys.islinux()
        return string(dirname(dirname(Base.source_path())),"\\bin\\unix64\\logger.so")
    end
end

# Logger for error and information messages
function fmi2CallbackLogger(componentEnvironment,
    instanceName, status, category,
    message...)

    try
        println("[", string(status), "][", unsafe_string(category), "] ", unsafe_string(message))
    catch
        println("Error trying to log message from FMU!")
    end
end
const fmi2CallbacLogger_funcWrapC = @cfunction(fmi2CallbackLogger, Cvoid,
(Ptr{Cvoid}, Cstring, Cuint, Cstring, Tuple{Cstring}))

# Allocate with zeroes initialized memory
function fmi2AllocateMemory(nitems, size)
    print("Allocate Memory: ")
    ptr = ccall(("calloc", @libc), Ptr{Cvoid}, (Csize_t, Csize_t), nitems, size)
    println("Returned pointer $ptr.")
    return ptr
end
const fmi2AllocateMemory_funcWrapC = @cfunction(fmi2AllocateMemory, Ptr{Cvoid}, (Csize_t, Csize_t))


# Free memory allocated with fmi2AllocateMemory
function fmi2FreeMemory(ptr)
    println("Freeing pointer $ptr.")
    ccall(("free", @libc), Cvoid, (Ptr{Cvoid},), ptr)
end
const fmi2FreeMemory_funcWrapC = @cfunction(fmi2FreeMemory, Cvoid, (Ptr{Cvoid},))


# Pointers to functions provided by the environment to be used by the FMU
struct CallbackFunctions
    callbackLogger::Ptr{Nothing}
    allocateMemory::Ptr{Nothing}
    freeMemory::Ptr{Nothing}
    stepFinished::Ptr{Nothing}

    componentEnvironmendt::Ptr{Nothing}
end

# open shared library with logger function
libLoggerHandle = dlopen(@libLogger)
fmi2CallbacLogger_Cfunc = dlsym(libLoggerHandle, :logger)

const fmi2Functions = CallbackFunctions(
    fmi2CallbacLogger_funcWrapC,
    fmi2AllocateMemory_funcWrapC,
    fmi2FreeMemory_funcWrapC,
    C_NULL,
    C_NULL)



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