function [x_filtered] = Filter(x,verbose)
%FILTER Summary of this function goes here
%   Detailed explanation goes here
    % Eye tracker has a sample rate of 120Hz, but the analog output is 1000Hz.
    analog_freq = 1000; %hz
    eye_tracker_freq = 120; %hz

    freq_diff = analog_freq / eye_tracker_freq;
    % to smooth the signal we're going to use a Savitzky-Golay filter, which
    % needs an uneven frame lenght as input.

    framelen = round(freq_diff) +1;
    order = 2; %we're going to use second order sgolay filt.

    x_sgol = sgolayfilt(x, order, framelen);
    
    if verbose==true
        figure; plot(x); hold on; plot(x_sgol);
    end
    %The also apply a moving mean to the signal with windowlengt 30ms is safe
    %to still see abrupt eye movements, (saccades?) but filter out the
    %background noise. 

    framelen_movmean = 30;
    x_filtered = movmean(x_sgol,framelen_movmean);
    
      if verbose==true
        figure; plot(x); hold on; plot(x_filtered);
      end

end

