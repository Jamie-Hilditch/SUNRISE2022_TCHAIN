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

    %% Set some global configurations
    global_config = struct();
    global_config.chain_model = 'cm_straight';
    % global_config.time_offset_method = 'cohere';
    % global_config.cohere_interval = [dunk_start_time, dunk_end_time];
    global_config.raw2mat = false; % if true force reparse of data;
    
    % Get the tchain data directory
    % Use an environment variable rather than user_directories.m
    tchain_dir = getenv('SUNRISE2022_TCHAIN_DATA');
    if isempty(tchain_dir); error("Environment variable 'SUNRISE2022_TCHAIN_DATA' not set"); end
    if exist(tchain_dir) ~= 7; error("'SUNRISE2022_TCHAIN_DATA' is not a directory"); end


    %% Create deployment-specific configurations
    % This is where having a consistent file structure does 90% of the work for us!
    % The file structure should look like this:
    %
    % └── tchain_dir
    %     └── Aries
    %         └── raw  
    %             └── deploy_20210618
    %                 └── raw_rsk
    %                 └── raw_mat (Dylan calls these files proc_mat but they're just parsed raw data)
    %                 └── metadata.json
    %                 └── sensors.csv
    %         └── processed_nc (where we save processed files - one netcdf per deployment)
    %         └── sections (individual section files)
    %     └── Pelican
    %         └── raw
    %         └── processed_nc
    %         └── sections
    %     └── PointSur
    %         └── raw
    %         └── processed_nc
    %         └── sections
    %     └── Polly
    %         └── raw
    %         └── processed_nc
    %         └── sections
    
    vessel_names = ["Aries", "Pelican", "PointSur", "Polly"];
  
    ndep = 0;
    for vessel = vessel_names
        vessel_directory = fullfile(tchain_dir,vessel);
        deployments = dir(fullfile(vessel_directory,'raw','deploy*'));
        for i = 1:length(deployments)
            ndep = ndep + 1;
            config(ndep).name = deployments(i).name;
            config(ndep).vessel = vessel;
            
            
            % Read the sensors.csv file for instrument deployment positions
            sensors_csv = fullfile(deployments(i).folder,deployments(i).name,'sensors.csv');
            t = readtable(sensors_csv,NumHeaderLines=0,ReadVariableNames=true,VariableNamingRule="preserve",format='%f%s%f%s%s%u%s');
            config(ndep).sensor_sn = t{:,'serial number'};
            config(ndep).sensor_pos = t{:,'depth [m]'};
            
            % Read in the metadata
            metadata_file = fullfile(deployments(i).folder,deployments(i).name,'metadata.json');
            fid = fopen(metadata_file); 
            raw_metadata = fread(fid,inf); 
            str_metadata = char(raw_metadata'); 
            fclose(fid);
            metadata = jsondecode(str_metadata);

            % deployment duration
            if isfield(metadata,'deployment_duration')
                deployment_duration = datetime(metadata.deployment_duration);
                config(ndep).dn_range = datenum(deployment_duration);
                % fallback for bad date formats
                if isnan(config(ndep).dn_range(1)); 
                    config(ndep).dn_range(1) = -inf
                end
                if isnan(config(ndep).dn_range(2)); 
                    config(ndep).dn_range(2) = inf
                end
            else
                config(ndep).dn_range = [-inf; inf];
            end

            % zero_pressure_interval
            if isfield(metadata,'zero_pressure_interval')
                zero_pressure_interval = datetime(metadata.deployment_duration);
                if ~any(isnat(zero_pressure_interval))
                    config(ndep).zero_pressure_interval = datenum(zero_pressure_interval);
                end
            end
    
            % Set raw_rsk data directory
            config(ndep).dir_raw = fullfile(deployments(i).folder,deployments(i).name,'raw_rsk');
    
            % Set raw_mat data directory
            config(ndep).dir_proc = fullfile(deployments(i).folder,deployments(i).name,'raw_mat');

            % Set the processed_nc file
            config(ndep).nc_file = fullfile(vessel_directory,'processed_nc',deployments(i).name);

            % set the gps file
            % config(ndep).file_gps = '';
        end
    end
    config = fill_defaults(config,global_config);
    
    %% End of config_SUNRISE2022