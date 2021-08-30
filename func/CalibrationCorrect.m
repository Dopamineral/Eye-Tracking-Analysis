function [x_cm, y_cm, x_px, y_px] = CalibrationCorrect(x,y, calibration)
%CALIBRATIONCORRECT Summary of this function goes here
%   Detailed explanation goes here
    screensize_px = [1400 1050]; %this should be fine, double check but ususally no need to change this. 
    screensize_cm = [40 30]; %same here, should be the standard 40cm by 30cm screen, ususally no need to change.
    
    %calculations below assume that the screen is viewed from 57cm
    %(because 1cm at 57cm distance = 1 visual degree). If this is not the
    %case in your setup, you have to figure out some math below to make it
    %work in your specific case. Shouldn't be too aweful.
    
    
    % Transform from analog to pixels and cm
        
    %create dummy array
    %cm
    x_cm = zeros(size(x));
    y_cm = zeros(size(y));
    
    %px
    x_px = zeros(size(x));
    y_px = zeros(size(y));
    
    left = calibration(1);
    top = calibration(2);
    right = calibration(3);
    bottom = calibration(4);

    % 1 visual degree = 1cm at 57 cm.
    % Subject was placed at 57cm
    % distance between left right = 20cm = 20 degrees
    % distance between top and bottom = 15cm =  15 degrees
    factorx_cm = (screensize_cm(1)/2) / (right - left);
    factory_cm = (screensize_cm(2)/2) / (bottom - top); % subtracting top from bottom to not have a negative number here

    %idem for pixels
    factorx_px = (screensize_px(1)/2) / (right - left);
    factory_px = (screensize_px(2)/2) / (bottom - top);

    %calculate x and y in cm and px -> for the deblinked data
    x_cm = x*factorx_cm; 
    y_cm = y*factory_cm;

    x_px = x*factorx_px;
    y_px = y*factory_px;
end

