binopcodes = Dict([1 => +, 2 => *, 7 => <, 8 => ==])

using DataStructures

"""
    p13(input; <keyword arguments>)
# Arguments
- `input`: the input array, or input Dict
- `ind`: the starting index (starts from 0,  not 1, due to conversion into a Dict)
- `relbase`: the base for mode 2, i.e. relative mode
- `infinitemode`: a Boolean flag which tells the program to keep printing numbers whenever it sees a 4 (output) instruction, as many times as needed, and only stop when 99 is encountered. Otherwise output the value when 4 is encountered.
- `invals`: an array of the input vals to the program
"""
function intcomp(input; ind=0, relbase=0, infinitemode=false, invals=[0])
    if typeof(input) == Array{Int64,1}
        inputcopy = Dict(0:length(input)-1 .=> input) |> d -> DefaultDict(0, d)
    else
        inputcopy = copy(input)
    end
    
    incounter, lastout, totalins = 1, 0, 0 # totalins: Just to see how many instructions are eventually run - not really needed
    outs = [] # In infinite mode, collect all the outputs
    
    while inputcopy[ind] != 99
        totalins += 1
        ins = inputcopy[ind]
        op = ins % 100
        
        mode1 = (log10(ins) > 2) ? parse(Int, string(ins)[end-2]) : 0
        mode2 = (log10(ins) > 3) ? parse(Int, string(ins)[end-3]) : 0
        mode3 = (log10(ins) > 4) ? parse(Int, string(ins)[end-4]) : 0
        
        op in [3,4,9] && (nparams = 1)
        op in [5,6] && (nparams = 2)
        op in [1,2,7,8] && (nparams = 3)
        
        param1 = (mode1 == 0) ? inputcopy[ind+1] : (mode1 == 1) ? ind+1 : inputcopy[ind+1]+relbase
        nparams > 1 && (param2 = (mode2 == 0) ? inputcopy[ind+2] : (mode2 == 1) ? ind+2 : inputcopy[ind+2]+relbase)
        nparams > 2 && (param3 = (mode3 == 0) ? inputcopy[ind+3] : (mode3 == 1) ? ind+3 : inputcopy[ind+3]+relbase)
        
        #println("ins: $ins, ind: $ind, param1 = $(inputcopy[ind+1]), param2 = $(inputcopy[ind+2]), param3 = $(inputcopy[ind+3])")
        
        op in [1,2,7,8] && ( inputcopy[param3] = binopcodes[op](inputcopy[param1], inputcopy[param2]) )
        
        if op == 3
            if length(invals) < incounter
                return Dict(:out => outs, :prog => inputcopy, :ind => ind, # Have to restart at same place 
                    :relbase => relbase, :totalins => totalins)
            else
                inputcopy[param1] = invals[incounter]
                incounter += 1
            end
        elseif op == 4
            lastout = inputcopy[param1]
            push!(outs, lastout)
            !infinitemode && return Dict(:out => outs, :prog => inputcopy, :ind => ind+nparams+1, 
                                :relbase => relbase, :totalins => totalins)
        elseif op == 5
            ind = (inputcopy[param1] ≠ 0) ? inputcopy[param2] : ind+3
        elseif op == 6
            ind = (inputcopy[param1] == 0) ? inputcopy[param2] : ind+3
        elseif op == 9 
            (relbase += inputcopy[param1])
        end
        
        if !(op in [5,6]) && inputcopy[ind] == ins #In case of jump, no need to do anything. Otherwise check if the execution has changed the instruction at pointer
            ind += (nparams + 1)
        end
    end
    return Dict(:out => outs, :prog => inputcopy, :ind => -1, # Changed :ind to -1 to indicate program finished
        :relbase => relbase, :totalins => totalins)
end