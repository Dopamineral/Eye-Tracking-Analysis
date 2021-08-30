%% General introduction
% Author Robert Pretorius Bsc, 2021
%
% Hello reader, welcome tot the eye tracking script! 
%
% This script will help you analyze your eye tracking data for specific
% conditions and hopefully not cause too much pain and discomfort. 
%
% So what does this script do 
% In short
% - loads data from the mat files that contain the analog data of eye tracking.
% - processes the data so it's nice (deblinking, filtering, outlier removal-ish)
% - Chops up the data and organizes them per condition into data stacks
% - data can then be plotted, exported and you can do whatever you want
%   with it.
% 
% Coming from a python background, everything is written in snake_case
% mostly (meaningng_that_words_are_separated_by_underscores). Sometimes you
% might find CamelCase (WordsSeparatedByCapitalisation) but I try to keep
% that to a minimum, just to minimize the risk of erros due to
% capitalisation. 
% 
%      
% Now before you jump into it, to get this to work there are some tips and
% pointers in the script below. There's a high likelihood that the script 
% won't work first time around and that's normal. The script below was made
% for a specific experimental setup as example for you to see how it works.
% However this means that if your experiment has different conditions and
% timings that it won't work immediately. But not to worry that's where all
% these long comments come in. 
%
% You should be able to tweak the script here
% and there a little bit to do what you want to do. For example, loading
% the data might be a bit of a tedious procedure and getting them to match
% the variables that the script will continue using might give some
% annoyance, but as long as you are able to wrangle your data a little 
% until it fits the supported format (as will be described below) you
% should be good to go. 
%
% Alright ready to go, let's get into it.
%
% I recommend copying this script and the corresponding func folder (should be closeby)
% into your own folder domain and rename however you like so you can make changes to it
% without any problems.

%% Load Dependencies
%path that has the eye tracking script
addpath('mnt.autofsstoragegbw-s-neu01_fmri-monkey-03PROJECTRobertPretoriusEyeTracking'); %root folder for eye tracking script
%func folder (that has all the necessary functions).
addpath('mnt.autofsstoragegbw-s-neu01_fmri-monkey-03PROJECTRobertPretoriusEyeTrackingfunc'); %Directory containing all the functions

%% To start, Prepare a sheet that has the necessary information to start the analysis
% First of all, to spare any annoying file manipulation tasks I opt for the
% following approach. Get all of the full paths of the files that you want to analyze ordered
% in a nice spreadsheet before you continue. This will make the loading
% procedure much smoother and will eliminate the difficulty of matching
% files (semi) automatically, if that were needed. This also gives you a
% protection against mismatching files by accident.
%
% Create a spreadsheet with column 1 containing the full path for all the analog data files
% analog data files =  the analog output file from the experiment (.mat
% file), it's usally comprised of a c and d struct that houses all the
% necessary data. In the c struct is an abundance of timing information
% (what was shown at what time). In the d struct you should find the
% relevant analog channel outputs and info on what each one is.
% 
% In columns 2,3,4 and 5 add the individual values of the calibration that
% was done. What is this Basically when the subject is scanned they are
% instructed to look at 4 corners  to calibrate the eye tracker to the
% screen. The output of this calibration is the four sides of this rectangle left, top, right, bottom.
% We will need this data later on to do the conversion to cm,
% pixels, and visual degrees. In older data you can find this in the
% task.log file. In newer data there is a json file that contains this
% information. 
%The data should look like 4 values [-3.82321 4.2213 4.654564 -3.84564 ] = left, top, right, bottom.
% Fun fact, the calibration is usually done once per scanning
% day so you can just copy the calibration settings from one run to the
% other runs of that same day. 
%
% In summary Prepare a spreadsheet.
% Column1 'fullpath' full path of the behavioral data file (analog data with c and d structs)
% Column2-5 Calibration data (left, top, right, bottom). Name the columns
%calib_left, calib_top, calib_right, calib_bottom
%
%Load the spreadsheet (UI will open)
[file, path] = uigetfile('.'); 
files = readtable(fullfile(path,file), 'Delimiter',',','ReadVariableNames',1); %'files' will contain the columns of your spreadsheet

%% Making condition varianbles.

%This is where the big loop starts. 
%Initiating some variables that can be used. For instance, we are
%interested in R hand and L hand conditions. We will filter out the data
%per run in the for loop and add them to the variables we asign here.
%It might necessary to make different CSV files and change the variables
%below and their logic in the script depending on your case. 

