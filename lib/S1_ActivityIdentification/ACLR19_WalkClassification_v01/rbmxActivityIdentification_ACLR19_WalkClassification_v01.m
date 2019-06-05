function [ session ] = rbmxActivityIdentification_ACLR19_WalkClassification_v01(session)
%Reed Gurchiek, 2019
%   Uses M-SenseResearchGroup ActivityIdentification toolbox:
%       https://github.com/M-SenseResearchGroup/ActivityIdentification
%   Classifier details in:
%   'Classifier_ACLR19_WalkClassification_RBFSVM_db2_cornerDistance.mat'
%
%   -expects MC10 data (annotations, sensor location folders) to be stored
%   in directory titled 'MC10' on the session.subject.datapath
%
%   -is compatible with ACLR_StrideDetectionSegmentation_v01 event 
%   detector: extracts walking bouts 8 seconds in length
%
%   SETTINGS:
%       -Accelerometer Range: accRange
%       -sEMG Range: emgRange
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
%           -subject.data: recording information, calibration information,
%               walk struct
%           -subject.data.walk: hours walking, counts struct, bout struct
%           -subject.data.walk.bout: n element struct, contains acc and emg
%               data for consecutive 8 second walking bouts
%
%--------------------------------------------------------------------------
%% rbmxActivityIdentification_ACLR19_WalkClassification_v01

% get subject
subject = session.subject;

% load classifier
walkClassifier = load(fullfile(session.rbmxPath,'S1_ActivityIdentification','ACLR19_WalkClassification_v01','Classifier_ACLR19_WalkClassification_RBFSVM_db2_cornerDistance.mat'));

% load home data
sf_acc = walkClassifier.classifier.featureSet.featureDetails.extractorInfo.samplingFrequency;
subject.data.sf_acc = sf_acc;
trial = importMC10(fullfile(subject.datapath,'MC10'),'trialNames','StandingCal','sensors',{'acc','emg'},'locations',{'rectus_femoris_right','rectus_femoris_left'},'resampleACC',sf_acc,'resampleEMG',250,'report',1);
sf_emg = trial.move.rectus_femoris_left.emg.sf;
subject.data.sf_emg = sf_emg;

% recording date time
subject.data.recordingStartDate = datestr(datetime(trial.move.start,'ConvertFrom','posixtime','TimeZone','America/New_York'),'mm/dd/yyyy');
subject.data.recordingStartDay = datestr(datetime(trial.move.start,'ConvertFrom','posixtime','TimeZone','America/New_York'),'dddd');
subject.data.recordingStartTime_EST = [str2double(datestr(datetime(trial.move.start,'ConvertFrom','posixtime','TimeZone','America/New_York'),'HH')),...
                                       str2double(datestr(datetime(trial.move.start,'ConvertFrom','posixtime','TimeZone','America/New_York'),'MM')),...
                                       str2double(datestr(datetime(trial.move.start,'ConvertFrom','posixtime','TimeZone','America/New_York'),'SS'))];
subject.data.recordingStartHour_EST = subject.data.recordingStartTime_EST*[1; 1/60; 1/3600];

% get total time and time array
subject.data.totalRecordingTime = (length(trial.move.rectus_femoris_left.acc.t)-1)/sf_acc;
t_acc = 0:1/sf_acc:subject.data.totalRecordingTime;
t_emg = 0:1/sf_emg:subject.data.totalRecordingTime;
subject.data.totalRecordingTime = subject.data.totalRecordingTime/3600;

% save emg data during calibration for post processing
subject.data.emgCalibration.right = trial.StandingCal.rectus_femoris_right.emg.e;
subject.data.emgCalibration.left = trial.StandingCal.rectus_femoris_left.emg.e;

%% GET FEATURES

% calibrator and processor
calibrator = str2func(walkClassifier.classifier.featureSet.dataDetails.dataCalibrator);
processor = str2func(walkClassifier.classifier.featureSet.dataDetails.dataProcessor);
calibratorInfo = walkClassifier.classifier.featureSet.dataDetails.calibratorInfo;

% calibrate right acc
right_acc = trial.StandingCal.rectus_femoris_right.acc.a;
calibratorInfo.data = right_acc;
processorInfo.calibration.a1 = calibrator(calibratorInfo);

% calibrate left acc
left_acc = trial.StandingCal.rectus_femoris_left.acc.a;
calibratorInfo.data = left_acc;
processorInfo.calibration.a2 = calibrator(calibratorInfo);

% get home data
processorInfo.data.a1 = trial.move.rectus_femoris_right.acc.a;
processorInfo.data.a2 = trial.move.rectus_femoris_left.acc.a;

% process
data = processor(processorInfo);

% get emg data
emgData.e1 = trial.move.rectus_femoris_right.emg.e;
emgData.e2 = trial.move.rectus_femoris_left.emg.e;

% extract features
extractor = str2func(walkClassifier.classifier.featureSet.featureDetails.featureExtractor);
extractorInfo = walkClassifier.classifier.featureSet.featureDetails.extractorInfo;
extractorInfo.data = data;
extractorInfo.reportStatus = 1;
fprintf('-Extracting features\n')
[features,~,indices] = extractor(extractorInfo);

%% CLASSIFY

% status report
fprintf('-Classifying...\n');

% manipulate features
manipulator = str2func(walkClassifier.classifier.featureManipulator.name);
manipulatorInfo = walkClassifier.classifier.featureManipulator.manipulatorInfo;
manipulatorInfo.action = 'manipulate';
manipulatorInfo.features = features;
manipulatorInfo = manipulator(manipulatorInfo);

