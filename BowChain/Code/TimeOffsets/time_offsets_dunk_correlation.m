function offsets = time_offsets_dunk_correlation(data,cfg)

    % initialise the offsets
    offsets = zeros(length(data),1);

    % get the serial number of the sensor we're using as our time base
    if isfield(cfg,'time_base_sensor_sn')
        sensor_sn = cfg.time_base_sensor_sn;
    else
        warning(['No sensor specified as the time base for computing offsets. Using sensor 1.'])
        sensor_sn = cfg.sensor_sn{1};
    end
    % serial numbers should be a char array
    if isnumeric(sensor_sn)
        sensor_sn = num2str(sensor_sn);
    end

    % get the position of the sensor we're using as our time base
    time_base_index = find(strcmp(cfg.sensor_sn,sensor_sn));
    if isempty(time_base_index)
        warning(['Could not find sensor ' cfg.time_base_sensor_sn '. No time offsets calculated.'])
        return 
    end
    time_base_index = time_base_index(1);

    % get the dunk_interval
    if isfield(cfg,'dunk_interval')
        dunk_interval = cfg.dunk_interval;
    else 
        warning(['No dunk interval specified. No time offsets calculated.'])
        return 
    end

    % get the time and temperature for our base 
    base_idx = (data{time_base_index}.dn >= datenum(dunk_interval(1))) & ...
            (data{time_base_index}.dn <= datenum(dunk_interval(2)));
    base_dn = data{time_base_index}.dn(base_idx);
    base_t = data{time_base_index}.t(base_idx);

    % fill in any nans in base_t
    base_t = fillmissing(base_t,'linear');

    % subtract off a mean to make correlation cleaner
    mean_t = mean(base_t);
    base_t = base_t - mean_t;

    for ii = 1:length(offsets)
        if ii == time_base_index
            % skip base time
            continue
        end
        disp(['Computing offset for sensor ' num2str(ii)]);
        offsets(ii) = compute_dunk_offset(data{ii}.dn,data{ii}.t - mean_t,base_dn,base_t);
    end 
end