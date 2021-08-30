function [data_normalized] = NormalizeData(data,buffer_beginning)
%NORMALIZEDATA Summary of this function goes here
%   Detailed explanation goes here
    for n = 1:size(data,1)
    curmean = nanmean(data(n,1:buffer_beginning));

    delta = curmean;% - overall_mean;
    data(n,:) = data(n,:) - delta;
    
    data_normalized = data;

    end
end