% classify walk
[walkLabels,walkConfidence] = msenseClassify(walkClassifier.classifier,manipulatorInfo.features);

% get walk time
walkWindows = find(walkLabels == 1);
subject.data.walk.hoursWalking = walkClassifier.classifier.featureSet.featureDetails.extractorInfo.windowSize*length(walkWindows)/3600;

% walk indices
walkIndices = indices(:,walkWindows);
walkConfidence = walkConfidence(walkWindows);

%% GET CONSECUTIVE WALKING BOUTS

fprintf('-Identifying consecutive walking bouts\n')
% get walk bouts
nWalkingBouts = 0;
walkBout = struct();
startWindow = 1;
startSample = walkIndices(1,1);
endSample = walkIndices(2,1);
progressBar = waitbar(0,'Progress: 0%','Name','Storing Consecutive Bouts');
boutDurations = zeros(1,1);
for i = 2:size(walkIndices,2)
    
    waitbar(i/size(walkIndices,2),progressBar,sprintf('Progress: %3.2f%%',i/size(walkIndices,2)*100));
    
    % if not consecutive
    if walkIndices(1,i) ~= endSample + 1
        
        % increment bout
        nWalkingBouts = nWalkingBouts + 1;
        boutDurations(nWalkingBouts) = (endSample - startSample + 1)/sf_acc;
        walkBout(nWalkingBouts).duration = (endSample - startSample + 1)/sf_acc;
        walkBout(nWalkingBouts).timeSinceStart = (startSample - 1)/sf_acc;
        walkBout(nWalkingBouts).nConsecutiveWindows = i - startWindow;
        walkBout(nWalkingBouts).labelConfidence = walkConfidence(startWindow:i-1);
        
        % store data
        walkBout(nWalkingBouts).right.acc = data.a1(:,startSample:endSample);
        walkBout(nWalkingBouts).left.acc = data.a2(:,startSample:endSample);
        
        % convert start/end sample to emg sample
        [~,eStartSample] = min(abs(t_emg - t_acc(startSample)));
        eEndSample = eStartSample + walkBout(nWalkingBouts).duration*sf_emg - 1;
        
        % save emg data
        walkBout(nWalkingBouts).right.emg = emgData.e1(eStartSample:eEndSample);
        walkBout(nWalkingBouts).left.emg = emgData.e2(eStartSample:eEndSample);
        
        % update start/end sample with current
        startSample = walkIndices(1,i);
        endSample = walkIndices(2,i);
        startWindow = i;
        
    % otherwise, if consecutive
    else
        
        % update end sample
        endSample = walkIndices(2,i);
        
    end
    
end

close(progressBar)

%% GET CONSECUTIVE BOUTS 8 SECONDS OR LONGER
    
% get bouts minimumLength seconds or longer
iMinimumLength = find(boutDurations >= 8);
nMinimumLength = length(iMinimumLength);
walkBout = walkBout(iMinimumLength);
    
% for each bout
emgRange = session.activityIdentification.emgRange;
accRange = session.activityIdentification.accRange;
nClipped = 0;
nAnalyze = 0;
for b = 1:nMinimumLength

    % for each 2 consecutive windows
    w = 1;
    while w < walkBout(b).nConsecutiveWindows

        % start/end samples
        istart = round((w-1)*sf_acc*4) + 1;
        iend = istart + round(sf_acc*4*2) - 1; % 2 windows = 8 sec

        % if no clipping
        if ~any(abs(walkBout(b).right.emg(istart:iend)) >= emgRange | abs(walkBout(b).left.emg(istart:iend)) >= emgRange) &&...
           all(~any(abs(walkBout(b).right.acc(:,istart:iend)) >= accRange | abs(walkBout(b).left.acc(:,istart:iend)) >= accRange))

            % increment count
            nAnalyze = nAnalyze + 1;

            % save
            tssc = walkBout(b).timeSinceStart + (istart-1)/31.25;
            subject.data.walk.bout(nAnalyze).timeSinceStartCollecting_Hours = tssc/3600;
            subject.data.walk.bout(nAnalyze).timeSinceStartWalking_Seconds = tssc - walkBout(b).timeSinceStart;
            subject.data.walk.bout(nAnalyze).hourOfDay = tssc/3600 + subject.data.recordingStartHour_EST;
            if subject.data.walk.bout(nAnalyze).hourOfDay > 24
                subject.data.walk.bout(nAnalyze).hourOfDay = subject.data.walk.bout(nAnalyze).hourOfDay - 24;
            end
            subject.data.walk.bout(nAnalyze).right.acc = walkBout(b).right.acc(:,istart:iend);
            subject.data.walk.bout(nAnalyze).left.acc = walkBout(b).left.acc(:,istart:iend);

            % convert start/end for emg
            istart =  round((w-1)*sf_emg*4) + 1;
            iend = istart + round(sf_emg*4*2) - 1;

            % save
            subject.data.walk.bout(nAnalyze).right.emg = walkBout(b).right.emg(istart:iend);
            subject.data.walk.bout(nAnalyze).left.emg = walkBout(b).left.emg(istart:iend);

            % increment
            w = w + 2;
        else
            nClipped = nClipped + 1;
            w = w + 1;
        end
    end

end

% remove zeros, save n bouts
subject.data.walk.counts.nOriginal8SecondBouts = nAnalyze;
subject.data.walk.counts.nClippedBoutsRemoved = nClipped;

fprintf('-Identified %d 8 second walking bouts\n',nAnalyze);

% save
session.subject = subject;

end