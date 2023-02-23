function [data, sensors] = SUNRISE2022_post_load_hook(data,cfg,sensors)
    % preprocessing code - executed after loading raw mat data
    % to keep this function organised save your preprocessing code as a
    % script or function in post_load_scripts and then run the script here
    
    if strcmp(cfg.vessel,'Aries') && strcmp(cfg.name,'deploy_20220703')
        data = Aries_20220703_sensor_203188_despike_pressure(data,cfg,sensors);
    end
    
    if strcmp(cfg.vessel,'Polly') && strcmp(cfg.name,'deploy_20220626')
        data = Polly_20220626_sensor_077565_remove_bad_temp(data,cfg,sensors);
    end
end