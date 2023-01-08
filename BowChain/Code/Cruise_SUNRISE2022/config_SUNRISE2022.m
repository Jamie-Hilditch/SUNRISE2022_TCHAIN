%% config_SUNRISE2022.m
% Usage: Called from get_config('SUNRISE2022') in BowChain_master
% Description: Creates a basic deployment configuration structure for all
%              BowChain/Tchain deployments.
% Inputs: none
% Outputs: config structure
%
% Author: Dylan Winters (dylan.winters@oregonstate.edu)
% Created: 2021-06-20

function config = config_SUNRISE2022()

    %% Set some global default options for deployments
    defaults = struct();
    
    % This is the simplest model for initial processing -- just assume that the
    % chain is vertical and compressing like a spring. Get the depth coordinate of
    % each sensor by interpolating between pressure sensors.
    defaults.chain_model = 'cm_straight';
    
    % We should do a "dunk" to calibrate sensor clocks eventually.
    % defaults.time_offset_method = 'cohere';
    % defaults.cohere_interval = [dunk_start_time, dunk_end_time];
    
    % Set this to true to force re-parsing of raw data even if .mat files already
    % exist. Useful in case we find mistakes in parsing functions and need to
    % correct them.
    defaults.raw2mat = false;
    
    % Use the earliest and latest timestamp of all sensors if the start/end time
    % aren't specified. Just in case we're missing a section_start_end_time.csv.
    defaults.dn_range = [-inf inf];
    
    % Grid-averaging settings
    % defaults.bin_method = 'average';
    % defaults.bin_dt = 2;
    % defaults.bin_dz = 1;
    % defaults.bin_zlim = [-30 0];
    
    % Modify user_directories.m for your data location. For me this returns
    % '/home/data/SUNRISE/Tchain', but everyone's local copy will probably be
    % different.
    dir_raw = fullfile(user_directories('SUNRISE2022'),'raw');
    
    %% Create deployment-specific configurations
    % This is where having a consistent file structure does 90% of the work for us!
    % The expected format should look like this:
    %
    % └── Tchain
    %     └── raw
    %         └── Aries
    %             └── deploy_20210618
    %                 ├── 060088_20210618_2140.rsk
    %                 ├── 077416_20210618_1644.rsk
    %                 ├── 077561_20210618_1649.rsk
    %                 ├── 077565_20210618_1647.rsk
    %                 ├── 077566_20210618_2148.rsk
    %                 ├── 077568_20210618_2141.rsk
    %                 ├── 101179_20210618_2145.rsk
    %                 ├── 101180_20210618_2136.rsk
    %                 ├── instrument_depths.csv
    %                 ├── README.txt
    %                 └── section_start_end_time.csv
    
    vessel_raw_folders = dir(fullfile(dir_raw));
    vessel_names = setdiff({vessel_raw_folders.name},{'.','..'});
    
    ndep = 0;
    for v = 1:length(vessel_names)
        deployments = dir(fullfile(dir_raw,vessel_names{v},'deploy*'));
        for i = 1:length(deployments)
            ndep = ndep + 1;
            config(ndep).name = deployments(i).name;
            config(ndep).vessel = vessel_names{v};
    
            % Read the sensors.csv file for instrument deployment positions
            t = readtable(fullfile(deployments(i).folder,deployments(i).name,'instrument_depths.csv'));
            config(ndep).sensor_sn = num2cell(t.serialnum);
            config(ndep).sensor_pos = t.depth_m_;
    
            % Try to read start & end time
            try
                t = readtable(fullfile(deployments(i).folder,deployments(i).name,'section_start_end_time.csv'));
                config(ndep).dn_range = datenum([t.start_time t.end_time]);
            catch err
                % Default to full sensor time range if this fails
                config(ndep).dn_range = [-inf inf];
            end
    
            % Set raw data directory
            config(ndep).dir_raw = fullfile(deployments(i).folder,deployments(i).name);
    
            % Set processed data directory
            config(ndep).dir_proc = strrep(config(ndep).dir_raw,'/raw/','/processed/');
        end
    end
    config = fill_defaults(config,defaults);
    
    %% We can specify any deployment- or vessel-specific settings here
    % There are a bunch of possible ways to do this, below is one example:
    for i = 1:length(config)
        switch config(i).vessel
    
          % ...
        end
    end
    
    
    %% End of config_SUNRISE2022