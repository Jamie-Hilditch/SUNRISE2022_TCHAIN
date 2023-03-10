classdef DeploymentConfiguration

    properties (SetAccess = private, GetAccess = public)
        processing_date (1,1) datetime = datetime('now')
    end

    properties (Access = public)
        binned_period (1,1) duration = seconds(nan)
        bin_dt (1,1) duration = seconds(nan)
        bin_dz (1,1) double 
        bin_method (1,:) char {mustBeMember(bin_method, ...
            {'average','time','space','none'})} = 'none'
        bin_zlim double
        chain_model (1,:) char {mustBeMember(chain_model, ...
            {'cm_straight','cm_segmented','cm_catenary','cm_catenary_old','cm_asiri'})} = 'cm_straight'
        cohere_interval (1,2) datetime = NaT(1,2)
        cruise (1,:) char
        deployment_duration (1,2) datetime = NaT(1,2)
        dir_fig (1,:) char 
        dir_proc (1,:) char
        dir_raw (1,:) char 
        dir_sections (1,:) char
        display_figures (1,1) logical = true
        drift (:,1) duration
        dunk_interval (1,2) datetime = NaT(1,2)
        file_gps (1,:) char
        force_linear (1,1) logical = false % force use of linear interpolation
        freq_base (1,1) double = 2
        name (1,:) char
        nc_file (1,:) char
        raw2mat (1,1) logical = false % force reparsing of raw files
        save_output (1,1) logical = true
        section_times (:,2) datetime = NaT(0,2)
        sensor_pos (:,1) double {mustBeNonnegative}
        sensor_sn (:,1) cell {mustBeText}
        time_base_sensor_sn (1,:) char
        time_drift_measured (1,1) datetime = NaT(1,1)
        time_offset_method (1,:) char {mustBeMember(time_offset_method, ...
            {'known_drift','cohere','dunk_correlation','none'})} = 'none'
        time_synched (1,1) datetime = NaT(1,1)
        vessel (1,:) char
        zero_pressure_interval (1,2) datetime = NaT(1,2)
    end

    properties (Hidden)
        directories = {'dir_fig', 'dir_proc', 'dir_raw', 'dir_sections'}
        required = {'cruise','deployment_duration','dir_proc','dir_raw', ...
            'file_gps','freq_base','name','sensor_pos','sensor_sn','vessel'}
    end

    methods (Access = public)
        function validate_config(obj)
            fprintf('Validating deployment configuration\n')
            for i = 1:numel(obj)
                try
                    obj(i).validate_required_properties()
                    obj(i).validate_directories()
                    obj(i).validate_time_offsets()
                    obj(i).validate_bin_method()
                catch ME
                    fprintf(['Error while validating configuration for cruise ' ...
                        '"%s", vessel "%s", deployment "%s"\n'], ...
                        obj(i).cruise,obj(i).vessel,obj(i).name)
                    rethrow(ME)
                end
            end
        end
    end

    methods (Access = private)
        function validate_required_properties(obj)
            empty = cellfun(@(x) isempty(obj.(x)),obj.required);
            if any(empty)
                fprintf('Required configuration property "%s" is empty\n',obj.required{empty})
                error('Required configuration properties are unset')
            end
        end

        function validate_directories(obj)
            invalid = cellfun(@(x) ~(~isempty(obj.(x)) && isfolder(obj.(x))),obj.directories);
            if any(invalid)
                fprintf('Invalid directory "%s"',obj.directories{invalid})
                error('Invalid directories set')
            end
        end

        function validate_time_offsets(obj)
            switch obj.time_offset_method
                case 'none'
                    return
                case 'known_drift'
                    if isempty(obj.drift) || isnat(obj.time_synched) || isnat(obj.time_drift_measured)
                        error(['drift, time_synched, and time_drift_measured' ... '
                            'configuration properties must be set to use known drift method'])
                    end
                case 'cohere'
                    if any(isnat(obj.cohere_interval))
                        error('cohere_interval just be set to use cohere method')
                    end
                case 'dunk_correlation'
                    if any(isnat(obj.dunk_interval))
                        error('cohere_interval just be set to use cohere method')
                    end
                    if isempty(obj.time_base_sensor_sn) || ~ismember(obj.time_base_sensor_sn,obj.sensor_sn)
                        error('time_base_sensor_sn "%s" not found in sensor_sn',obj.time_base_sensor_sn)
                    end

                otherwise
                    error('Unknown time offset method %s',obj.time_offset_method)
            end
        end

        function validate_bin_method(obj)
            switch obj.bin_method
                case {'none', 'space'}
                    return 
                case 'average'
                    if isnan(obj.bin_dt) || ~(obj.bin_dz > 0) || isempty(obj.bin_zlim)
                        error('bin_dt, bin_dz and bin_zlim must be set to use average bin method')
                    end
                case 'time'
                    if isnan(obj.binned_period)
                        error('binned_period must be set to use time bin method')
                    end
                otherwise 
                    error('Unknown bin method %s',obj.bin_method)
            end

        end
    end
end
