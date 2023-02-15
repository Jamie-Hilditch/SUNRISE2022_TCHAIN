%% BowChain_master.m
% Usage: BowChain_master(cruise,deployments)
% Inputs:      cruise - name of cruise 
%         deployments - (optional) A string, or cell array of strings, specifying
%                       which deployment(s) to process. By default, all deployments
%                       configured in the cruise's config file are processed.
% Outputs: gridded - gridded dataset (cell array). 
% 
% Author: Dylan Winters (dylan.winters@oregonstate.edu)

function [ gridded_output, data_output ] = BowChain_master(cruise,varargin)

%% Setup
% Add dependencies to path
addpath(genpath('ChainModels'));      % bow chain shape models
addpath(genpath('Config'));           % functions for creating and checking config
addpath(genpath('Gridding'));         % Functions to create time grid
addpath(genpath('Hooks'));            % Hook functions
addpath(genpath('ParseFunctions'));   % instrument parsing functions
addpath(genpath('SaveOutput'));       % Write output to file
addpath(genpath('Sensors'));          % Get sensor info
addpath(genpath('TimeOffsets'));      % Sensor clock offset computation methods
addpath(genpath('Utils'));            % Utility functions

addpath(genpath(['Cruise_' cruise])); % cruise-specific functions

config = get_config(cruise,varargin{:}); % get processing options
ndep = length(config);

% preallocate cell array for output variables 
if nargout >= 1; gridded_output = cell(ndep,1); end
if nargout >= 2; data_output = cell(ndep,1); end

for i = 1:ndep 
    %% Preprocessing
    cfg = config(i);
    fprintf('Processing deployment: %s\n',cfg.name);
    cfg = preproc_setup(cfg);   % set up filepaths & parse funcs
    preproc_raw2mat(cfg); % convert raw data to .mat files if necessary
    [data, cfg] = proc_load_mat(cfg); % load raw data
    
    %% Main processing
    % 1) Any user-defined preprocessing
    [data, cfg] = post_load_hook(data,cfg);
    % 2) Compute and apply time/pressure offsets to raw data
    [data, time_offsets] = proc_time_offsets(data,cfg);
    [data, pressure_offsets] = proc_pressure_cal(data,cfg);
   
    % 3) Sample calibrated data onto uniform time base
    [gridded, cfg] = proc_grid_init(data,cfg);
    gridded = post_grid_hook(gridded,cfg);
    gridded.info.config = cfg;
    gridded.info.time_offsets = time_offsets;
    gridded.info.pressure_offsets = pressure_offsets;

    % 4) Compute positional offsets using chain shape model
    gridded = proc_chain_model(gridded,cfg);
    gridded = post_chain_hook(gridded,cfg);
    gridded = proc_gps(gridded,cfg);
    
    % 5) Post-processing
    gridded = postproc_grid_data(gridded,cfg);

    % 6) Save
    save_deployment(data,gridded,cfg);
    save_sections(data,gridded,cfg);

    % 7) Output
    if nargout >= 1; gridded_output{i} = gridded; end
    if nargout >= 2; data_output{i} = data; end
end

