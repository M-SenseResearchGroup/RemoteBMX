function [ session ] = rbmxInitializeProject_ACLR19(session)
%Reed Gurchiek, 2019
%   project for monitoring gait in patients post-surgery (e.g. ACL
%   reconstruction). 
%
%   Example dataset can be requested by email: reed.gurchiek@uvm.edu
%
%   This example dataset specifies data type, format, etc. This application
%   uses tri-axial accelerometer and surface EMG data from MC10 BioStamp
%   nPoint sensors worn over the right and left anterior thigh (muscle
%   belly of rectus femoris). Patients wear the sensors during daily life
%   and must first perform a standing calibration trial (named StandingCal)
%   during which they stand straight up with the thighs vertical relative
%   to the ground.
%
%   SETTINGS (see specific functions for description):
%       -MC10 accelerometer and sEMG range
%       -strideTimeBins
%       -strideTimeNames
%       -minimumDutyFactor
%       -maximumDutyFactor
%       -nMinimumStridesPerBout
%       -emgHighPassCutoff
%       -emgLowPassCutoff
%       -accLowPassCutoff
%       -dataset name
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       struct, specified activityIdentifier, eventDetector, analyzer,
%       subject with specified demographics
%
%--------------------------------------------------------------------------
%% rbmxInitializeProject_ACLR19

% classifier
activityIdentification.name = 'ACLR19_WalkClassification_v01';
activityIdentification.function = str2func('rbmxActivityIdentification_ACLR19_WalkClassification_v01');
activityIdentification.emgRange = 0.2016;
activityIdentification.accRange = 16;

% event detector
eventDetection.name = 'ACLR19_StrideDetectionSegmentation_v01';
eventDetection.function = str2func('rbmxEventDetection_ACLR19_StrideDetectionSegmentation_v01');
eventDetection.strideTimeBins = [0.91 1.57];
eventDetection.strideTimeNames = {'walkNormal'};
eventDetection.nStrideTimeBins = numel(eventDetection.strideTimeNames);
eventDetection.minimumDutyFactor = 0.44;
eventDetection.maximumDutyFactor = 0.73;
eventDetection.nMinimumStridesPerBout = 2;

% analyzer
analysis.name = 'ACLR19_AsymmetryAnalysis_v01';
analysis.function = str2func('rbmxAnalysis_ACLR19_AsymmetryAnalysis_v01');
analysis.emgHighPassCutoff = 30;
analysis.emgLowPassCutoff = 6;
analysis.accLowPassCutoff = 6;
analysis.strideTimeBins = [0.91 1.57];
analysis.strideTimeNames = {'walkNormal'};
analysis.nStrideTimeBins = numel(analysis.strideTimeNames);

% get data path
ok = questdlg('Select the patient directory containing the master.xlsx and the MC10 folder','Data Path','OK',{'OK'});
if isempty(ok); error('Initialization terminated.'); end
datapath = uigetdir;

% read master
[numdata,txtdata] = xlsread(fullfile(datapath,'master.xlsx'),'A2:K2');

% initialize subject structure
subject.dataset = 'RemoteBMX_ExampleDataset';
subject.datapath = datapath;
subject.ID = txtdata{1};
subject.sex = txtdata{2};
subject.injuredLeg = txtdata{5};
if subject.injuredLeg == 'R'
    subject.injuredLeg = 'right';
    subject.healthyLeg = 'left';
    subject.rightLeg = 'injured';
    subject.leftLeg = 'healthy';
else
    subject.injuredLeg = 'left';
    subject.healthyLeg = 'right';
    subject.leftLeg = 'injured';
    subject.rightLeg = 'healthy';
end
subject.age = (numdata(6) - numdata(4))/365.25;
subject.weeksPostop = (numdata(6) - numdata(5))/7;

% save
session.activityIdentification = activityIdentification;
session.eventDetection = eventDetection;
session.analysis = analysis;
session.subject = subject;

end