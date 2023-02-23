%% config_SUNRISE2022.m
% Usage: Called from get_config('SUNRISE2022') in BowChain_master
% Description: Creates a basic deployment configuration structure for all
%              BowChain/Tchain deployments.
% Inputs: none
% Outputs: array of DeploymentConfiguration
%
% Author: Jamie Hilditch (hilditch@stanford.edu)
% Created: January 2022

function config = config_SUNRISE2022()

    %% Set some global configurations
    global_config = DeploymentConfiguration();
    global_config.cruise = 'SUNRISE2022';
    global_config.chain_model = 'cm_catenary';
    global_config.freq_base = 2;
    global_config.bin_method = 'none';
    global_config.raw2mat = false; % if true force reparse of data;
    global_config.display_figures = true;
    global_config.force_linear = true; % force use of linear interpolation in time
    global_config.save_output = true;
    
    % Get the tchain data directorys
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
   
    vessel_names = {'Aries', 'Pelican', 'PointSur', 'Polly'};

    nvessels = length(vessel_names);
    configs = cell(nvessels,1);
  
    for vi = 1:nvessels
        vessel = vessel_names{vi};
        vessel_directory = fullfile(tchain_dir,vessel);
        deployments = dir(fullfile(vessel_directory,'raw','deploy_*'));
        ndep = length(deployments);
        
        % get section times
        switch vessel
            case 'Pelican'
                section_definition = readtable(fullfile(vessel_directory,'raw','PE_section_definition'),NumHeaderLines=0,ReadVariableNames=true,VariableNamingRule="preserve");
                section_times = section_definition{:,["start_time","end_time"]};
            case 'PointSur'
                section_definition = readtable(fullfile(vessel_directory,'raw','PS_section_definition'),NumHeaderLines=0,ReadVariableNames=true,VariableNamingRule="preserve");
                section_times = section_definition{:,["start_time","end_time"]};
            case {'Aries','Polly'}
                section_times = get_rhib_section_times(fullfile(vessel_directory,'raw','section_data'));
            otherwise
                section_times = NaT(0,2);
        end
        
        vessel_config = repmat(global_config,ndep,1);
        for i = 1:ndep
            vessel_config(i).name = deployments(i).name;
            vessel_config(i).vessel = vessel;
            
            
            % Read the sensors.csv file for instrument deployment positions
            sensors_csv = fullfile(deployments(i).folder,deployments(i).name,'sensors.csv');
            t = readtable(sensors_csv,NumHeaderLines=0,ReadVariableNames=true,VariableNamingRule="preserve",Format='%f%s%f%s%s%u%s');
            vessel_config(i).sensor_sn = t{:,'serial number'};
            vessel_config(i).sensor_pos = t{:,'depth [m]'};
            
            % Read in the metadata
            metadata_file = fullfile(deployments(i).folder,deployments(i).name,'metadata.json');
            fid = fopen(metadata_file,'r','n','UTF-8'); 
            char_metadata = fread(fid,[1,inf],'char=>char');
            fclose(fid);
            metadata = jsondecode(char_metadata);

            % deployment duration
            if isfield(metadata,'deployment_duration')
                vessel_config(i).deployment_duration = datetime(metadata.deployment_duration);
            end

            % zero_pressure_interval
            if isfield(metadata,'zero_pressure_interval')
                zero_pressure_interval = datetime(metadata.zero_pressure_interval);
                if ~any(isnat(zero_pressure_interval))
                    vessel_config(i).zero_pressure_interval = zero_pressure_interval;
                end
            end

            % dunk_interval
            if isfield(metadata,'dunk_interval') && isfield(metadata,'time_base_sensor_sn')
                dunk_interval = datetime(metadata.dunk_interval);
                if ~any(isnat(dunk_interval))
                    vessel_config(i).time_offset_method = 'dunk_correlation';
                    vessel_config(i).dunk_interval = dunk_interval;
                    vessel_config(i).time_base_sensor_sn = metadata.time_base_sensor_sn;
                end
            end
    
            % Set raw_rsk data directory
            vessel_config(i).dir_raw = fullfile(deployments(i).folder,deployments(i).name,'raw_rsk');
    
            % Set raw_mat data directory
            vessel_config(i).dir_proc = fullfile(deployments(i).folder,deployments(i).name,'raw_mat');
            if ~exist(vessel_config(i).dir_proc,'dir'); mkdir(vessel_config(i).dir_proc); end

            % Set the processed_nc file
            vessel_config(i).nc_file = fullfile(vessel_directory,'processed_nc',[deployments(i).name '.nc']);
            if ~exist(fullfile(vessel_directory,'processed_nc'),'dir'); mkdir(fullfile(vessel_directory,'processed_nc')); end

            % Set the figures directory
            vessel_config(i).dir_fig = fullfile(vessel_directory,'processing_figures',deployments(i).name);
            if ~exist(vessel_config(i).dir_fig,'dir'); mkdir(vessel_config(i).dir_fig); end

            % Set the sections directory
            vessel_config(i).dir_sections = fullfile(vessel_directory,'sections');
            if ~exist(vessel_config(i).dir_sections,'dir'); mkdir(vessel_config(i).dir_sections); end

            % set the section start and end times (Nx2 datetime array)
            vessel_config(i).section_times = section_times;

            % set the gps files
            gps_files.Aries = 'gps.mat';
            gps_files.Pelican = 'SUNRISE2022_PE_ShipDas_Processed.mat';
            gps_files.PointSur = 'SUNRISE2022_PS_ShipDas_Processed.mat';
            gps_files.Polly = 'gps.mat';
            
            if isfield(gps_files,vessel)
                vessel_config(i).file_gps = fullfile(vessel_directory,'raw',gps_files.(vessel));
            end

            
        end
        configs{vi} = vessel_config;
    end

    % concatenate configs
    config = vertcat(configs{:});
    %% End of config_SUNRISE2022