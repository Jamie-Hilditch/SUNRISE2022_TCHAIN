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
    global_config.chain_model = 'cm_catenary'; %'cm_straight';
    global_config.freq_base = 2;
    global_config.bin_method = 'none';
    global_config.raw2mat = false; % if true force reparse of data;
    global_config.display_figures = false;
    global_config.force_linear = true; % force use of linear interpolation in time
    
    % Get the tchain data directory
    % Use an environment variable rather than user_directories.m
    tchain_dir = getenv('SUNRISE2022_TCHAIN_DATA');
    if isempty(tchain_dir); error("Environment variable 'SUNRISE2022_TCHAIN_DATA' not set"); end
    if ~exist(tchain_dir,'dir'); error("'SUNRISE2022_TCHAIN_DATA' is not a directory"); end


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
    %             └── gps.mat (or ShipDas file)
    %         └── processed_nc (where we save processed files - one netcdf per deployment)
    %         └── sections (individual section files)
    %         └── processing_figures
    %             └── deploy_20210618
    %     └── Pelican
    %         └── raw
    %         └── processed_nc
    %         └── sections
    %         └── processing_figures
    %     └── PointSur
    %         └── raw
    %         └── processed_nc
    %         └── sections
    %         └── processing_figures
    %     └── Polly
    %         └── raw
    %         └── processed_nc
    %         └── sections
    %         └── processing_figures
    
    vessel_names = ["Aries", "Pelican", "PointSur", "Polly"];
  
    ndep = 0;
    for vessel_name = vessel_names
        vessel = char(vessel_name);
        vessel_directory = fullfile(tchain_dir,vessel);
        deployments = dir(fullfile(vessel_directory,'raw','deploy_*'));
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
                zero_pressure_interval = datetime(metadata.zero_pressure_interval);
                if ~any(isnat(zero_pressure_interval))
                    config(ndep).zero_pressure_interval = zero_pressure_interval;
                end
            end

            % dunk_interval
            if isfield(metadata,'dunk_interval') && isfield(metadata,'time_base_sensor_sn')
                dunk_interval = datetime(metadata.dunk_interval);
                if ~any(isnat(dunk_interval))
                    config(ndep).time_offset_method = 'dunk_correlation';
                    config(ndep).dunk_interval = dunk_interval;
                    config(ndep).time_base_sensor_sn = metadata.time_base_sensor_sn;
                end
            end
    
            % Set raw_rsk data directory
            config(ndep).dir_raw = fullfile(deployments(i).folder,deployments(i).name,'raw_rsk');
    
            % Set raw_mat data directory
            config(ndep).dir_proc = fullfile(deployments(i).folder,deployments(i).name,'raw_mat');
            if ~exist(config(ndep).dir_proc,'dir'); mkdir(config(ndep).dir_proc); end

            % Set the processed_nc file
            config(ndep).nc_file = fullfile(vessel_directory,'processed_nc',[deployments(i).name '.nc']);
            if ~exist(fullfile(vessel_directory,'processed_nc'),'dir'); mkdir(fullfile(vessel_directory,'processed_nc')); end

            % Set the figures directory
            config(ndep).dir_fig = fullfile(vessel_directory,'processing_figures',deployments(i).name);
            if ~exist(config(ndep).dir_fig,'dir'); mkdir(config(ndep).dir_fig); end

            % set the gps files
            gps_files.Aries = 'gps.mat';
            gps_files.Pelican = 'SUNRISE2022_PE_ShipDas_Processed.mat';
            gps_files.PointSur = 'SUNRISE2022_PS_ShipDas_Processed.mat';
            gps_files.Polly = 'gps.mat';
            
            if isfield(gps_files,vessel)
                config(ndep).file_gps = fullfile(vessel_directory,'raw',gps_files.(vessel));
            end

        end
    end
    config = fill_defaults(config,global_config);
    
    %% End of config_SUNRISE2022