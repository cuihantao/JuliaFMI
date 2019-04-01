using Trajectories
using CSV
using DataFrames


"""
    csvFilesEqual(csvFile1Path::String, csvFile1Path::String, epsilon::Real)

Checks if trajectories of variables in two CSV files are equal.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String,
    epsilon::Real)

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)

    # Compare trajectories for all variables
    allVars = setdiff(names(csvData1), [:time])
    return csvCompareVars(csvData1, csvData2, allVars, epsilon)
end

"""
    csvFilesEqual(csvFile1Path::String, csvFile2Path::String, checkVars::Array{String,1}, epsilon::Real)

Checks if trajectories of variables `checkVars` in two CSV files are equal.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String,
    checkVars::Array{String,1}, epsilon::Real)

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)

    # Compare trajectories for specified variables
    return csvCompareVars(csvData1, csvData2, checkVars, epsilon)
end


"""
    csvCompareVars(csvData1:::DataFrames.DataFrame, csvData2:::DataFrames.DataFrame, checkVars::Array{Symbol,1}, epsilon::Real)

Helper function to check if trajectories of variables `checkVars` in two
DataFrames are equal.
"""
function csvCompareVars(csvData1::DataFrames.DataFrame,
    csvData2::DataFrames.DataFrame, checkVars::Array{Symbol,1},
    epsilon::Real)

    # rename variables like der(x) to der_x_
    replaceNames!(csvData1)
    replaceNames!(csvData2)
    newNames = Array{String}(undef, length(checkVars))
    for (i,name) in enumerate(checkVars)
        newNames[i] = String(checkVars[i])
        newNames[i] = replace(newNames[i], "(" => "_")
        newNames[i] = replace(newNames[i], ")" => "_")
    end
    checkVars = Symbol.(newNames)

    # Check if comparable
    if unique(names(csvData1)) != names(csvData1)
        error("Got duplicate names in csv file. Can't compare.")
    end

    # Compare trajectories for each specified variables
    for varName in checkVars
        trajectory1 = trajectory(csvData1.time, csvData1[Symbol(varName)])
        trajectory2 = trajectory(csvData2.time, csvData2[Symbol(varName)])
        if !trajectoriesEqual(trajectory1::Trajectory, trajectory2::Trajectory, epsilon)
            return false
        end
    end

    # TODO unload?

    return true
end

"""
    function trajectoriesEqual(trajectory1::Trajectory, trajectory2::Trajectory, epsilon)

Compares if two trajectories are equal by linear interpolation and comparing to
definded error ϵ.
"""
function trajectoriesEqual(trajectory1::Trajectory, trajectory2::Trajectory,
    epsilon::Real)

    time1, values1 = Pair(trajectory1)
    time2, values2 = Pair(trajectory2)

    if abs(time1[1]-time2[1])>1e-8 || abs(time1[end]-time2[end])>1e-8
        error("Compared trajectories have to different start and/or stop time.");
    end

    for (i,t) in enumerate(time1)
        if abs(interpolate(Linear(), trajectory2, t) - values1[i]) > epsilon
            return false
        end
    end

    return true
end


"""

Helper function to replace brackets in DataFrames names.
"""
function replaceNames!(data::DataFrames.DataFrame)

    newNames = Array{String}(undef, size(data,2))
    for (i,name) in enumerate(names(data))
        newNames[i] = String(names(data)[i])
        newNames[i] = replace(newNames[i], "(" => "_")
        newNames[i] = replace(newNames[i], ")" => "_")
    end

    names!(data, Symbol.(newNames))
end
