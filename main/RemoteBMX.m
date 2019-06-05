%% RemoteBMX
%{
  Reed Gurchiek, 2019
   
    -RemoteBMX is a pipeline for biomechanical analysis of human movement
    in remote environments (i.e. daily life)

    -see README for more information

%}

%% INITIALIZATION

session = rbmx_ProjectInitialization();

%% ACTIVITY IDENTIFICATION

% report/execute
fprintf('\nACTIVITY IDENTIFICATION\n')
session = session.activityIdentification.function(session);

%% EVENT DETECTION

% report/execute
fprintf('\nEVENT DETECTION\n')
session = session.eventDetection.function(session);

%% ANALYSIS

% report/execute
fprintf('\nANALYSIS\n')
session = session.analysis.function(session);
