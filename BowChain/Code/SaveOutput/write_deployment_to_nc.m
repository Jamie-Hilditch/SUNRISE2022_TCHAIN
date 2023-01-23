function write_deployment_to_nc(data,gridded,cfg)
    
    % possible variables with sensor and time dimensions
    possible_vars = {'t';'p';'s';'x';'z';'lat';'lon'};
    
    % map variable names to units and long_names
    long_names.time = "Time";
    long_names.dn = "datenum";
    long_names.pos = "Position on chain";
    long_names.offsets = "Time offsets applied";
    long_names.t = "Temperature";
    long_names.p = "Pressure";
    long_names.c = "Conductivity";
    long_names.s = "Salinity";
    long_names.x = "Horizontal displacement";
    long_names.z = "Vertical displacement";
    long_names.lat = "Latitude";
    long_names.lon = "Longitude";
    long_names.catenary_a = "Catenary length scale";
    % units
    units.time = "seconds since 1970-01-01 0:0:0";
    units.dn = "MATLAB datenum";
    units.pos = "m";
    units.offsets = "days";
    units.t = "degC";
    units.p = "dbar";
    units.c = "mS/cm";
    units.s = "PSU";
    units.x = "m";
    units.z = "m";
    units.lat = "degrees_north";
    units.lon = "degrees_east";
    units.catenary_a = "m";
    
    % create a netcdf4 file overwriting (CLOBBER) an existing file
    cmode = bitor(netcdf.getConstant('NETCDF4'),netcdf.getConstant('CLOBBER'));
    ncid = netcdf.create(cfg.nc_file,cmode);

    % close the file when we exit even if due to an error
    cleanup_obj = onCleanup(@() netcdf.close(ncid));

    % create a group for gridded and ungridded data
    grid_id = netcdf.defGrp(ncid,'gridded');
    ungd_id = netcdf.defGrp(ncid,'ungridded');

    % define dimensions in the gridded group
    time_dim_id = netcdf.defDim(grid_id,'time',length(gridded.dn));
    sensor_dim_id = netcdf.defDim(grid_id,'sensor_number',length(gridded.pos));

    % define variables in the gridded group
    % time, dn, pos and offsets only have 1 dimension
    time_id = netcdf.defVar(grid_id,'time','NC_DOUBLE',time_dim_id);
    dn_id = netcdf.defVar(grid_id,'dn','NC_DOUBLE',time_dim_id);
    pos_id = netcdf.defVar(grid_id,'pos','NC_DOUBLE',sensor_dim_id);
    offsets_id = netcdf.defVar(grid_id,'offsets','NC_DOUBLE',sensor_dim_id);
    sensor_sn_id = netcdf.defVar(grid_id,'sensor_sn','NC_STRING',sensor_dim_id);
    sensor_type_id = netcdf.defVar(grid_id,'sensor_type','NC_STRING',sensor_dim_id);
    
    % get cell array of variable names
    fields = fieldnames(gridded);
    vars = intersect(possible_vars,fields);

    % create a nc_variable for each returning a cell array of ids 
    var_ids = cellfun(@(name) netcdf.defVar(grid_id,name,'NC_DOUBLE',[sensor_dim_id, time_dim_id]),vars,'UniformOutput',false);

    % set fill values, chunking and compression on all variables
    chunksize = [length(gridded.pos) 7200]; % all sensors and 1hr of data at 2Hz
    compression_level = 9; % 1 is least, 9 is most
    cellfun(@(varid) netcdf.defVarFill(grid_id,varid,false,1e35),var_ids);
    cellfun(@(varid) netcdf.defVarChunking(grid_id,varid,'CHUNKED',chunksize),var_ids);
    cellfun(@(varid) netcdf.defVarDeflate(grid_id,varid,true,true,compression_level),var_ids);

    % set long_name and units attributes
    netcdf.putAtt(grid_id,time_id,'long_name',long_names.time,'NC_STRING');
    netcdf.putAtt(grid_id,dn_id,'long_name',long_names.dn,'NC_STRING');
    netcdf.putAtt(grid_id,pos_id,'long_name',long_names.pos,'NC_STRING');
    netcdf.putAtt(grid_id,offsets_id,'long_name',long_names.offsets,'NC_STRING');
    cellfun(@(varid,name) netcdf.putAtt(grid_id,varid,'long_name',long_names.(name),'NC_STRING'),var_ids,vars);
    % units
    netcdf.putAtt(grid_id,time_id,'units',units.time,'NC_STRING');
    netcdf.putAtt(grid_id,dn_id,'units',units.dn,'NC_STRING');
    netcdf.putAtt(grid_id,pos_id,'units',units.pos,'NC_STRING');
    netcdf.putAtt(grid_id,offsets_id,'units',units.offsets,'NC_STRING');
    cellfun(@(varid,name) netcdf.putAtt(grid_id,varid,'units',units.(name),'NC_STRING'),var_ids,vars);

    % optional variables
    if isfield(gridded.info,'catenary_a')
        catenary_a_id = netcdf.defVar(grid_id,'catenary_a','NC_DOUBLE',time_dim_id);
        netcdf.putAtt(grid_id,catenary_a_id,'long_name',long_names.catenary_a,'NC_STRING');
        netcdf.putAtt(grid_id,catenary_a_id,'units',units.catenary_a,'NC_STRING');
    end

    % create global attributes with configuration data for both gridded and
    % ungridded groups
    global_id = netcdf.getConstant('GLOBAL');
    function putAtt(name,dtype)
        if isfield(cfg,name) && ~isempty(cfg.(name))
            netcdf.putAtt(grid_id,global_id,name,cfg.(name),dtype); 
            netcdf.putAtt(ungd_id,global_id,name,cfg.(name),dtype); 
        end
    end
    function putAttDatetime(name)
        if isfield(cfg,name) && ~isempty(cfg.(name))
            netcdf.putAtt(grid_id,global_id,name,string(cfg.(name)),'NC_STRING');
            netcdf.putAtt(ungd_id,global_id,name,string(cfg.(name)),'NC_STRING');
        end
    end
    putAtt('name','NC_STRING');
    putAtt('cruise','NC_STRING');
    putAtt('vessel','NC_STRING');
    putAtt('dn_range','NC_DOUBLE');
    putAttDatetime('zero_pressure_interval');
    putAtt('dir_raw','NC_STRING');
    putAtt('dir_proc','NC_STRING');
    putAtt('nc_file','NC_STRING');
    putAtt('file_gps','NC_STRING');
    putAtt('time_offset_method','NC_STRING');
    putAttDatetime('dunk_interval');
    putAtt('time_base_sensor_sn','NC_STRING');
    putAtt('freq_base','NC_DOUBLE');
    putAtt('chain_model','NC_STRING');
    
    
    % convert raw2mat to integer
    if isfield(cfg,'raw2mat') && ~isempty(cfg.raw2mat)
        netcdf.putAtt(grid_id,global_id,'raw2mat',uint8(cfg.raw2mat),'NC_UBYTE');
        netcdf.putAtt(ungd_id,global_id,'raw2mat',uint8(cfg.raw2mat),'NC_UBYTE');
    end

    % optional attributes
    function putAttInfo(name,dtype)
        if isfield(gridded.info,name) && ~isempty(gridded.info.(name))
            netcdf.putAtt(grid_id,global_id,name,gridded.info.(name),dtype);
            netcdf.putAtt(ungd_id,global_id,name,gridded.info.(name),dtype);
        end
    end
    putAttInfo('catenary_pos_to_x','NC_STRING');
    putAttInfo('catenary_pos_to_z','NC_STRING');

    % end define mode
    netcdf.endDef(ncid);

    % now we can write the gridded data to the variables
    netcdf.putVar(grid_id,time_id,posixtime(datetime(gridded.dn,'ConvertFrom','datenum')));
    netcdf.putVar(grid_id,dn_id,gridded.dn);
    netcdf.putVar(grid_id,pos_id,gridded.pos);
    netcdf.putVar(grid_id,offsets_id,gridded.info.offsets);
    netcdf.putVar(grid_id,sensor_sn_id,string({cfg.sensors(:).sn}));
    netcdf.putVar(grid_id,sensor_type_id,string({cfg.sensors(:).sensor_type}));
    cellfun(@(varid,name) netcdf.putVar(grid_id,varid,gridded.(name)),var_ids,vars);

    % optional variables
    if isfield(gridded.info,'catenary_a') && ~isempty(gridded.info.catenary_a)
        netcdf.putVar(grid_id,catenary_a_id,gridded.info.catenary_a);
    end
    
    % now the ungridded data
    % loop through data
    chunksize = 14400; % 2 hrs of data at 2Hz
    compression_level = 9;
    for ii = 1:length(data)
        % put file back into definition mode
        netcdf.reDef(ncid);
        
        % make a group for the sensor
        grp_id = netcdf.defGrp(ungd_id,sprintf('sensor_%02d',ii));

        % define the time dimension
        time_dim_id = netcdf.defDim(grp_id,'time',length(data{ii}.dn));

        % get the variable names
        fields = fieldnames(data{ii});
        ndata = length(data{ii}.dn); % number of datapoints
        idx = cellfun(@(fieldname) length(data{ii}.(fieldname))==ndata,fields);
        vars = fields(idx);

        % define the variables
        time_id = netcdf.defVar(grp_id,'time','NC_DOUBLE',time_dim_id);
        var_ids = cellfun(@(name) netcdf.defVar(grp_id,name,'NC_DOUBLE',time_dim_id),vars,'UniformOutput',false);

        % set the fill value, chunking and compression 
        cellfun(@(varid) netcdf.defVarFill(grp_id,varid,false,1e35),var_ids);
        cellfun(@(varid) netcdf.defVarChunking(grp_id,varid,'CHUNKED',chunksize),var_ids);
        cellfun(@(varid) netcdf.defVarDeflate(grp_id,varid,true,true,compression_level),var_ids);

        % set variable attributes
        netcdf.putAtt(grp_id,time_id,'long_name',long_names.time,'NC_STRING');
        netcdf.putAtt(grp_id,time_id,'units',units.time,'NC_STRING');
        cellfun(@(varid,name) netcdf.putAtt(grp_id,varid,'long_name',long_names.(name),'NC_STRING'),var_ids,vars);
        cellfun(@(varid,name) netcdf.putAtt(grp_id,varid,'units',units.(name),'NC_STRING'),var_ids,vars);

        % set global attributes on the group
        netcdf.putAtt(grp_id,global_id,'sensor_sn',cfg.sensors(ii).sn,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'sensor_type',cfg.sensors(ii).sensor_type,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'position_on_chain',cfg.sensors(ii).pos,'NC_DOUBLE');
        netcdf.putAtt(grp_id,global_id,'position_units',units.pos,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'time_offset_applied',gridded.info.offsets(ii),'NC_DOUBLE');
        netcdf.putAtt(grp_id,global_id,'time_offset_units',units.offsets,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'raw_rsk_file',cfg.sensors(ii).file_raw,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'raw_mat_file',cfg.sensors(ii).file_mat,'NC_STRING');

        % end define mode
        netcdf.endDef(ncid);

        % write data into variables
        netcdf.putVar(grp_id,time_id,posixtime(datetime(data{ii}.dn,'ConvertFrom','datenum')));
        cellfun(@(varid,name) netcdf.putVar(grp_id,varid,data{ii}.(name)),var_ids,vars);

    end
   
    % close file
    netcdf.close(ncid);

end