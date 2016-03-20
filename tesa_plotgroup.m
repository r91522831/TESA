% tesa_plotgroup() - plots TMS-evoked activity averaged over participants. Timing of
%               the TMS pulse is indicated with a red dashed line. Confidence intervals 
%               across participants can also be plotted.
% 
%               To use this function, all of the participant files
%               must be in the same folder and all files must have
%               undergone identical tesa_peak_analysis runs or have the same 
%               electrodes.  No other files should be in this folder. Open
%               one file from the folder and run the function on
%               this file and all files in the folder will be averaged and plotted.
%
% Usage:
%   >>  tesa_plotgroup( EEG ); %butterfly plot
%   >>  tesa_plotgroup( EEG, 'key1',value1... );
%
% Inputs:
%   EEG             - EEGLAB EEG structure
% 
% Optional input pairs:
%   'xlim', [min,max] - integers describing the x axis limits in ms.
%                   default = [-100,500]
%   'ylim', [min,max] - integers describing the y axis limits in ms. If
%                   left blank, the plot will automatically scale.
%                   default = []
%                   Examples: [-10,10]
%   'elec','str'  - string describing either a single electrode  
%                   for plotting. If left blank, a butterfly plot of all electrodes 
%                   will be plotted.
%                   default = [];
%                   Example: 'Cz'
%   'CI','str'      - 'on' | 'off'. Plot confidence interval calculated
%                   across trials. This option is not available for GMFA
%                   and butterfly plots.
%                   default = 'off';
%   
% Options for plotting output from tesa_tepextract and tesa_peakanalysis
%   'tepType','str'  - 'data' | 'ROI' | 'GMFA'. 'Data' input extracts data
%                   for plotting from EEG.data. 'ROI' input selects a ROI
%                   generated by tesa_tepextract. 'GMFA' input selects a
%                   GMFA generated by tesa_tepextract. Note that if
%                   multiple ROIs or GMFAs are present, 'tepName' must also
%                   be included to determine which one to plot.
%                   Default = 'all';
%   'tepName', 'str' - String is either the name of a ROI or GMFA generated
%                   by tesa_tepextract. The default names generated by
%                   tesa_tepextract are 'R1','R2'... etc. however the user
%                   can also define names. This is required if multiple ROIs or GMFAs are present. 
%                   Default = []; 
% 
% Examples:
%   tesa_plotgroup(EEG); % plot a butterfly plot.
%   tesa_plotgroup(EEG, 'xlim', [-200,600], 'ylim', [-10,10], 'elec', 'P1', 'CI', 'on'); % plot the average of electrodes P1 and P3, rescale the axes and include confidence intervals.
%   tesa_plotgroup(EEG, 'tepType','ROI','tepName','parietal','CI','on'); % plot the output from a ROI analysis called parietal including detected peaks and confidence intervals
%   tesa_plotgroup(EEG, 'tepType','GMFA'); % plot output from a GMFA analysis including detected peaks
% 
% See also:
%   tesa_tepextract, tesa_peakanalysis, tesa_peakoutput 

% Copyright (C) 2016  Nigel Rogasch, Monash University,
% nigel.rogasch@monash.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function tesa_plotgroup( EEG, varargin )

if nargin < 1
	error('Not enough input arguments.');
end

%define defaults
options = struct('xlim',[-100,500],'ylim',[],'elec',[],'CI','off','tepType','data','tepName',[]);

% read the acceptable names
optionNames = fieldnames(options);

% count arguments
nArgs = length(varargin);
if round(nArgs/2)~=nArgs/2
   error('EXAMPLE needs key/value pairs')
end

for pair = reshape(varargin,2,[]) % pair is {propName;propValue}
   inpName = pair{1}; % make case insensitive

   if any(strcmpi(inpName,optionNames))%looks for known options and replaces these in options
      options.(inpName) = pair{2};
   else
      error('%s is not a recognized parameter name',inpName)
   end