data_xR = []; %x data for Right hand conditions.
data_yR = [];
data_pupilR = [];

data_xL = [];
data_yL = [];
data_pupilL = [];

data_xNull = [];
data_yNull = [];
data_pupilNull = [];

%Condition_logic 1 Left is associated with condition A
%Condition_logic 2 Right hand is associated with condition A
condition_logic = 1;

%% loop over all the files
file_index = 1; % Initiate this variable and run everything inside the for loop if you're interested in just looking at 1 run. 

%Addning a variable to store all the indices that correspond to junk files
%(These files give errors when you run the loop). 
junk_files = [];

for file_index = 1size(files,1)
try
%The for loop willl go until the data stacks are created below. Figure plotting is not inside the loop. 
%Change as needed. 
disp(file_index);
% analog data loading
analog_data = load(files.fullpath{file_index}); %change 'Var2' to whatever your column name is.
calibration = [files.calib_left(file_index),...
               files.calib_top(file_index),...
               files.calib_right(file_index),...
               files.calib_bottom(file_index)];
%THis calibration logic variable as described above can also be soureced
%from the csv file if that makes it easier. 
condition_logic = files.calibration_logic(file_index);

%Now your data might not follow the exact logic as is shown below. 
%It might be structured slightly differently or might be
%entirely something else. Bottom line is,  get it to the format that you
%see below.
%
%If your data is contained within these variables as is shown below, then
%you can run the rest of the script without any problems. Tweak as
%necessary.

x = analog_data.d.analog(1,); %eye tracking data on x-axis
y = analog_data.d.analog(2,); %eye tracking data on y-axis
pupil = analog_data.d.analog(8,); %pupil diameter output
time = (1size(x,2))analog_data.d.analogSampleRate(1); %time variable, might by handy during plotting.

datastart = analog_data.d.dataStart; %start time of the data

% Create meta_table of c struct in analog data - easier to work with
meta_table = struct2table(analog_data.c);

