function [data,time_offsets,pressure_offsets, sensors] = SUNRISE2022_post_offsets_hook(data,time_offsets,pressure_offsets,cfg,sensors)
    % preprocessing code - executed after computing offsets
    % to keep this function organised save your preprocessing code as a
    % script or function in post_offsets_scripts and then run the script here
    
    if strcmp(cfg.vessel,'Pelican') && strcmp(cfg.name,'deploy_20220625')
        [data, pressure_offsets] = Pelican_20220625_sensor_060558_pressure_offset(data,pressure_offsets,sensors);
    end

    if strcmp(cfg.vessel,'Polly') && strcmp(cfg.name,'deploy_20220626')
        [data, time_offsets] = Polly_20220626_sensor_077565_time_offset(data,time_offsets,sensors);
    end
end