end

%Check xlim input
if size(options.xlim,2)~=2
    error('Input for ''xlim'' must be in the following format [min,max] e.g. [-100,500].')
end

%Check xlim is within range of data
if options.xlim(1,1) < EEG.times(1,1) || options.xlim(1,1) > EEG.times(1,end) || options.xlim(1,2) < EEG.times(1,1) || options.xlim(1,2) > EEG.times(1,end)
    error('Input for ''xlim'' is outside of the range of the data (%d to %d).', EEG.times(1,1), EEG.times(1,end));
end

%Check ylim input
if ~isempty(options.ylim)
    if size(options.ylim,2)~=2
        error('Input for ''ylim'' must be in the following format [min,max] e.g. [-10,10].')
    end
end

%Check CI input
if ~(strcmp(options.CI,'off') || strcmp(options.CI,'on'))
    error('Input for ''CI'' must be either ''on'' or ''off''.');
end

%Check CI is not for butterfly plot
if strcmpi(options.tepType,'data') && strcmp(options.CI,'on') && isempty(options.elec)
    error('Confidence intervals can not be plotted for butterfly plots. Please include a single channel, ROI or GMFA for analysis.');
end

%Check tepType input
if ~(strcmp(options.tepType,'data') || strcmp(options.tepType,'ROI') || strcmp(options.tepType,'GMFA'))
    error('Input for ''tepType'' must be either ''data'', ''ROI'' or ''GMFA''.');
end    

%If tepType is ROI, check whether tepName is needed
if strcmp(options.tepType,'ROI')
    if ~isfield(EEG,'ROI')
        error('There are no ROI analyses present in the data. Please run tesa_tepextract.')
    elseif isempty(options.tepName) && size(fieldnames(EEG.ROI),1) > 1
        error('There are multiple ROIs present in the data. Please enter a specific ROI using ''tepName'', ''str'' where str is the name of the specific ROI.')
    end
end

%If tepType is GMFA, check whether tepName is needed
if strcmp(options.tepType,'GMFA')
    if ~isfield(EEG,'GMFA')
        error('There are no GMFA analyses present in the data. Please run tesa_tepextract.')
    elseif isempty(options.tepName) && size(fieldnames(EEG.GMFA),1) > 1
        error('There are multiple GMFAs present in the data. Please enter a specific GMFA using ''tepName'', ''str'' where str is the name of the specific GMFA.')
    end
end

