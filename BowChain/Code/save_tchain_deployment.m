function save_tchain_deployment(data,gridded,cfg)
    if isfield(cfg,'nc_file')
        fprintf('Saving deployment to %s ...\n',cfg.nc_file)
        write_deployment_to_nc(data,gridded,cfg);
        fprintf('Done!\n')
    end
end