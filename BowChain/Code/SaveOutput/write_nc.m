function write_nc(data,gridded,cfg,sensors,filename,time_range)
    % write gridded and ungridded data in a timerange to netcdf

    % possible variables with sensor and time dimensions
    possible_vars = {'t';'p';'s';'x';'z';'lat';'lon'};
    
    % map variable names to units and long_names
    long_names.time = "Time";
    long_names.dn = "datenum";
    long_names.pos = "Position on chain";
    long_names.time_offsets = "Time offsets added";
    long_names.pressure_offsets = "Pressure offsets subtracted";
    long_names.t = "Temperature";
    long_names.p = "Pressure";
    long_names.c = "Conductivity";
    long_names.s = "Salinity";
    long_names.x = "Horizontal displacement, positive in direction of ship heading";
    long_names.z = "Vertical displacement";
    long_names.lat = "Latitude";
    long_names.lon = "Longitude";
    long_names.catenary_k = "Catenary inverse length scale k";
    long_names.catenary_th = "Catenary theta, angle down from horizontal at first pressure sensor";
    long_names.catenary_rms_error = "RMS error in z from catenary fit";
    long_names.catenary_z0 = "z coordinate of first pressure sensor";
    long_names.catenary_s0 = "Catenary arclength from the top of the chain to the first pressure sensor";
    % units
    units.time = "seconds since 1970-01-01 0:0:0";
    units.dn = "MATLAB datenum";
    units.pos = "m";
    units.time_offsets = "s";
    units.pressure_offsets = "dbar";
    units.t = "degC";
    units.p = "dbar";
    units.c = "mS/cm";
    units.s = "PSU";
    units.x = "m";
    units.z = "m";
    units.lat = "degrees_north";
    units.lon = "degrees_east";
    units.catenary_k = "m^-1";
    units.catenary_th = "rad";
    units.catenary_rms_error = "m";
    units.catenary_z0 = "m";
    units.catenary_s0 = "m";
    
    % create a netcdf4 file overwriting (CLOBBER) an existing file
    cmode = bitor(netcdf.getConstant('NETCDF4'),netcdf.getConstant('CLOBBER'));
    ncid = netcdf.create(filename,cmode);

    % close the file when we exit even if due to an error
    cleanup_obj = onCleanup(@() netcdf.close(ncid));

    % create a group for gridded and ungridded data
    grid_id = netcdf.defGrp(ncid,'gridded');
    ungd_id = netcdf.defGrp(ncid,'ungridded');
    
    % get time index 
    time_idx = (gridded.dt >= time_range(1)) & (gridded.dt <= time_range(2));

    % define dimensions in the gridded group
    time_dim_id = netcdf.defDim(grid_id,'time',nnz(time_idx));
    sensor_dim_id = netcdf.defDim(grid_id,'sensor_number',length(gridded.pos));

    % define variables in the gridded group
    % time, dn, pos and offsets only have 1 dimension
    time_id = netcdf.defVar(grid_id,'time','NC_DOUBLE',time_dim_id);
    pos_id = netcdf.defVar(grid_id,'pos','NC_DOUBLE',sensor_dim_id);
    if size(gridded.info.time_offsets(1,:)) == 1
        time_offsets_id = netcdf.defVar(grid_id,'time_offsets','NC_DOUBLE',sensor_dim_id);
    else
        time_offsets_id = netcdf.defVar(grid_id,'time_offsets','NC_DOUBLE',[sensor_dim_id, time_dim_id]);
    end
    pressure_offsets_id = netcdf.defVar(grid_id,'pressure_offsets','NC_DOUBLE',sensor_dim_id);
    sensor_sn_id = netcdf.defVar(grid_id,'sensor_sn','NC_STRING',sensor_dim_id);
    sensor_type_id = netcdf.defVar(grid_id,'sensor_type','NC_STRING',sensor_dim_id);
    sensor_interp_id = netcdf.defVar(grid_id,'sensor_interp_method','NC_STRING',sensor_dim_id);
    
    % get cell array of variable names
    fields = fieldnames(gridded);
    vars = intersect(possible_vars,fields);

    % create a nc_variable for each returning a cell array of ids 
    var_ids = cellfun(@(name) netcdf.defVar(grid_id,name,'NC_DOUBLE',[sensor_dim_id, time_dim_id]),vars,'UniformOutput',false);

    % set fill values, chunking and compression on all variables
    chunksize = [length(gridded.pos) min(7200,nnz(time_idx))]; % all sensors and 1hr of data at 2Hz
    compression_level = 9; % 1 is least, 9 is most
    cellfun(@(varid) netcdf.defVarFill(grid_id,varid,false,1e35),var_ids);
    cellfun(@(varid) netcdf.defVarChunking(grid_id,varid,'CHUNKED',chunksize),var_ids);
    cellfun(@(varid) netcdf.defVarDeflate(grid_id,varid,true,true,compression_level),var_ids);

    % set long_name and units attributes
    netcdf.putAtt(grid_id,time_id,'long_name',long_names.time,'NC_STRING');
    netcdf.putAtt(grid_id,pos_id,'long_name',long_names.pos,'NC_STRING');
    netcdf.putAtt(grid_id,time_offsets_id,'long_name',long_names.time_offsets,'NC_STRING');
    netcdf.putAtt(grid_id,pressure_offsets_id,'long_name',long_names.pressure_offsets,'NC_STRING');
    cellfun(@(varid,name) netcdf.putAtt(grid_id,varid,'long_name',long_names.(name),'NC_STRING'),var_ids,vars);
    % units
    netcdf.putAtt(grid_id,time_id,'units',units.time,'NC_STRING');
    netcdf.putAtt(grid_id,pos_id,'units',units.pos,'NC_STRING');
    netcdf.putAtt(grid_id,time_offsets_id,'units',units.time_offsets,'NC_STRING');
    netcdf.putAtt(grid_id,pressure_offsets_id,'units',units.pressure_offsets,'NC_STRING');
    cellfun(@(varid,name) netcdf.putAtt(grid_id,varid,'units',units.(name),'NC_STRING'),var_ids,vars);

    % optional variables
    function var_id = def_info_time_variable(varname)
        var_id = [];
        if isfield(gridded.info,varname) && ~isempty(gridded.info.(varname))
            var_id = netcdf.defVar(grid_id,varname,'NC_DOUBLE',time_dim_id);
            netcdf.putAtt(grid_id,var_id,'long_name',long_names.(varname),'NC_STRING');
            netcdf.putAtt(grid_id,var_id,'units',units.(varname),'NC_STRING');
        end
    end
    catenary_k_id = def_info_time_variable('catenary_k');
    catenary_th_id = def_info_time_variable('catenary_th');
    catenary_rms_error_id = def_info_time_variable('catenary_rms_error');
    catenary_z0_id = def_info_time_variable('catenary_z0');
    catenary_s0_id = def_info_time_variable('catenary_s0');

    % create global attributes with configuration data for both gridded and
    % ungridded groups
    global_id = netcdf.getConstant('GLOBAL');
    function putAtt(name,dtype)
        if ~isempty(cfg.(name))
            netcdf.putAtt(grid_id,global_id,name,cfg.(name),dtype); 
            netcdf.putAtt(ungd_id,global_id,name,cfg.(name),dtype); 
        end
    end
    function putAttDatetime(name)
        if ~any(isnat(cfg.(name)))
            netcdf.putAtt(grid_id,global_id,name,string(cfg.(name)),'NC_STRING');
            netcdf.putAtt(ungd_id,global_id,name,string(cfg.(name)),'NC_STRING');
        end
    end
    function putAttDuration(name)
        if ~any(isnan(cfg.(name)))
            netcdf.putAtt(grid_id,global_id,name,cfg.(name)/seconds(1),'NC_DOUBLE');
            netcdf.putAtt(ungd_id,global_id,name,cfg.(name)/seconds(1),'NC_DOUBLE');
        end
    end
    putAttDatetime('processing_date')
    putAtt('name','NC_STRING');
    putAtt('cruise','NC_STRING');
    putAtt('vessel','NC_STRING');
    putAttDatetime('deployment_duration');
    putAttDatetime('zero_pressure_interval');
    putAtt('dir_raw','NC_STRING');
    putAtt('dir_proc','NC_STRING');
    putAtt('nc_file','NC_STRING');
    putAtt('dir_fig','NC_STRING');
    putAtt('file_gps','NC_STRING');
    putAtt('time_offset_method','NC_STRING');
    putAttDatetime('dunk_interval');
    putAtt('time_base_sensor_sn','NC_STRING');
    putAttDatetime('cohere_interval');
    putAttDatetime('time_synched');
    putAttDatetime('time_drift_measured');
    putAttDuration('drift');
    putAtt('freq_base','NC_DOUBLE');
    putAtt('chain_model','NC_STRING');   
    
    % convert raw2mat to integer
    if ~isempty(cfg.raw2mat)
        netcdf.putAtt(grid_id,global_id,'raw2mat',uint8(cfg.raw2mat),'NC_UBYTE');
        netcdf.putAtt(ungd_id,global_id,'raw2mat',uint8(cfg.raw2mat),'NC_UBYTE');
    end

    % optional attributes
    function putAttInfo(name,dtype)
        if isfield(gridded.info, name) && ~isempty(gridded.info.(name))
            netcdf.putAtt(grid_id,global_id,name,gridded.info.(name),dtype);
            netcdf.putAtt(ungd_id,global_id,name,gridded.info.(name),dtype);
        end
    end
    putAttInfo('catenary_pos_to_x','NC_STRING');
    putAttInfo('catenary_pos_to_z','NC_STRING');
    putAttInfo('catenary_s_to_x','NC_STRING');
    putAttInfo('catenary_s_to_z','NC_STRING');

    % end define mode
    netcdf.endDef(ncid);

    % now we can write the gridded data to the variables
    netcdf.putVar(grid_id,time_id,posixtime(gridded.dt(time_idx)));
    netcdf.putVar(grid_id,pos_id,gridded.pos);
    if size(gridded.info.time_offsets(1,:)) == 1
        netcdf.putVar(grid_id,time_offsets_id,gridded.info.time_offsets/seconds(1));
    else
        netcdf.putVar(grid_id,time_offsets_id,gridded.info.time_offsets(:,time_idx)/seconds(1));
    end
    netcdf.putVar(grid_id,pressure_offsets_id,gridded.info.pressure_offsets);
    netcdf.putVar(grid_id,sensor_sn_id,string({sensors(:).sn}));
    netcdf.putVar(grid_id,sensor_type_id,string({sensors(:).sensor_type}));
    netcdf.putVar(grid_id,sensor_interp_id,string({sensors(:).interp_method}));
    cellfun(@(varid,name) netcdf.putVar(grid_id,varid,gridded.(name)(:,time_idx)),var_ids,vars);

    % optional variables
    function put_info_time_var(varname,var_id)
        if isfield(gridded.info,varname) && ~isempty(gridded.info.(varname))
            netcdf.putVar(grid_id,var_id,gridded.info.(varname)(time_idx));
        end
    end
    put_info_time_var('catenary_k',catenary_k_id);
    put_info_time_var('catenary_th',catenary_th_id);
    put_info_time_var('catenary_rms_error',catenary_rms_error_id);
    put_info_time_var('catenary_z0',catenary_z0_id);
    put_info_time_var('catenary_s0',catenary_s0_id);
    
    % now the ungridded data
    % loop through data
    chunksize = 14400; % 2 hrs of data at 2Hz
    compression_level = 9;
    for ii = 1:length(data)
        % put file back into definition mode
        netcdf.reDef(ncid);
        
        % make a group for the sensor
        grp_id = netcdf.defGrp(ungd_id,sprintf('sensor_%02d',ii));

        % get time index
        time_idx = (data{ii}.dt >= time_range(1)) & (data{ii}.dt <= time_range(2));
        
        % total number of datapoints
        ndata = length(data{ii}.dt);
        nidx = nnz(time_idx);

        % define the time dimension
        time_dim_id = netcdf.defDim(grp_id,'time',nidx);

        % if no data continue
        if nidx == 0; continue; end

        % get the variable names
        fields = fieldnames(data{ii});
        
        idx = cellfun(@(fieldname) length(data{ii}.(fieldname))==ndata && ~strcmp(fieldname,'dt'),fields);
        vars = fields(idx);

        % define the variables
        time_id = netcdf.defVar(grp_id,'time','NC_DOUBLE',time_dim_id);
        var_ids = cellfun(@(name) netcdf.defVar(grp_id,name,'NC_DOUBLE',time_dim_id),vars,'UniformOutput',false);

        % set the fill value, chunking and compression 
        cellfun(@(varid) netcdf.defVarFill(grp_id,varid,false,1e35),var_ids);
        cellfun(@(varid) netcdf.defVarChunking(grp_id,varid,'CHUNKED',min(chunksize,nidx)),var_ids);
        cellfun(@(varid) netcdf.defVarDeflate(grp_id,varid,true,true,compression_level),var_ids);

        % set variable attributes
        netcdf.putAtt(grp_id,time_id,'long_name',long_names.time,'NC_STRING');
        netcdf.putAtt(grp_id,time_id,'units',units.time,'NC_STRING');
        cellfun(@(varid,name) netcdf.putAtt(grp_id,varid,'long_name',long_names.(name),'NC_STRING'),var_ids,vars);
        cellfun(@(varid,name) netcdf.putAtt(grp_id,varid,'units',units.(name),'NC_STRING'),var_ids,vars);

        % set global attributes on the group
        netcdf.putAtt(grp_id,global_id,'sensor_sn',sensors(ii).sn,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'sensor_type',sensors(ii).sensor_type,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'position_on_chain',sensors(ii).pos,'NC_DOUBLE');
        netcdf.putAtt(grp_id,global_id,'position_units',units.pos,'NC_STRING');
        if size(gridded.info.time_offsets(ii,:)) == 1
            netcdf.putAtt(grp_id,global_id,'time_offset_added',gridded.info.time_offsets(ii)/seconds(1),'NC_DOUBLE');
        end
        netcdf.putAtt(grp_id,global_id,'time_offset_units',units.time_offsets,'NC_STRING');
        if isfield(data{ii},'p')
            netcdf.putAtt(grp_id,global_id,'pressure_offset_subtracted',gridded.info.pressure_offsets(ii),'NC_DOUBLE');
            netcdf.putAtt(grp_id,global_id,'pressure_offset_units',units.pressure_offsets,'NC_STRING');
        end
        netcdf.putAtt(grp_id,global_id,'raw_rsk_file',sensors(ii).file_raw,'NC_STRING');
        netcdf.putAtt(grp_id,global_id,'raw_mat_file',sensors(ii).file_mat,'NC_STRING');

        % end define mode
        netcdf.endDef(ncid);
        

        % write data into variables
        netcdf.putVar(grp_id,time_id,posixtime(data{ii}.dt(time_idx)));
        cellfun(@(varid,name) netcdf.putVar(grp_id,varid,data{ii}.(name)(time_idx)),var_ids,vars);
    
    end
   
    % close file
    clear cleanup_obj
end