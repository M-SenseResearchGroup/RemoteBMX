function [ data ] = importMC10(dataDirectory,varargin)
%Reed Gurchiek, 2018, reed.gurchiek@uvm.edu
%   imports MC10 data from the specified data directory.  The data
%   directory is the path to the folder containing only annotation.csv file
%   (if any) and data folders corresponding to different sensors.  
%
%   all imported data are synced and resampled to a uniform grid at a 
%   sampling frequency dependent on the resample option (see INPUTS).
%
%   data is returned according to the trial during which it was recorded.
%   If no activities (no annotation.csv), then the trial name 'move' will 
%   hold all the data.  'move' is also a trial name for all returned data 
%   structures and contains all data captured after the last activity in 
%   annotation.csv
%
%   for example, if a 1 minute walk task was performed called 'walk' and
%   then the subject wore the sensor at home for 2 hrs, then there would be
%   two trials: (1) data.walk and (2) data.move where move contains all
%   data after the walk task finished.
%
%---------------------------INPUTS-----------------------------------------
%
%   dataDirectory:
%       The data directory should contain only annotation.csv file and 
%       data folders corresponding to different sensors.
%
%   options (varargin):
%       -input as: importMC10(dataDirectory, option1, val1, option2, val2, etc.)
%
%       (1) trialNames (default: all):
%           -cell with names of trials (activities) to keep 
%           -these correspond to those listed in annotations.csv)  
%           -if all then 'all'
%
%       (2) locationNames (default: all):
%           -cell with names of sensor locations.  
%           -if all then 'all'
%
%       (3) sensorNames (default: all):
%           -cell with sensor names to keep.  
%           -if all then 'all'
%           -acceptable sensor names:
%               (1) 'acc'
%               (2) 'gyro'
%               (3) 'emg'
%
%       (4) resample (default: mc10):
%           -if 'high' then resamples all data to highest sf for all sensors
%           -if 'low' then resamples all data to lowest sf
%           -if x then resamples to x
%           -if 'mean' then resamples to the sensor's mean frequency
%           -if 'mc10' then resamples to user-set sf in mc10 study
%                   -e.g. if mean sf is 34 Hz, then resamples to 31.25 Hz
%           -if 'mc10high' then resamples to the highest sf set by user in
%               mc10 study design across all sensors
%                   -e.g. if mean emg sf = 501.3 Hz and acc sf = 30 Hz,
%                   then all emg and acc data resampled to 500 Hz
%           -if 'mc10low' then resamples to the lowest sf set by user in
%               mc10 study design across all sensors
%           
%       (5-7) resampleACC, resampleGYRO, resampleEMG:
%           -use this to resample individual sensors to specific sf
%           -for this use either x, 'mean', or 'mc10'
%
%       (8) storeSameTrials (default: appendField):
%           -if 'appendName' then multiple trials of same activity will have
%               the trial number appended 
%                   -e.g. trial.walk_01.start, trial.walk_02.start, etc.
%           -if 'appendField' then multiple trials of same activity will be 
%               added as an additional field element
%                   -e.g. trial.walk(1).start, trial.walk(2).start, etc.
%           -if 'first' then only the first activity of this type is saved
%           -if 'last' then only the last activity of this type is saved
%
%       (9) reportStatus (default: 0):
%           -flag to update (1) or not (0) status of import to command
%            window
%
% 	-example: to make the accelerometer resample to the mean acc sf, the
%           gyro resample to 100 Hz, and emg resample to the sf set by user
%           in mc10 study, for the left/right rectus femoris, all trials, 
%           and report import status then:
%
%   importMC10(dataDirectory,'trialNames','all',...
%                            'sensorLocations',{'rectus_femoris_right','rectus_femoris_left'},...
%                            'sensorNames','all',...
%                            'resampleACC','mean',...
%                            'resampleGYRO,100,...
%                            'resampleEMG','mc10',...
%                            'reportStatus',1)
%
%--------------------------OUTPUTS-----------------------------------------
%
%   data:
%           data.
%                trialName.
%                          start
%                          end
%                          locationName.
%                                       sensorName.
%                                                  t
%                                                  dataName
%                                                  sf
%
%--------------------------------------------------------------------------
%% importMC10

% set option defaults
sense = {'acc' 'gyro' 'emg'};
option = ...
    struct('trialNames','all',...
           'locationNames','all',...
           'sensorNames','all',...
           'storeSameTrials','appendField',...
           'resampleACC','mc10',...
           'resampleGYRO','mc10',...
           'resampleEMG','mc10',...
           'reportStatus',0);