% Correct the start and stop times of data with datastart (will use this to
% load x and y and pupil data later in the script.
meta_table.norm_start = meta_table.Start - datastart;
meta_table.norm_stop = meta_table.Stop - datastart;

%Extract the photoevents. Here the photoevents give an accurate timing of
%your experimental setup.
%in the example below
%photoevent(1) = fixation starts
%photoevent(2) = target appears
%photoevent(3) = target disappears
%photoevent(4) = subject responded

pecell = meta_table.PhotoEvents;
PE_table = table();
warning('off','all') %suppressing the warnings the table will throw below just so people don't freak out
for i = 1size(pecell,1) 
    % adjust this loop, add or subtract according to how many photoevents you have. 
    % The individual photoevents are then added to the meta_table so they
    % can be accessed easier.
    %if there are 4 photoevents it will look as below 
    if size(pecell{i},2) == 4
        PE_table.PE1(i) = pecell{i}(1); %photoevent 1
        PE_table.PE2(i) = pecell{i}(2); %photoevent 2
        PE_table.PE3(i) = pecell{i}(3); %photoevent 3
        PE_table.PE4(i) = pecell{i}(4); %photoevent 4
    else
        %if there are less than 4 photoevents in this case it means that
        %these are not useful for me. These correspond to some conditions
        %that are meaningless. If you have some conditions where there are
        %3 or 5 or however many photoevents but they are relevant, just add them to this
        %loop in a similar matter as above and you should be good to go.
        %You can change the table names to PEA1, PEA2 and so on. Just
        %know that changing them here wil mean you have to change them 
        %add them  remove them later on in the script where they will be
        %used. Should not be too much work. 
        PE_table.PE1(i) = 0;
        PE_table.PE2(i) = 0;
        PE_table.PE3(i) = 0;
        PE_table.PE4(i) = 0;
    end
end
warning('on','all')

meta_table = [meta_table, PE_table];

%'normalize' the PE timepoints by substracting datastart
%adjust here according to how many Photo Events you have.
meta_table.norm_PE1 = round(meta_table.PE1 - datastart);
meta_table.norm_PE2 = round(meta_table.PE2 - datastart);
meta_table.norm_PE3 = round(meta_table.PE3 - datastart);
meta_table.norm_PE4 = round(meta_table.PE4 - datastart);


% get relevant lines out of the metatable.
%Select the relevant conditions - make logical index
conditions = unique(meta_table.Condition); %adjust as necessary if you have more or less conditions. 
%The example below uses 3 conditions (2 experimental and one control)

relevant_index_condition_A = cellfun(@isequal, meta_table.Condition, repmat(conditions(2),size(meta_table,1),1)); % Having to use the cellfun thing here because cells are weird, you can´t just compare them outright
relevant_index_condition_B = cellfun(@isequal, meta_table.Condition, repmat(conditions(3),size(meta_table,1),1));
relevant_index_condition_null = cellfun(@isequal, meta_table.Condition, repmat(conditions(1),size(meta_table,1),1));

%Select which answer type you want to investigate - logical index array is created.
index_right_answer = meta_table.Answer == 1;

%Combine index arrays if necessary - for example; below are the specific conditions that had
%answers in a particular condition and those answers were correct.
index_right_condition_A = relevant_index_condition_A & index_right_answer;
index_right_condition_B = relevant_index_condition_B & index_right_answer;
index_right_condition_null = relevant_index_condition_null & index_right_answer;

%% Load all the data into the tables you want
%load tables for each condition to save yourself a headache later
condition_A_table = meta_table(index_right_condition_A,);
condition_B_table = meta_table(index_right_condition_B,);
condition_null_table = meta_table(index_right_condition_null,);
%These tables will be used to make a stacked datamatrix later on (see below
%for more information).

%% preprocessing
    
        
    % Deblinking x, y and pupil data. See function for more info
    [x_db, y_db, pupil_db] = Deblink(x,y,pupil, false);
    
    % Filter data taking into account 120Hz eye tracker, smoothing the
    % data as well. If the eye tracker sampling rate or other variables are
    % slightly different, change them in the function file
    x_db_f = Filter(x_db,false); %the false here is for the verbose argument
    y_db_f = Filter(y_db,false);
    pupil_db_f = Filter(pupil_db,false);
    
    % Calibration Correcting data - cm and px output for x and y. See
    % function for more info. 
    [x_cm, y_cm, x_px, y_px] = CalibrationCorrect(x_db_f,y_db_f,calibration);
   
    
%% Further analysis (todo)
    % vergence angle 

    % Saccade detection
    
    % Fixation detection
    
    % Microsaccade detection

%% PLOTTING
% Stack data for a certain condition into a matrix
%These matrices with the data stacked are going to be the basis for the
%plotting and statistics. They can also be outputted to be worked on in
%other programs  scripts. 

buffer_beginning = 300; %Peri-stimulus time in the beginning to plot and analyze
buffer_ending = 100; %peri stimulis time in the end to plot

%Stack x, y and pupil data for condition A
data_xA = StackConditionData(condition_A_table,x_cm,buffer_beginning,buffer_ending,false);
data_yA = StackConditionData(condition_A_table,y_cm,buffer_beginning,buffer_ending,false);
data_pupilA = StackConditionData(condition_A_table,pupil_db_f,buffer_beginning,buffer_ending,false);

%Stack x, y and pupil data for condition B
data_xB = StackConditionData(condition_B_table,x_cm,buffer_beginning,buffer_ending,false);
data_yB = StackConditionData(condition_B_table,y_cm,buffer_beginning,buffer_ending,false);
data_pupilB = StackConditionData(condition_B_table,pupil_db_f,buffer_beginning,buffer_ending,false);

%Stack x, y and pupil data for condition null
data_xnull = StackConditionData(condition_null_table,x_cm,buffer_beginning,buffer_ending,false);
data_ynull = StackConditionData(condition_null_table,y_cm,buffer_beginning,buffer_ending,false);
data_pupilnull = StackConditionData(condition_null_table,pupil_db_f,buffer_beginning,buffer_ending,false);

%Normalize data The name is a bit misleading. WHat this script does is 
%centering the data around zero. TO do this it takes the datastack and
%calculates the mean of beginning window (which has size
%beginning_buffer). It then subtracts this from the whole data signal. 

%Centering condition A data stacks
data_xA = NormalizeData(data_xA,buffer_beginning);
data_yA = NormalizeData(data_yA,buffer_beginning);
data_pupilA = NormalizeData(data_pupilA,buffer_beginning);

%Centering condition B data stacks
data_xB = NormalizeData(data_xB,buffer_beginning);
data_yB = NormalizeData(data_yB,buffer_beginning);
data_pupilB = NormalizeData(data_pupilB,buffer_beginning);

%Centering condition null data stacks. 
data_xnull = NormalizeData(data_xnull,buffer_beginning);
data_ynull = NormalizeData(data_ynull,buffer_beginning);
data_pupilnull = NormalizeData(data_pupilnull,buffer_beginning);


%% Adding data to the condition variables that were defined above the for loop.

if condition_logic ==1
    data_xR = [data_xR;data_xB]; 
    data_yR = [data_yR;data_yB];
    data_pupilR = [data_pupilR;data_pupilB];

    data_xL = [data_xL;data_xA];
    data_yL = [data_yL;data_yA];
    data_pupilL = [data_pupilL;data_pupilA];


    data_xNull = [data_xNull;data_xnull];
    data_yNull = [data_yNull;data_ynull];
    data_pupilNull = [data_pupilNull;data_pupilnull];

elseif condition_logic ==2
    data_xR = [data_xR;data_xA]; 
    data_yR = [data_yR;data_yA];
    data_pupilR = [data_pupilR;data_pupilA];

    data_xL = [data_xL;data_xB];
    data_yL = [data_yL;data_yB];
    data_pupilL = [data_pupilL;data_pupilB];


    data_xNull = [data_xNull;data_xnull];
    data_yNull = [data_yNull;data_ynull];
    data_pupilNull = [data_pupilNull;data_pupilnull];
end

catch
    disp(Junk File Detected);
     junk_files = [junk_files, file_index];
end
end
%% Plotting data
% To plot the data there is a specialized function called PLotDataMatrix.
% It takes the data that is in the datamatrix formed above and calculates
% means, standard errors of means and plots them as a mean line with a
% standard deviation shadow around it. It also has a horizontal line for
% x=0 and 2 vertical lines at the start and stop of the particular stimulus
% window we're interested in.


% Condition L
figure;
subplot(1,3,1);
figtitle = X;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_xL,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.06 0.03])

