function [data] = StackConditionData(condition_table,x,buffer_beginning,buffer_ending,verbose)
%STACKCONDITIONDATA Summary of this function goes here
%   Detailed explanation goes here
    data = [];
    
    for n = 1:size(condition_table,1)
        start = condition_table.norm_PE2(n)-buffer_beginning;
        stop = condition_table.norm_PE3(n)+buffer_ending;
        %added the try catch because very occasionally there is a variable
        %that is just one too short or too long. Probably an error in the
        %meta_table, just leave them out. 
        try
            if verbose==true
                disp(stop - start)
            end
            
            data = [data;x(start:stop)];
        catch
        end

    end
end

