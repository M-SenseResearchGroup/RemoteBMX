function [ session ] = rbmx_ProjectInitialization()
%Reed Gurchiek, 2019
%   initialize RemoteBMX session struct and specify project
%
%----------------------------------INPUTS----------------------------------
%
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       struct
%       -Fields:
%           1) date: string; day-month-year
%           2) rbmxPath: string; path to .../RemoteBMX/lib/
%           3) project: string; project name
%           4,...) fields from rbmxInitializeProject_projectName
%               -activityIdentification: struct; name, function, other
%               -eventDetection: struct; name, function, other
%               -analysis: struct; name, function
%               -other: e.g. subject with subject demographics, etc.
%
%--------------------------------------------------------------------------
%% rbmx_ProjectInitialization

close all
clear
clc

% get project
rbmxpath = replace(which('rbmx_ProjectInitialization'),'rbmx_ProjectInitialization.m','');
projects = dir(fullfile(rbmxpath,'S0_ProjectInitialization','rbmxProject_*'));
project = cell(1,length(projects));
for p = 1:length(project)
    project{p} = projects(p).name(13:end);
end
iproject = listdlg('ListString',project,'SelectionMode','Single','PromptString','Select Project');
project = project{iproject};

% save to session
session.date = date;
session.rbmxPath = rbmxpath;
session.project = project;

% initialize project
func = str2func(['rbmxInitializeProject_' project]);
session = func(session);

end