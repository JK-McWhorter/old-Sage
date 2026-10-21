function dirs = SetupDirs_sage
% ************************************************************************
% SetupDirs_sage.m
% ************************************************************************
%
% Sets up directories referenced throughout GUI.
%
% USE AS:  DIRS = SetupDirs_sage;
%
% OUTPUTS: DIRS: structure containing directory paths used throughout the
%                sage GUI.
%
% UPDATES: Updated 3/8/17 to allow gui user to more easily work from
%          preferred directory location.
%          Updated 10/25/2017 to improve path install process.
%          Updated 11/13/24 to WOA2023 TM
% NOTES:   Before launching SageO2, be sure you have run INSTALL_sageO2
%          from ../ARGO_PROCESSING/MFILES/GUIS/SAGE_O2/.
% ************************************************************************

fp = filesep; % File separator for current platform

try
    load sage_workingDIR.mat % loads 'topdir', 'msgfile_dir', 'MBARInet'
catch
    warning('Problem loading sage_workingDIR.mat. Did you run INSTALL_sage from ../ARGO_PROCESSING/MFILES/GUIS/SAGE/ ?')
    topdir = [getenv('USERPROFILE'), fp, 'Documents', fp, 'MATLAB', fp];
end

% Ensure topdir ends with a file separator
if ~endsWith(topdir, fp)
    topdir = [topdir, fp];
end

% Set up directory paths
dirs.user_dir  = topdir;
dirs.mfiles    = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'MFILES', fp];
dirs.woa = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'WOA2023', fp];
dirs.glodap    = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'GLODAP', fp];
dirs.mat       = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'FLOATS', fp];
dirs.cal       = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'CAL', fp];
dirs.FVlocal   = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'FLOATVIZ', fp];
dirs.FV        = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'FLOATVIZ', fp];
%dirs.FV       = '\\sirocco\wwwroot\lobo\Data\FloatVizData\';
dirs.QCadj     = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'CAL', fp, 'QC_LISTS', fp];
dirs.bottle    = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'SHIPBOARD', fp];
dirs.QC_images = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'QC_images', fp];
dirs.CANY      = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'CANYON', fp];
% Update dirs.ESPER to reference MFILES folder:
dirs.ESPER = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'MFILES', fp, 'ESPER', fp];
dirs.LIR       = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'LIAR', fp]; 

addpath(genpath('C:\Users\Jennifer.McWhorter\Documents\MATLAB\ARGO_PROCESSING\MFILES\ESPER'));
savepath;

if ~isempty(strfind(computer, 'PC'))
    dirs.temp  = ['C:', fp, 'temp', fp];
else
    dirs.temp  = [getenv('HOME'), fp, 'temp', fp];
end

% Ensure temp directory exists
if ~exist(dirs.temp, 'dir')
    mkdir(dirs.temp);
end

% msg file directories (MBARI). Comment out if not used.
dirs.msg       = [dirs.user_dir, 'ARGO_PROCESSING', fp, 'DATA', fp, 'ARGO_REPO', fp];
% dirs.msg     = '\\seaecho.shore.mbari.org\floats\';
% dirs.alt     = '\\atlas\ChemWebData\floats\alternate\'; 
% dirs.msg_comb = '\\atlas\ChemWebData\floats\combined\';

end