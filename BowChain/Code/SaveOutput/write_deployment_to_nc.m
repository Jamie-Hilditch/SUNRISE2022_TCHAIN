function write_deployment_to_nc(data,gridded,cfg,sensors)
    
    write_nc(data,gridded,cfg,sensors,cfg.nc_file,cfg.deployment_duration);

end