function write_sections_to_nc(data,gridded,cfg)
   
    
    % get start and end time of deployment
    deployment_range = datetime(cfg.dn_range,'ConvertFrom','datenum');
    
    % check section times is the correct shape
    size_sections = size(cfg.section_times);
    if size_sections(2) ~= 2; error('Config section times must be an Nx2 datetime array'); end

    % loop through sections
    for i = 1:size_sections(1)
        
        % get start and end time
        start_time = cfg.section_times(i,1);
        end_time = cfg.section_times(i,2);

        % continue if section time is before or after deployment
        if isnat(start_time) || isnat(end_time); continue; end
        if start_time > deployment_range(2); continue; end
        if end_time < deployment_range(1); continue; end

        % construct file name
        start_time.Format = 'yyyyMMdd-HHmm';
        filename = fullfile(cfg.dir_sections,sprintf('%s_%s_%s.nc',cfg.cruise,cfg.vessel,start_time));

        % write the netcdf 
        write_nc(data,gridded,cfg,filename,cfg.section_times(i,:));

        fprintf('\tCreated section file: %s\n',filename);
    end
end