% update if given
if ~isempty(varargin)
    if mod(length(varargin),2)
        error('Input arguments must be even number: (Name1, Value1, Name2, Value2, ...)')
    end
    % for each option
    for k = 1:length(varargin)/2
        % correct potential naming errors
        if any(strcmp(varargin{2*k-1},{'sensors','sensor','sensorName'})); varargin{2*k-1} = 'sensorNames';
        elseif any(strcmp(varargin{2*k-1},{'sensorLocations','locations','location','locationName','sensorLocation'})); varargin{2*k-1} = 'locationNames';
        elseif any(strcmp(varargin{2*k-1},{'storeSameActivities','sameActivites','sameTrials'})); varargin{2*k-1} = 'storeSameTrials';
        elseif any(strcmp(varargin{2*k-1},{'activityNames','activities','trials','activity','trial'})); varargin{2*k-1} = 'trialNames';
        elseif any(strcmp(varargin{2*k-1},{'report','status'})); varargin{2*k-1} = 'reportStatus';
        end
        
        % update sensor resamples if global resample given
        if strcmpi(varargin{2*k-1},'resample')
            for j = 1:3
                option.(['resample' upper(sense{j})]) = varargin{2*k};
            end
            
        % if cell value
        elseif iscell(varargin{2*k})
            option.(varargin{2*k-1}) = '';
            % concatenate each name
            for j = 1:length(varargin{2*k})
                % use first letter only if sensorNames
                if strcmp(varargin{2*k-1},'sensorNames')
                    option.(varargin{2*k-1}) = [option.(varargin{2*k-1}) varargin{2*k}{1,j}(1)];
                else
                    option.(varargin{2*k-1}) = [option.(varargin{2*k-1}) varargin{2*k}{1,j}];
                end
            end
        else
            option.(varargin{2*k-1}) = varargin{2*k};
        end
    end
end

%% organize structure

