function [ session ] = rbmxAnalysis_ACLR19_AsymmetryAnalysis_v01(session)
%Reed Gurchiek, 2019
%   computes indices of bilateral asymmetry for strides extracted from 8
%   second walking bouts
%
%   Compatible with ACLR19_StrideDetectionSegmentation_v01 event detector
%
%   sEMG Processing: high pass, rectify, low pass, normalize. high pass and
%   low pass cutoffs are function settings. data are normalized to mean emg
%   amplitude during stride (since MVC may not be available very soon after
%   surgery and largely variable sensor bias throughout day).
%
%   Expects the subject injured leg to be specified in
%   session.subject.injuredLeg = 'right' or 'left'
%
%   SETTINGS:
%       -emgHighPassCutoff: see sEMG Processing
%       -emgLowPassCutoff: see sEMG Processing
%       -accLowPassCutoff: low pass filter cutoff frequency for
%           accelerometer data. Recommend 6 Hz for walking
%       -also strideTimeNames, strideTimeBins (see StrideStanceSwing_v1
%           event detector)
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%       new fields:
%           -subject.data.walk.boutMetrics: variables characterizing
%           strides during identified 8 second walking bouts. Also contains
%           tri-axial thigh acceleration and sEMG time series normalized by
%           stride time for each leg (Healthy or Injured).
%           -subject.data.walk.counts: stride counts, bouts analyzed, etc.
%
%--------------------------------------------------------------------------
%% rbmxAnalysis_ACLR19_AsymmetryAnalysis_v01

% unpack
subject = session.subject;
emgHP = session.analysis.emgHighPassCutoff;
emgLP = session.analysis.emgLowPassCutoff;
accLP = session.analysis.accLowPassCutoff;
nStrideTimes = session.analysis.nStrideTimeBins;
strideTimeNames = session.analysis.strideTimeNames;
n = subject.data.walk.counts.nBoutsExtractedStrides;
strideTimeBins = session.analysis.strideTimeBins;
asf = subject.data.sf_acc;
esf = subject.data.sf_emg;

% create time arrays for emg and acc
ta = 0:1/asf:8-1/asf;
te = 0:1/esf:8-1/esf;

% metrics pulled from each bout (average of each stride during bout)
strideMetrics = {'strideTime' 'dutyFactor' 'emgMean_Stance' 'emgMean_Swing'};

% asymmetries for the following variables will be checked for outliers after analysis, outliers removed
timeSeries = {'emg' 'ap' 'ml' 'cc'};
outlierVariables = {'dutyFactorAsymmetry' 'emgMean_StanceAsymmetry' 'emgMean_SwingAsymmetry' 'ccAsymmetry' 'mlAsymmetry' 'apAsymmetry' 'emgAsymmetry' 'compositeAsymmetry'};

% status
status = {'healthy' 'injured'};
statusLeg = {'left' 'right'};
if subject.injuredLeg(1) == 'r'
    injured = 'right';
    healthy = 'left';
else
    injured = 'left';
    healthy = 'right';
    statusLeg = {'right' 'left'};
end
    
% analyze
subject.analyzed = 1;
if n == 0
    subject.analyzed = 0;
    fprintf('-No strides extracted\n');
