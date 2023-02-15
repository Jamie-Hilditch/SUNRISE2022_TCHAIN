function write_deployment_to_nc(data,gridded,cfg)
    
    write_nc(data,gridded,cfg,cfg.nc_file,datetime(cfg.dn_range,'ConvertFrom','datenum'));

end