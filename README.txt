Script: RemoteBMX
Author: Reed D. Gurchiek, reed.gurchiek@uvm.edu, June 2019

SUMMARY:
RemoteBMX is a pipeline for biomechanical analysis of human movement in remote environments (i.e. daily life). There are three basic steps: (1) activity identification: activities being evaluated are identified from wearable sensor data (e.g. walking), (2) event detection: task specific events are identified that may be useful for further analysis (e.g. foot contact and foot off events during walking), and (3) analysis: the various signals from the wearable sensors are processed to compute informative descriptors of the identified tasks. RemoteBMX requires MATLAB version R2018a or later.

HOW TO USE:
An example application of RemoteBMX is monitoring a patient’s gait following surgery. This application is available upon downloading the RemoteBMX package. An example dataset for this application is available at: https://www.uvm.edu/~rsmcginn/lab.html. The first step in designing a new application is to create a project. Project’s are given a name (e.g. projectName) and consist of a directory within RemoteBMX/lib/S0_ProjectInitialization which must be named ‘rbmxProject_projectName’ within which contain project specific functions/files for initiating the project, one of which must be a function named ‘rbmxInitializeProject_projectName’. The example project is titled ‘ACLR19’.

The ‘rbmxInitializeProject_projectName’ function initializes a ‘session’ MATLAB struct which specifies which activity identifier to use, which event detector to use, which analysis function to use, function specific parameters, and contains imported patient specific data. IMPORTANT: the way data is imported and structured in the MATLAB environment must be compatible with all functions used in the pipeline. All rbmx* functions should accept the ‘session’ struct as input and output the same ‘session’ struct with updated fields.

Activity identifiers consist of a directory within RemoteBMX/lib/S1_ActivityIdentification/ which is given a name ‘activityIdentifierName’ within which contain identifier specific functions/files for activity identification, one of which must be a function named ‘rbmxActivityIdentification_activityIdentifierName’. The example activity identifier is titled ‘ACLR19_WalkClassification_v01’ and is accompanied by the .mat file ‘Classifier_ACLR19_WalkClassification_RBFSVM_db2_cornerDistance.mat’.

Event detectors consist of a directory within RemoteBMX/lib/S2_EventDetection/ which is given a name ‘eventDetectorName’ within which contain detector specific functions/files for event detection, one of which must be a function named ‘rbmxEventDetection_eventDetectorName’. The example event detector is ‘ACLR19_StrideDetectionSegmentation_v01’ and is accompanied by the MATLAB function ‘getGaitEvents_ccThighAccelerometer.m’.

Analyzers consist of a directory within RemoteBMX/lib/S3_Analysis/ which is given a name ‘analysisName’ within which contain analyzer specific functions/files for analysis, one of which must be a function named ‘rbmxAnalysis_analysisName’. The example analysis is ‘ACLR19_AsymmetryAnalysis_v01’.

To use the example application, download the RemoteBMX package and the M-Sense Research Group ActivityIdentification package (https://github.com/M-SenseResearchGroup/ActivityIdentification) and add them to the MATLAB path. Download example dataset: https://www.uvm.edu/~rsmcginn/lab.html. In the MATLAB command window, type ‘RemoteBMX’ and press ‘enter’.

