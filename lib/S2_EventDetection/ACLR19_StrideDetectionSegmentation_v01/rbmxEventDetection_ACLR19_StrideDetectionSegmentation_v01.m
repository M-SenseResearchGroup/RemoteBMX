function [ session ] = rbmxEventDetection_ACLR19_StrideDetectionSegmentation_v01(session)
%Reed Gurchiek, 2019
%   identifies strides and estimates stance/swing phase from 8 seconds of
%   accelerometer data.
%
%   Compatible with ACLR19_WalkClassification_v01 acitivity identifier
%
%   Uses getGaitEvents_ccThighAccelerometer subfunction
%
%   SETTINGS:
%       -strideTimeBins: nx2 array specifying lower bound (column 1) and
%           upper bound (column 2) of stride times to be extracted for
%           analysis. n bins
%       -strideTimeNames: n element cell array where element i gives a name
%           to the strides extracted from row i of strideTimeBins
%       -minimumDutyFactor: minimum allowable duty factor from an extracted
%           stride
%       -maximumDutyFactor: maximum allowable duty factor from an extracted
%           stride
%       -nMinimumStridesPerBout: minimum number of strides which must be
%           extracted from an 8 second bout in order to keep the bout
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with new fields from
%       rbmxActivityIdentification_ACLR19_WalkClassification_v01
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%       new fields:
%           -subject.data.walk.bout.(leg).: strideEnd, swingStart,
%           strideTime, dutyFactor. All are mx1 arrays where m is number of
%           identified strides for leg (leg) (right or left)
%           -also updates counts fields for new bout number and extracted
%           strides
%
%--------------------------------------------------------------------------
%% rbmxEventDetection_ACLR19_StrideDetectionSegmentation_v01

% unpack
subject = session.subject;
n = subject.data.walk.counts.nOriginal8SecondBouts;
asf = subject.data.sf_acc;
nMinimumStridesPerBout = session.eventDetection.nMinimumStridesPerBout;
minimumStrideTime = min(session.eventDetection.strideTimeBins(:,1));
maximumStrideTime = max(session.eventDetection.strideTimeBins(:,2));
minimumDutyFactor = session.eventDetection.minimumDutyFactor;
maximumDutyFactor = session.eventDetection.maximumDutyFactor;

% create time arrays for acc
ta = 0:1/asf:8-1/asf;
    
% for each bout
progressBar = waitbar(0,'Progress: 0%','Name','Event Detection');
side = {'right' 'left'};
subject.data.walk.counts.nOriginalStrides = 0;
b = 1;
while b <= n

    % status
    waitbar(b/n,progressBar,sprintf('Progress: %3.2f%%',b/n*100));
    
    % for each leg
    for l = 1:2

        leg = side{l};
        
        % get events
        events = getGaitEvents_ccThighAccelerometer(subject.data.walk.bout(b).(leg).acc(3,:),asf,ta,minimumStrideTime,maximumStrideTime,nMinimumStridesPerBout);

        % unpack
        deleteBout = events.deleteBout;
        strideStart = events.strideStart;
        swingStart = events.swingStart;

        % if none
        if isempty(strideStart)
            deleteBout = 1;
            break;
        else

            % stride ends are stride starts without first
            strideEnd = strideStart;
            strideStart(end) = [];
            strideEnd(1) = [];

            % FC before first swing start not identified, delete
            swingStart(1) = [];

            % get stride endpoints and check times
            nStrides = length(strideStart);
            subject.data.walk.bout(b).(leg).strideStart = zeros(1,nStrides);
            subject.data.walk.bout(b).(leg).strideEnd = zeros(1,nStrides);
            subject.data.walk.bout(b).(leg).swingStart = zeros(1,nStrides);
            subject.data.walk.bout(b).(leg).strideTime = zeros(1,nStrides);
            subject.data.walk.bout(b).(leg).dutyFactor = zeros(1,nStrides);
            i = 1;
            while i <= nStrides

                deleteStride = 0;

                % get stride time
                strideTime0 = strideEnd(i) - strideStart(i);

                % get duty factor
                dutyFactor0 = (swingStart(i)-strideStart(i))/strideTime0;

                % verify stride time/duty factor within constraints
                if strideTime0 > maximumStrideTime || strideTime0 < minimumStrideTime
                    deleteStride = 1;
                elseif dutyFactor0 > maximumDutyFactor || dutyFactor0 < minimumDutyFactor
                    deleteStride = 1;
                end

                % if didn't meet critieria
                if deleteStride

                    % delete stride
                    strideEnd(i) = [];
                    strideStart(i) = [];
                    swingStart(i) = [];
                    nStrides = nStrides - 1;
                    subject.data.walk.bout(b).(leg).strideStart(i) = [];
                    subject.data.walk.bout(b).(leg).strideEnd(i) = [];
                    subject.data.walk.bout(b).(leg).strideTime(i) = [];
                    subject.data.walk.bout(b).(leg).swingStart(i) = [];
                    subject.data.walk.bout(b).(leg).dutyFactor(i) = [];

                % otherwise save
                else

                    subject.data.walk.bout(b).(leg).strideStart(i) = strideStart(i);
                    subject.data.walk.bout(b).(leg).strideEnd(i) = strideEnd(i);
                    subject.data.walk.bout(b).(leg).strideTime(i) = strideTime0;
                    subject.data.walk.bout(b).(leg).swingStart(i) = swingStart(i);
                    subject.data.walk.bout(b).(leg).dutyFactor(i) = dutyFactor0;
                    i = i + 1;

                end

            end


            % final error check for nMinimumStridesPerBout
            subject.data.walk.bout(b).(leg).nStrides = nStrides;
            if nStrides < nMinimumStridesPerBout

                deleteBout = 1;
                break;

            end

        end

    end

    % handle bout deletion
    if deleteBout
        subject.data.walk.bout(b) = [];
        n = n - 1;
    else
        subject.data.walk.counts.nOriginalStrides = subject.data.walk.counts.nOriginalStrides + subject.data.walk.bout(b).left.nStrides + subject.data.walk.bout(b).right.nStrides;
        b = b + 1;
    end

end
close(progressBar)
fprintf('-Extracted %d strides for %d walking bouts\n',subject.data.walk.counts.nOriginalStrides,n);

% save
subject.data.walk.counts.nBoutsExtractedStrides = n;
session.subject = subject;

end