%Check tepName input exists
if ~isempty(options.tepName)
    if ~(strcmp(options.tepType,'ROI') || strcmp(options.tepType,'GMFA'))
        error('Please indicate which type of TEP you would like to perform analysis on using ''tepType'', ''str'', where str is either ''ROI'' or ''GMFA''.');
    elseif strcmp(options.tepType,'ROI')
        if ~isfield(EEG.ROI,options.tepName)
            error('''tepName'' ''%s'' does not exist for tepType ROI. Please revise.',options.tepName);
        end
    elseif strcmp(options.tepType,'GMFA')
        if ~isfield(EEG.GMFA,options.tepName)
            error('''tepName'' ''%s'' does not exist for tepType GMFA. Please revise.',options.tepName);
        end
    end
end

%If only one TEP and tepName not included
if strcmpi(options.tepType,'ROI')
    if isempty(options.tepName)
        tempN = fieldnames(EEG.ROI);
        options.tepName = tempN{1,1};
    end
end

if strcmpi(options.tepType,'GMFA')
    if isempty(options.tepName)
        tempN = fieldnames(EEG.GMFA);
        options.tepName = tempN{1,1};
    end
end

%Get information from other files
fileInfo = dir([EEG.filepath,filesep,'*.set']);

fileNames = [];
for x = 1:size(fileInfo,1)
    fileNames{x,1} = fileInfo(x).name;
end

baseChan = size(EEG.data,1);
baseTime = size(EEG.data,2);

data = [];
time = [];
for x = 1:size(fileNames,1)
    EEG = pop_loadset( 'filename', fileNames{x,1}, 'filepath', EEG.filepath);
    if strcmpi(options.tepType,'data')
        if isempty(options.elec)
            %Check channels and time are equivalent
            if ~isequal(baseChan,size(EEG.data,1))
                error('The number of electrodes in the following data set is not equivalent with other data: %s',fileNames{x,1});
            end
            data(:,:,x) = mean(EEG.data,3);
            time = EEG.times;
        elseif ~isempty(options.elec);
            for z = 1:EEG.nbchan;
                chan{1,z} = EEG.chanlocs(1,z).labels;
            end;
            elecNum = find(strcmpi(options.elec,chan));
            if isempty(elecNum)
                error('The electrode %s is not present in the following data: %s', options.elec,fileNames{x,1});
            end
            data(:,:,x) = mean(EEG.data(elecNum,:,:),3);
            time = EEG.times;
        end
    elseif strcmpi(options.tepType,'ROI')
        if ~isfield(EEG,'ROI')
            error('ROI analysis is not present in the following data: %s',fileNames{x,1});
        end
        data(:,:,x) = EEG.ROI.(options.tepName).tseries;
        time = EEG.ROI.(options.tepName).time;
    elseif strcmpi(options.tepType,'GMFA')
        if ~isfield(EEG,'GMFA')
            error('GMFA analysis is not present in the following data: %s',fileNames{x,1});
        end
        data(:,:,x) = EEG.GMFA.(options.tepName).tseries;
        time = EEG.GMFA.(options.tepName).time;
    end
end

t = figure;

%Plot figure
plot(time,mean(data,3),'b'); hold on;

%Figure settings
if isempty(options.ylim)
    set(gca,'xlim',options.xlim,'box','off','tickdir','out')
elseif ~isempty(options.ylim)
    set(gca,'xlim',options.xlim,'ylim',options.ylim,'box','off','tickdir','out')
end

if strcmpi(options.tepType,'GMFA')
    ylabel('GMFA (\muV)');
else
    ylabel('Amplitude (\muV)');
end
xlabel('Time (ms)');

if strcmp(options.tepType,'data') && isempty(options.elec)
    title(['All electrodes - average of n = ',num2str(size(fileNames,1))]);
elseif strcmp(options.tepType,'data') && ~isempty(options.elec)
    title([options.elec, ' - average of n = ',num2str(size(fileNames,1))]);
elseif strcmp(options.tepType,'ROI')
    if isempty(options.tepName)
        tempName = fieldnames(EEG.ROI);
        titleIn = ['Region of interest (', tempName{1,1}, ') - average of n = ',num2str(size(fileNames,1))];
    else
        titleIn = ['Region of interest (', options.tepName, ') - average of n = ',num2str(size(fileNames,1))];
    end
    title(titleIn)
elseif strcmp(options.tepType,'GMFA')
    if isempty(options.tepName)
        tempName = fieldnames(EEG.GMFA);
        titleIn = ['Global mean field amplitude (', tempName{1,1}, ') - average of n = ',num2str(size(fileNames,1))];
    else
        titleIn = ['Global mean field amplitude (', options.tepName, ') - average of n = ',num2str(size(fileNames,1))];
    end
    title(titleIn)
end

%Confidence intervals (if requested)
if strcmp(options.CI,'on')
    M = mean(data,3); 
    CI = 1.96*(std(data,0,3)./(sqrt(size(data,3))));
    f = fill([EEG.times,fliplr(EEG.times)],[M-CI,fliplr(M+CI)],'b');
    set(f,'FaceAlpha',0.3);set(f,'EdgeColor', 'none');
end

%Plot timing of TMS pulse
plot([0 0], get(gca,'ylim'),'r--');

fprintf('TEP plot generated. \n');

end