% get directory and unhidden folders, read annotations, initialize data
data = struct('move',struct('start',[],'end',[]));
data.move.start = 0;
noEvents = 1;
data.move.end = inf;
location = struct();
d = dir(dataDirectory);
idir = 1;
while idir <= numel(d)
    % if unhidden folder to keep
    if isfolder(fullfile(d(idir).folder,d(idir).name))
        if ~strcmp(d(idir).name(1),'.') && (strcmpi(option.locationNames,'all') || contains(option.locationNames,d(idir).name))
            % then data folder, save and increment counter
            location.(d(idir).name) = fullfile(d(idir).folder,d(idir).name);
            idir = idir + 1;
        else
            d(idir) = [];
        end
    % otherwise if hidden file
    elseif d(idir).name(1) == '.'
        % then delete
        d(idir) = [];
    % otherwise if csv file
    elseif strcmp(d(idir).name(end-3:end),'.csv')
        % then annotation file, read
        noEvents = 0;
        if option.reportStatus; fprintf('-Reading annotations, creating trials\n'); end
        fanot = fopen(fullfile(d(idir).folder,d(idir).name),'r');
        anot = textscan(fanot,'%s','HeaderLines',1,'Delimiter',','); anot = anot{1};
        fclose(fanot);
        % structure trials
        ntrials = round(length(anot)/7);
        itr = 1;
        while itr <= ntrials
            % keep?
            tname = replace(anot{itr*7-4},{'"'},{''});
            if strcmpi(option.trialNames,'all') || contains(option.trialNames,tname)
                
                % make field appropriate trial name
                tname = valfname(tname);
                % how many of these trials?
                ntr = 1;
                if isfield(data,tname) || isfield(data,[tname '_1'])
                    if strcmpi(option.storeSameTrials,'appendName')
                        ntr = 2;
                        while isfield(data,[tname '_' num2str(ntr)])
                            ntr = ntr + 1;
                        end
                    else
                        ntr = numel(data.(tname)) + 1;
                    end    
                end
                % handle storeSameTrials option
                if strcmpi(option.storeSameTrials,'appendName')
                    if ntr == 2
                        data.([tname '_1']) = data.(tname);
                        data = rmfield(data,tname);
                        tname = strcat(tname,'_',num2str(ntr));
                    elseif ntr > 2
                        tname = strcat(tname,'_',num2str(ntr));
                    end
                    ntr = 1;
                elseif strcmpi(option.storeSameTrials,'last')
                    ntr = 1;
                end
                if ~strcmpi(option.storeSameTrials,'first') || ntr == 1
                    % start and end timestamps
                    data.(tname)(ntr).start = str2double(replace(anot{itr*7-2},{'''','"'},{'',''}))/1000;
                    data.(tname)(ntr).end= str2double(replace(anot{itr*7-1},{'''','"'},{'',''}))/1000;
                    % if current trial has latest start time, then end is move start
                    if data.move.start < data.(tname)(ntr).end; data.move.start = data.(tname)(ntr).end; end
                end
            end
            itr = itr + 1;
        end
        idir = idir + 1;
    % otherwise unnecessary, delete
    else
        d(idir) = [];
    end
end

% sampling frequency options for resampling and syncing
mc10f = 15.625*2.^[0 1 2 3 4 5 6];
new.high = 0;
new.low = inf;
new.mc10high = 0;
new.mc10low = inf;

%% get data files

% loop through locations
locations = fieldnames(location);
for k = 1:length(locations)
    done = 0;
    while ~done
        % get .csv files
        d = dir(fullfile(location.(locations{k}),'*.csv'));
        % remove hidden
        idir = 1;
        while idir <= numel(d)
            if d(idir).name(1) == '.'
                d(idir) = [];
            else
                idir = idir + 1;
            end
        end
        
        % if none
        if isempty(d)
            % look at each element
            d = dir(location.(locations{k}));
            idir = 1;
            while idir <= numel(d)
                % delete if not a folder
                if ~isfolder(fullfile(d(idir).folder,d(idir).name))
                    d(idir) = [];
                % delete if hidden
                elseif strcmp(d(idir).name(1),'.')
                    d(idir) = [];
                % otherwise enter it
                else
                    location.(locations{k}) = fullfile(d(idir).folder,d(idir).name);
                    break;
                end
            end
        % if found the csv files
        else
            
            % remove hidden files
            j = 1;
            while j <= numel(d)
                if d(j).name(1) == '.'
                    d(j) = [];
                else
                    j = j + 1;
                end
            end
            data.move.(locations{k}) = struct();
            % for each
            for j = 1:numel(d)
                % if keep sensor data
                if strcmpi(option.sensorNames,'all') || contains(option.sensorNames,d(j).name(1))
                    % num columns (4 for acc and gyro, 2 for emg), sensor names, and data names
                    if strcmp(d(j).name(1),'a')
                        ncol = 4;
                        sensorName = 'acc';
                        dname = 'a';
                        scale = 1;
                    elseif strcmp(d(j).name(1),'g')
                        ncol = 4;
                        sensorName = 'gyro';
                        dname = 'w';
                        scale = pi/180;
                    elseif strcmp(d(j).name(1),'e')
                        ncol = 2;
                        sensorName = 'emg';
                        dname = 'e';
                        scale = 1;
                    end
                    % read
                    if option.reportStatus; fprintf('-Reading %s for %s ',d(j).name,locations{k}); end
                    fid = fopen(fullfile(d(j).folder,d(j).name),'r');
                    scalarID = textscan(fid,'Timestamp (m%c,',1);
                    timeScalar = 1000;
                    if scalarID{1} == 'i'; timeScalar = 1000000; end
                    dat = cell2mat(textscan(fid,[repmat('%f,',[1 ncol-1]) '%f\n'],'HeaderLines',1));
                    fclose(fid);
                    if option.reportStatus
                        mem = whos('data');
                        mem = mem.bytes/1024^3;
                        metric = 'GB';
                        if mem < 1
                            mem = mem*1024;
                            metric = 'MB';
                        end
                        if mem < 1
                            mem = mem*1024;
                            metric = 'KB';
                        end
                        fprintf('(Current memory: %3.1f %s)\n',mem,metric);
                    end
                    % get time and make sure unique
                    data.move.(locations{k}).(sensorName).t = dat(:,1)'/timeScalar;
                    [data.move.(locations{k}).(sensorName).t,iUnique] = unique(data.move.(locations{k}).(sensorName).t);
                    
                    % get sensor data with unique time points and mean sf
                    data.move.(locations{k}).(sensorName).(dname) = scale*dat(iUnique,2:ncol)';
                    data.move.(locations{k}).(sensorName).sf = 1/mean(diff(data.move.(locations{k}).(sensorName).t));

                    % resampling specs
                    % highest?
                    if new.high < data.move.(locations{k}).(sensorName).sf
                    	new.high = data.move.(locations{k}).(sensorName).sf;
                    end
                    % lowest?
                    if new.low > data.move.(locations{k}).(sensorName).sf
                    	new.low = data.move.(locations{k}).(sensorName).sf;
                    end
                    % sensor specific mc10 user specified?
                    if strcmpi(option.(['resample' upper(sensorName)]),'mc10')
                        [~,isf] = min(abs(mc10f - data.move.(locations{k}).(sensorName).sf));
                        data.move.(locations{k}).(sensorName).sf = mc10f(isf);
                    % constant user specified
                    elseif isa(option.(['resample' upper(sensorName)]),'numeric')   
                        data.move.(locations{k}).(sensorName).sf = option.(['resample' upper(sensorName)]);
                    end

                    % update end time
                    if dat(end,1)/timeScalar < data.move.end; data.move.end = dat(end,1)/timeScalar; end
                    if noEvents
                        if dat(1,1)/timeScalar > data.move.start
                            data.move.start = dat(1,1)/timeScalar;
                        end
                    end
                end
            end
            done = 1;
        end
    end
end

% all sfs should be correct for resampling unless high, low, mc10high, or mc10low
[~,isf] = min(abs(mc10f - new.high));
new.mc10high = mc10f(isf);
[~,isf] = min(abs(mc10f - new.low));
new.mc10low = mc10f(isf);
% for each location
for k = 1:length(locations)
    % for each sensor
    sensors = fieldnames(data.move.(locations{k}));
    for j = 1:length(sensors)
        % if high, low, mc10high, or mc10low
        if any(strcmpi(option.(['resample' upper(sensors{j})]),{'high','low','mc10high','mc10low'}))
            data.move.(locations{k}).(sensors{j}).sf = new.(option.(['resample' upper(sensors{j})]));
        end
    end
end

%% sync and resample

% for each trial name
trials = fieldnames(data);
for k = length(trials):-1:1
    % for each trial of that name
    for kk = 1:length(data.(trials{k}))
        % for each location
        for j = 1:length(locations)
            % for each sensor
            sensors = fieldnames(data.move.(locations{j}));
            for i = 1:length(sensors)
                % global time array
                allTime = data.move.(locations{j}).(sensors{i}).t;
                % sync and resample
                if option.reportStatus; fprintf('-Syncing and resampling %s, %s data during %s (%d) ',locations{j},sensors{i},trials{k},kk); end
                dname = fieldnames(data.move.(locations{j}).(sensors{i}));
                data.(trials{k})(kk).(locations{j}).(sensors{i}).t = data.(trials{k})(kk).start:1/data.move.(locations{j}).(sensors{i}).sf:data.(trials{k})(kk).end;
                % if this sensor not started before this trial
                if data.(trials{k})(kk).(locations{j}).(sensors{i}).t(1) - allTime(1) < 0
                    
                    % then no data
                    data.(trials{k})(kk).(locations{j}).(sensors{i}).(dname{2}) = [];
                    data.(trials{k})(kk).(locations{j}).(sensors{i}).t = [];
                    
                    % report
                    if option.reportStatus; fprintf('\n\t-WARNING: sensor %s of %s started recording after the start of %s (%d).  This trial will have no data.\n',sensors{i},locations{j},trials{k},kk); end
                    
                else
                    
                    % otherwise resample
                    data.(trials{k})(kk).(locations{j}).(sensors{i}).(dname{2}) = interp1(allTime,...
                                                                                          data.move.(locations{j}).(sensors{i}).(dname{2})',...
                                                                                          data.(trials{k})(kk).(locations{j}).(sensors{i}).t,'pchip')';
                    % save new time
                    data.(trials{k})(kk).(locations{j}).(sensors{i}).t = data.(trials{k})(kk).(locations{j}).(sensors{i}).t - data.(trials{k})(kk).(locations{j}).(sensors{i}).t(1);
                    
                end
                
                % report memory
                if option.reportStatus
                    mem = whos('data');
                    mem = mem.bytes/1024^3;
                    metric = 'GB';
                    if mem < 1
                        mem = mem*1024;
                        metric = 'MB';
                    end
                    if mem < 1
                        mem = mem*1024;
                        metric = 'KB';
                    end
                    fprintf('(Current memory: %3.1f %s)\n',mem,metric);
                end
            end
        end
    end
end


end