function save_deployment(data,gridded,cfg,sensors)
    
    if ~cfg.save_output; return; end
    
    if ~isempty(cfg.nc_file)
        fprintf('Saving deployment to %s ...\n',cfg.nc_file)
        write_deployment_to_nc(data,gridded,cfg,sensors);
    end
end