%% BowChain_master.m
% Usage: BowChain_master(cruise,deployments)
% Inputs:      cruise - name of cruise 
%         deployments - (optional) A string, or cell array of strings, specifying
%                       which deployment(s) to process. By default, all deployments
%                       configured in the cruise's config file are processed.
% Outputs: gridded - gridded dataset (cell array). 
% 
% Author: Dylan Winters (dylan.winters@oregonstate.edu)
%
% Updated February 2023 - Jamie Hilditch (hilditch:stanford.edu)

function [ binned_output, gridded_output, data_output ] = BowChain_master(cruise,vessels,deployments)

arguments 
    cruise (1,:) char
    vessels {mustBeText} = {}
    deployments {mustBeText} = {}
end 

%% Setup
% Add dependencies to path
addpath(genpath('ChainModels'));      % bow chain shape models
addpath(genpath('Config'));           % functions for creating and checking config
addpath(genpath('Gridding'));         % Functions to create time grid
addpath(genpath('Hooks'));            % Hook functions
addpath(genpath('ParseFunctions'));   % instrument parsing functions
addpath(genpath('PreProcessing'));
addpath(genpath('SaveOutput'));       % Write output to file
addpath(genpath('Sensors'));          % Get sensor info
addpath(genpath('TimeOffsets'));      % Sensor clock offset computation methods
addpath(genpath('Utils'));            % Utility functions

addpath(genpath(['Cruise_' cruise])); % cruise-specific functions

config = get_config(cruise,vessels,deployments); % get processing options
ndep = length(config);

% preallocate cell array for output variables 
if nargout >= 1; binned_output = cell(ndep,1); end
if nargout >= 2; gridded_output = cell(ndep,1); end
if nargout == 3; data_output = cell(ndep,1); end

for i = 1:ndep 
    %% Preprocessing
    cfg = config(i);
    fprintf('Processing deployment: %s\n',cfg.name);
    sensors = preproc_setup(cfg);   % set up filepaths & parse funcs
    preproc_raw2mat(cfg,sensors); % convert raw data to .mat files if necessary
    data = proc_load_mat(cfg,sensors); % load raw data
    
    %% Main processing
    % 1) Any user-defined preprocessing
    data = post_load_hook(data,cfg,sensors);

    % 2) Compute and apply time/pressure offsets to raw data
    [data, time_offsets, sensors] = proc_time_offsets(data,cfg,sensors);
    [data, pressure_offsets] = proc_pressure_cal(data,cfg);
    [data, time_offsets, pressure_offsets, sensors] = post_offsets_hook( ...
        data,time_offsets,pressure_offsets,cfg,sensors);
   
    % 3) Sample calibrated data onto uniform time base
    [gridded, sensors] = proc_grid_init(data,cfg,sensors);
    [gridded, sensors] = post_grid_hook(gridded,cfg,sensors);

    % 4) Compute positional offsets using chain shape model
    gridded = proc_chain_model(gridded,cfg);
    [gridded, sensors] = post_chain_hook(gridded,cfg,sensors);
    gridded = proc_gps(gridded,cfg);

    % 5) Add info
    gridded.info.config = cfg;
    gridded.info.sensors = sensors;
    gridded.info.time_offsets = time_offsets;
    gridded.info.pressure_offsets = pressure_offsets;

    % 6) Save processed data
    save_deployment(data,gridded,cfg,sensors);
    save_sections(data,gridded,cfg,sensors);
    
    % 7) Post Processing
    binned = postproc_bin_data(gridded,cfg);

    % 8) Output
    if nargout >= 1; binned_output{i} = binned; end
    if nargout >= 2; gridded_output{i} = gridded; end
    if nargout == 3; data_output{i} = data; end
end

% if specifying a single deployment don't return output in cell arrays
if ischar(vessels) && ischar(deployments)
    if nargout >= 1; binned_output = binned; end
    if nargout >= 2; gridded_output = gridded; end
    if nargout == 3; data_output = data; end
end



