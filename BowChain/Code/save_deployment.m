function save_deployment(data,gridded,cfg)
    if isnonemptyfield(cfg,'nc_file')
        fprintf('Saving deployment to %s ...\n',cfg.nc_file)
        write_deployment_to_nc(data,gridded,cfg);
    end
end