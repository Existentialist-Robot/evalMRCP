function [importedData] = importPrototypeData(fileName)
%importPrototypeFile Import numeric data from a text file saved using the
%   prototype system built upon OpenBCI platform.
%
%   Some of the code was auto-generated by MATLAB on 2018/04/25 12:01:06.
%
%   Included Variables:
%   saveDate: The date the file was saved.
%   eegData: EEG channels as columns and values as rows.
%   emgData: EMG channels as columns and values as rows.
%   sampleRate: The sampling rate of the data.
%   eegChannels: A cell array of eeg channel names corresponding to column number.
%   emgChannels: A cell array of emg channel names corresponding to column number.
%   timeVect: A column vector containing a time series for the recording, starting at 1/sampleRate.
%   trigger: A column vector of logical values. 1 for trigger.
%   system: The name of the system used for recording. One of {'Gold Standard', 'Prototype'}.
%   task: The name of the task performed during the recording. One of {'Dorsiflexion', 'Step on/off'}.
%   paradigm: The name of the paradigm for recording. One of {'Self-paced', 'Cued'}.
%
%   Variable Naming:
%   proto stands for prototype.
%   NU stands for not used.
%
%
%   Copyright (C) 2018 Usman Rashid
%   urashid@aut.ac.nz
%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 3 of the License, or
%   (at your option) any later version.


%% Predifined Variables
DELIMITER   = ',';
START_ROW   = 3;
CHANNEL_LABELS = {'C3', 'FC3', 'FCZ', 'CZ', 'CPZ', 'FC4', 'C4', 'CP4',...
    'CP3', 'P3', 'FP1', 'F3', 'F4', 'P4', 'EMG1', 'EMG2', 'TRIG', 'NU1', 'NU2'};
EMG_CHANNEL_LABELS      = {'EMG1', 'EMG2'};
EEG_CHANNEL_LABELS      = {'C3', 'FC3', 'FCZ', 'CZ', 'CPZ', 'FC4', 'C4', 'CP4',...
    'CP3', 'P3', 'FP1', 'F3', 'F4', 'P4'};
TRIG_CHANNEL_LABEL      = {'TRIG'};
TASK_NAMES              = {'Dorsiflexion', 'Step on/off'};
PARADIGM_NAMES          = {'Self-paced', 'Cued'};
AMP_FACT                = 24;
UVS_PER_COUNT           = 4.5/AMP_FACT/(2^23 - 1) * 1000000;
NUM_BYTES_EACH_VALUE    = 3;
SAMPLE_RATE             = 250;

% Assign default values
importedData = [];

% Find number of lines in the file and exclude the last line.
fprintf('Reading file %s\n', fileName);
fprintf('Finding number of lines in file\n');
endRow = numLinesInCSV(fileName) - 1;
fprintf('Number of lines in file %d\n', endRow);

%% Format for each line of text:
%   column2: text (%s)
%	column3: text (%s)
%   column4: text (%s)
%	column5: text (%s)
%   column6: text (%s)
%	column7: text (%s)
%   column8: text (%s)
%	column9: text (%s)
%   column10: text (%s)
%	column11: text (%s)
%   column12: text (%s)
%	column13: text (%s)
%   column14: text (%s)
%	column15: text (%s)
%   column16: text (%s)
%	column17: text (%s)
%   column18: double (%f)
%	column19: double (%f)
%   column20: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%*s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(fileName, 'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-START_ROW(1)+1, 'Delimiter', DELIMITER, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', START_ROW(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(START_ROW)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-START_ROW(block)+1, 'Delimiter', DELIMITER, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', START_ROW(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
fprintf('Reading raw data values\n');
dataArray([17, 18, 19]) = cellfun(@(x) num2cell(x), dataArray([17, 18, 19]), 'UniformOutput', false);
dataArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]) = cellfun(@(x) mat2cell(x, ones(length(x), 1)), dataArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]), 'UniformOutput', false);
rawData = [dataArray{1:end-1}];

%% Prepare storage variables
importedData.saveDate = date;

% EEG data
eegChannelLocs = strcmpMSC(CHANNEL_LABELS, EEG_CHANNEL_LABELS);
rawEegData = rawData(:, eegChannelLocs);
fprintf('Doing EEG hex conversion\n');
importedData.eegData = cellhex2double(rawEegData, NUM_BYTES_EACH_VALUE) .* UVS_PER_COUNT;
timeVect = (1:1:length(rawEegData)) ./ SAMPLE_RATE;
importedData.timeVect = timeVect';

% EMG data
emgChannelLocs = strcmpMSC(CHANNEL_LABELS, EMG_CHANNEL_LABELS);
rawEmgData = rawData(:, emgChannelLocs);
fprintf('Doing EMG hex conversion\n');
importedData.emgData = cellhex2double(rawEmgData, NUM_BYTES_EACH_VALUE) .* UVS_PER_COUNT;

% Other variables
importedData.sampleRate = SAMPLE_RATE;
importedData.eegChannels = EEG_CHANNEL_LABELS';
importedData.emgChannels = EMG_CHANNEL_LABELS';
importedData.system = 'Prototype';

% Trigger
triggerChannelLocs = strcmpMSC(CHANNEL_LABELS, TRIG_CHANNEL_LABEL);
trigger = cell2mat(rawData(:, triggerChannelLocs));
importedData.trigger = trigger == 0;

subSessMovTokens = regexp(fileName, '.*sub([0-9]+)_sess([0-9]+)_mov([0-9]+)', 'tokens');
subSessMovTokens = subSessMovTokens{1};

% Ask user for task.
addInfo = sprintf('sub:%s sess:%s mov:%s', subSessMovTokens{1}, subSessMovTokens{2}, subSessMovTokens{3});
taskName = singleChoiceList(sprintf('Choose task for %s', addInfo), TASK_NAMES);
if(isempty(taskName))
    importedData = [];
    return;
else
    importedData.task = taskName;
end

% Ask user for paradigm.
paradigmName = singleChoiceList(sprintf('Choose paradigm for %s', addInfo), PARADIGM_NAMES);
if(isempty(paradigmName))
    importedData = [];
    return;
else
    importedData.paradigm = paradigmName;
end
fprintf('Done packing variables\n');
end