subplot(1,3,2);
figtitle = Y;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_yL,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.5 0.1])

subplot(1,3,3);
figtitle = Pupil;
figxlabel = time (ms);
figylabel = arbitrary units;
PlotDataMatrix(data_pupilL,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.05 0.02])

sgtitle('Left Hand Response')
saveas(gcf,['M1_LeftHandResp.png']);
% Plotting data
% Condition R
figure; 
subplot(1,3,1);
figtitle = X;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_xR,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.07 0.03])

subplot(1,3,2);
figtitle = Y;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_yR,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.45 0.1])

subplot(1,3,3);
figtitle = Pupil;
figxlabel = time (ms);
figylabel = arbitrary units;
PlotDataMatrix(data_pupilR,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.035 0.04])

sgtitle('Right Hand Response')
saveas(gcf,['M1_RightHandResp.png']);
% Plotting data
% Condition Null
figure; 
subplot(1,3,1);
figtitle = X;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_xNull,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.005 0.02])

subplot(1,3,2);
figtitle = Y;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_yNull,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.006 0.014])

subplot(1,3,3);
figtitle = Pupil;
figxlabel = time (ms);
figylabel = arbitrary units;
PlotDataMatrix(data_pupilNull,buffer_beginning,figtitle,figxlabel,figylabel)
ylim([-0.025 0.01])

sgtitle('Fixation')
saveas(gcf,['M1_FixOnly.png']);

% Plotting Left and Right in single figure

figure;
subplot(1,3,1);
figtitle = X;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_xL,buffer_beginning,figtitle,figxlabel,figylabel,'b');
% p.Color='g';
hold on
PlotDataMatrix(data_xR,buffer_beginning,figtitle,figxlabel,figylabel,'r')
% p.Color='r';
ylim([-0.5 0.1])

subplot(1,3,2);
figtitle = Y;
figxlabel = time (ms);
figylabel = visual degrees;
PlotDataMatrix(data_yL,buffer_beginning,figtitle,figxlabel,figylabel,'b')
hold on
PlotDataMatrix(data_yR,buffer_beginning,figtitle,figxlabel,figylabel,'r')
ylim([-0.5 0.1])

subplot(1,3,3);
figtitle = Pupil;
figxlabel = time (ms);
figylabel = arbitrary units;
PlotDataMatrix(data_pupilL,buffer_beginning,figtitle,figxlabel,figylabel,'b')
hold on
PlotDataMatrix(data_pupilR,buffer_beginning,figtitle,figxlabel,figylabel,'r')
ylim([-0.03 0.02])

sgtitle('Left and Right Hand Response')
saveas(gcf,['M2 Left and Right Hand Response_ScaleSet.png']);