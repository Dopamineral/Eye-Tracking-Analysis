function [] = PlotDataMatrix(data,buffer_beginning,figtitle,figxlabel,figylabel,LineColor)
%PLOTDATAMATRIX Summary of this function goes here

    meandata = nanmean(data);
    stddataplus = meandata + nanstd(data);
    stddatamin = meandata - nanstd(data);
    %calulating standard error of the mean. = standard error divide by sqrt of
    %the sample size (size of data[1])
    sem =  nanstd(data) /(sqrt(size(data,1)));
    semplus = meandata + sem; 
    semmin = meandata - sem;


    % %fill the stimulation zone. TODO
    % xstimzone = [buffer_beginning: buffer_beginning+300];
    % ystimzone = ylim;
    % fill([xstimzone, fliplr(xstimzone)], [ystimzone,fliplr(ystimzone)], 'g')

    %Fill te standard error areas before plotting over them.
    upper_data = semplus;
    lower_data = semmin;
    x0 = 1:length(meandata);
    x2 = [x0, fliplr(x0)];
    fill_area = [lower_data,fliplr(upper_data)];
    fill(x2, fill_area,[0.85 0.85 0.85],'LineStyle','none');

    hold on;
    %plot(meandata,'r') %mean
	plot(meandata,LineColor) %mean

    %plot margins showing stimulus section
    xp1 = buffer_beginning;
    xp2 = buffer_beginning +300; %length of stimulus is 300ms;

    line(xlim, [0,0]); %x=0 axis
    line([xp1, xp1],ylim); %first vertical line
    line([xp2, xp2],ylim); %second vertical line
    
    title(figtitle)
    xlabel(figxlabel)
    ylabel(figylabel)
end