else

    % stride counter
    for st = 1:nStrideTimes
        subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_healthyLeg']) = cell(n,1);
        subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_injuredLeg']) = cell(n,1);
    end

    % x is medio lateral (lateral > 0), y anterior posterior (anterior > 0), z cranial caudal (up > 0)
    % to make x positive = lateral, need to negate left leg    
    lateral = struct('right',1,'left',-1);

    % initialize bout wise analysis
    % start with empty cell arrays then convert to matrix at end
    for st = 1:nStrideTimes
        subject.data.walk.boutMetrics.(strideTimeNames{st}).hourOfDay = cell(n,1);
        subject.data.walk.boutMetrics.(strideTimeNames{st}).strideTime = cell(n,1);
        subject.data.walk.boutMetrics.(strideTimeNames{st}).timeSinceStartWalking_Seconds = cell(n,1);
        for v = 1:length(strideMetrics)
            subject.data.walk.boutMetrics.(strideTimeNames{st}).([strideMetrics{v} 'Healthy']) = cell(n,1);
            subject.data.walk.boutMetrics.(strideTimeNames{st}).([strideMetrics{v} 'Injured']) = cell(n,1);
            subject.data.walk.boutMetrics.(strideTimeNames{st}).([strideMetrics{v} 'Asymmetry']) = cell(n,1);
        end

        % for each leg
        for l = 1:2
            % and each time series
            for iser = 1:length(timeSeries)
                % allocate space for normalized time series
                subject.data.walk.boutMetrics.(strideTimeNames{st}).([timeSeries{iser} cap(status{l})]) = cell(n,1);
            end
        end
        % allocate space for time series correlation (symmetry)
        for iser = 1:length(timeSeries)
            subject.data.walk.boutMetrics.(strideTimeNames{st}).([timeSeries{iser} 'Asymmetry']) = cell(n,1);
        end
        subject.data.walk.boutMetrics.(strideTimeNames{st}).compositeAsymmetry = cell(n,1);
    end

    % for each bout
    progressBar = waitbar(0,'Progress: 0%','Name','Asymmetry Analysis');
    for b = 1:n
        
        % status
        waitbar(b/n,progressBar,sprintf('Progress: %3.2f%%',b/n*100));

        % get stride time bin of bout
        boutStrideTime = 0;
        meanStrideTime = mean([subject.data.walk.bout(b).(healthy).strideTime subject.data.walk.bout(b).(injured).strideTime]);
        for st = 1:nStrideTimes
            if meanStrideTime >= strideTimeBins(st,1) && meanStrideTime <= strideTimeBins(st,2)
                boutStrideTime = strideTimeNames{st};
                break;
            end
        end

        % hour of day, time since start walking, stride time
        subject.data.walk.boutMetrics.(boutStrideTime).hourOfDay{b} = subject.data.walk.bout(b).hourOfDay;
        subject.data.walk.boutMetrics.(boutStrideTime).strideTime{b} = meanStrideTime;
        subject.data.walk.boutMetrics.(boutStrideTime).timeSinceStartWalking_Seconds{b} = subject.data.walk.bout(b).timeSinceStartWalking_Seconds;

        % initialize metrics
        for v = 1:length(strideMetrics)
            subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Healthy']){b} = 0;
            subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Injured']){b} = 0;
        end
        for iser = 1:length(timeSeries)
            subject.data.walk.boutMetrics.(boutStrideTime).([timeSeries{iser} 'Healthy']){b,:} = zeros(1,101);
            subject.data.walk.boutMetrics.(boutStrideTime).([timeSeries{iser} 'Injured']){b,:} = zeros(1,101);
        end

        % for each leg
        for l = 1:2

            % leg being analyzed
            leg = status{l};
            side = statusLeg{l};

            % get stride time and duty factor
            subject.data.walk.boutMetrics.(boutStrideTime).(['strideTime' cap(leg)]){b} =  mean(subject.data.walk.bout(b).(side).strideTime);
            subject.data.walk.boutMetrics.(boutStrideTime).(['dutyFactor' cap(leg)]){b} =  mean(subject.data.walk.bout(b).(side).dutyFactor);

            % get emg envelope
            emg = bwfilt(abs(bwfilt(subject.data.walk.bout(b).(side).emg,emgHP,esf,'high',4)),emgLP,esf,'low',4);

            % get bout acceleration
            acc = subject.data.walk.bout(b).(side).acc;

            % get sensor heading
            h = pca(bwfilt(acc(1:2,:),2,asf,'low',4)');
            h = h(:,1);
            dcm.(status{l}) = [ h(2) -h(1) 0;...
                                h(1)  h(2) 0;...
                                  0    0   1];

            % if negative axis pointing forward
            if mean(acc(1,:)) < 0
                % then negate upper left 2x2 block
                dcm.(status{l})(1:2,1:2) = -dcm.(status{l})(1:2,1:2);
            end

            % low pass and get transverse plane values for analysis
            acc = dcm.(leg)*bwfilt(acc,accLP,asf,'low',4);

            % make lateral acceleration positive
            acc(1,:) = lateral.(side)*acc(1,:);

            % for each stride
            nStrides = subject.data.walk.bout(b).(side).nStrides;
            subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_' leg 'Leg']){b} = nStrides;
            for str = 1:nStrides

                % get acc time array for current stride
                tanew = [subject.data.walk.bout(b).(side).strideStart(str),...
                         ta(ta > subject.data.walk.bout(b).(side).strideStart(str) & ta < subject.data.walk.bout(b).(side).strideEnd(str)),...
                         subject.data.walk.bout(b).(side).strideEnd(str)];

                % get acc data at stride enpoints
                nacc = interp1(ta,acc',tanew,'pchip')';

                % resample acc to 101 points (percent stride)
                nacc = interp1((tanew-tanew(1))/(tanew(end)-tanew(1))*100,nacc',0:100,'pchip')';
                subject.data.walk.boutMetrics.(boutStrideTime).(['ap' cap(leg)]){b} = subject.data.walk.boutMetrics.(boutStrideTime).(['ap' cap(leg)]){b} + nacc(2,:)./nStrides;
                subject.data.walk.boutMetrics.(boutStrideTime).(['ml' cap(leg)]){b} = subject.data.walk.boutMetrics.(boutStrideTime).(['ml' cap(leg)]){b} + nacc(1,:)./nStrides;
                subject.data.walk.boutMetrics.(boutStrideTime).(['cc' cap(leg)]){b} = subject.data.walk.boutMetrics.(boutStrideTime).(['cc' cap(leg)]){b} + nacc(3,:)./nStrides;

                % get emg time array for current stride
                tenew = [subject.data.walk.bout(b).(side).strideStart(str),...
                         te(te > subject.data.walk.bout(b).(side).strideStart(str) & te < subject.data.walk.bout(b).(side).strideEnd(str)),...
                         subject.data.walk.bout(b).(side).strideEnd(str)];

                % get emg data at stride enpoints
                nemg = interp1(te,emg,tenew,'pchip');

                % resample emg to 101 points (percent stride)
                nemg = interp1((tenew-tenew(1))/(tenew(end)-tenew(1))*100,nemg,0:100,'pchip');

                % get mean emg and normalize
                nemg = nemg/mean(nemg);
                subject.data.walk.boutMetrics.(boutStrideTime).(['emg' cap(leg)]){b} = subject.data.walk.boutMetrics.(boutStrideTime).(['emg' cap(leg)]){b} + nemg./nStrides;

                % swing start sample
                isw = round(subject.data.walk.bout(b).(side).dutyFactor(str)*100)+1;

                % get mean emg in stance and swing
                subject.data.walk.boutMetrics.(boutStrideTime).(['emgMean_Stance' cap(leg)]){b} =  subject.data.walk.boutMetrics.(boutStrideTime).(['emgMean_Stance' cap(leg)]){b} + mean(nemg(1:isw))./nStrides;
                subject.data.walk.boutMetrics.(boutStrideTime).(['emgMean_Swing' cap(leg)]){b} =  subject.data.walk.boutMetrics.(boutStrideTime).(['emgMean_Swing' cap(leg)]){b} + mean(nemg(isw+1:end))./nStrides;

            end

        end

        % asymmetry analysis
        for v = 1:length(strideMetrics)
            subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Asymmetry']){b} = abs((subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Injured']){b} - ...
                                                                                                      subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Healthy']){b})/ ...
                                                                                                      subject.data.walk.boutMetrics.(boutStrideTime).([strideMetrics{v} 'Healthy']){b});
        end

        % time series correlation
        % correlation is an index of symmetry, we want asymmetry
        % correlation range from -1 to 1
        % so transform so that corr = 1 is 0 and = -1 is 1
        subject.data.walk.boutMetrics.(boutStrideTime).emgAsymmetry{b} = 0.5*(1-corr(subject.data.walk.boutMetrics.(boutStrideTime).emgHealthy{b}',subject.data.walk.boutMetrics.(boutStrideTime).emgInjured{b}'));
        subject.data.walk.boutMetrics.(boutStrideTime).apAsymmetry{b}  = 0.5*(1-corr(subject.data.walk.boutMetrics.(boutStrideTime).apHealthy{b}',subject.data.walk.boutMetrics.(boutStrideTime).apInjured{b}'));
        subject.data.walk.boutMetrics.(boutStrideTime).mlAsymmetry{b}  = 0.5*(1-corr(subject.data.walk.boutMetrics.(boutStrideTime).mlHealthy{b}',subject.data.walk.boutMetrics.(boutStrideTime).mlInjured{b}'));
        subject.data.walk.boutMetrics.(boutStrideTime).ccAsymmetry{b}  = 0.5*(1-corr(subject.data.walk.boutMetrics.(boutStrideTime).ccHealthy{b}',subject.data.walk.boutMetrics.(boutStrideTime).ccInjured{b}'));

        % composite score
        subject.data.walk.boutMetrics.(boutStrideTime).compositeAsymmetry{b} = mean([subject.data.walk.boutMetrics.(boutStrideTime).emgAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).apAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).mlAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).ccAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).dutyFactorAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).emgMean_StanceAsymmetry{b},...
                                                                                     subject.data.walk.boutMetrics.(boutStrideTime).emgMean_SwingAsymmetry{b}]);

    end

    % for each stride time, convert to matrix to get rid of empty elements
    fields = fieldnames(subject.data.walk.boutMetrics.(strideTimeNames{1}));
    for st = 1:nStrideTimes
        % get rid of each empty element
        for ifield = 1:length(fields)
            subject.data.walk.boutMetrics.(strideTimeNames{st}).(fields{ifield}) = cell2mat(subject.data.walk.boutMetrics.(strideTimeNames{st}).(fields{ifield}));
        end
        subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_healthyLeg']) = cell2mat(subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_healthyLeg']));
        subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_injuredLeg']) = cell2mat(subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_injuredLeg']));
    end

    % get bout wise asymmetry outliers
    fprintf('-Outliers: ');
    for st = 1:nStrideTimes
        ioutliers.(strideTimeNames{st}) = [];
        for v = 1:length(outlierVariables)

            % get 25th and 75th quantiles
            q75 = quantile(subject.data.walk.boutMetrics.(strideTimeNames{st}).(outlierVariables{v}),0.75);
            q25 = quantile(subject.data.walk.boutMetrics.(strideTimeNames{st}).(outlierVariables{v}),0.25);
            iqr = (q75-q25);

            % outliers are those 1.5 IQR's greater (lesser) than q75
            % (q25). This is the matlab default for boxplots.
            % Corresponds to about 2.7 sd and 99.3 percent of the data
            % if normally distributed
            ub = q75 + 1.5*iqr;
            lb = q25 - 1.5*iqr;
            ioutliers.(strideTimeNames{st}) = vertcat(ioutliers.(strideTimeNames{st}),find(subject.data.walk.boutMetrics.(strideTimeNames{st}).(outlierVariables{v}) > ub));
            ioutliers.(strideTimeNames{st}) = vertcat(ioutliers.(strideTimeNames{st}),find(subject.data.walk.boutMetrics.(strideTimeNames{st}).(outlierVariables{v}) < lb));
        end
        ioutliers.(strideTimeNames{st}) = unique(ioutliers.(strideTimeNames{st}));  
        fprintf('%d %s, ',length(ioutliers.(strideTimeNames{st})),strideTimeNames{st});
    end
    fprintf('\b\b\n');

    % remove outliers
    subject.data.walk.outlierBouts = ioutliers;
    for st = 1:nStrideTimes
        for ifield = 1:length(fields)
            subject.data.walk.boutMetrics.(strideTimeNames{st}).(fields{ifield})(ioutliers.(strideTimeNames{st}),:) = [];
        end
        % remove outliers from stride count and sum
        for l = 1:2
            leg = status{l};
            subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_' leg 'Leg'])(ioutliers.(strideTimeNames{st})) = [];
            subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_' leg 'Leg']) = sum(subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_' leg 'Leg']));
        end
        subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_Total']) = ...
            subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_injuredLeg']) + subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_healthyLeg']);
    end

    % final bout count
    fprintf('-Number of bouts analyzed:\n');
    for st = 1:nStrideTimes
        subject.data.walk.counts.(['nBoutsAnalyzed_' strideTimeNames{st}]) = numel(subject.data.walk.boutMetrics.(strideTimeNames{st}).strideTime);
        fprintf('\t-Stride Time Bin (%d) %s: %d bouts\n',st,strideTimeNames{st},subject.data.walk.counts.(['nBoutsAnalyzed_' strideTimeNames{st}]));
    end

    % report
    fprintf('-Number of strides analyzed:\n');
    for st = 1:nStrideTimes
        fprintf('\t-Stride Time Bin (%d) %s: %d strides (%d healthy, %d injured)\n',st,strideTimeNames{st},...
                                                                                    subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_Total']),...
                                                                                    subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_healthyLeg']),....
                                                                                    subject.data.walk.counts.(['nStrides_' strideTimeNames{st} '_injuredLeg']));
    end
end

close(progressBar)

% save
session.subject = subject;
saveAnswer = questdlg('Select directory to save analysis too.','Save','Ok','Do Not Save','Do Not Save');
if saveAnswer(1) == 'O'
    savePath = uigetdir(session.subject.datapath);
    saveName = inputdlg('Save As:','Filename',[1 100],{['RemoteBMX_' session.subject.ID '_' replace(session.date,'-','')]});
    save(fullfile(savePath,saveName{1}),'session');
end

end