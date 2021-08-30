function [x_db, y_db, pupil_db] = Deblink(x,y,pupil,verbose)
%DEBLINK Summary of this function goes here
%   Detailed explanation goes here
% Blink duration is Rhesus Macaques is aproximately 200ms on average(Tada et al.
    % 2013 - PLoS ONE)
    % We find the peak of the differential of the X data. Whenever there is
    % a blink the eye tracker freaks out and shoots to the sides, causing a
    % big spike in eye tracker movement. -> we can use this to filter out
    % the blinks.
    
    xdiff = diff(x);
    [pks, locs] = findpeaks(xdiff,'MinPeakHeight',0.3);
    
    
    %For each location where ther is a blink, convert a certain blinkwindow(ms) before and
    %after to nans
    blinkwindow = 400; %ms - 200ms blink duration with 100ms extra padding before and after removed. 
    
    x_db = x; %deblinked
    
    %turn x data inside window tot nans
    for n = locs(locs> blinkwindow)
        x_db(n-blinkwindow/2:n+blinkwindow/2) = nan;
    end
    
    % filter out other weird data. If data is outside 3std of the in the normal and diff data then
    % drop it. For now I have chosen not to do super extreme dropping of
    % data because it might occur that halfway through the data that the
    % system refixates for some reason, meaning that your new fixation point
    % is somewhat to the left or right and you don want to delete that of course.
    % While looking at the individual condition windows when plotting the data 
    % it will be correctd to start around 0 anyway so it shouldn't
    % matter too much. 
    
    meanx = nanmean(x_db); %calculate mean of normal signal
    meanxdiff = nanmean(xdiff); %calculate mean of first differential of signal
    
    stdx = nanstd(x_db); %std for normal signal
    stdxdiff = nanstd(xdiff); %std for first diff of signal
    
    upper = meanx + 3*stdx; %3std above and below mean set as thresholds.
    upperdiff = meanxdiff + 3*stdxdiff;
    lower = meanx - 3*stdx;
    lowerdiff = meanxdiff - 3*stdxdiff;
    
    %find locations of data that are outside of 3std. 
    x_upper = find(x_db > upper); 
    xdiff_upper = find(xdiff > upperdiff);
    x_lower = find(x_db < lower);
    x_diff_lower = find(xdiff < lowerdiff);
    
    x_correction = unique([x_upper, xdiff_upper, x_lower, x_diff_lower]); %add all the indices together and take only the unique ones (so you don have doubles)
    %How many ms around the datapoint that is outside the 3std range do you
    %want to remove? 
    correction_window = 50; %ms
    
    for n = x_correction(x_correction > correction_window/2) % check that its bigger then half the correction window els ethe index will be negative.
        x_db(n-correction_window/2:n+correction_window/2) = nan;
    end
    %plot result if verbose is true
    if verbose == true
        figure;
        plot(x); hold on; plot(x_db)
    end
    %make everything that's a nan in the xdata also a nan in the y and
    %pupil data
    y_db = y;
    y_db(isnan(x_db)) = nan;
    
    pupil_db = pupil;
    pupil_db(isnan(x_db)) = nan;
end

