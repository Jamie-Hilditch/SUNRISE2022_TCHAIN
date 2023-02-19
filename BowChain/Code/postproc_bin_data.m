function out = postproc_bin_data(gridded,cfg)

out = gridded;

% return if bin method is none
if cfg.bin_method == 'none'; return; end

%% Check for valid GPS data
if ~isempty(cfg.file_gps)
    gps = load(cfg.file_gps);
    % Check for missing fields
    flds = fields(gps);
    req_flds = {'dn','lat','lon'};
    missing_flds = setdiff(req_flds,flds);
    if length(missing_flds) > 1
        warning('GPS file is missing fields: %s. Returning point cloud!',...
                strjoin(missing_flds,', '))
        return
    end
end

%% Define bin edges for time/lateral space dimension
switch cfg.bin_method
  case 'average'
    %% Bin-average with specified dt & dz
    fprintf('Bin-averaging with dt=%.1fs, dz=%.1fm...',cfg.bin_dt/seconds(1),cfg.bin_dz);

    tg = cfg.deployment_duration(1):cfg.bin_dt:cfg.deployment_duration(2); % time grid
    zg = min(cfg.bin_zlim):abs(cfg.bin_dz):max(cfg.bin_zlim); % z grid
    zbn = discretize(gridded.z,zg); % z bin number
    tbn = discretize(gridded.dt,tg).*ones(length(cfg.sensors),1); % time bin number
    kp = ~isnan(zbn.*tbn); % indices to keep (non-nan time and depth bin numbers)

    % Do the bin-averaging
    flds = {'t','p','s','lat','lon'};
    for i = 1:length(flds)
        gridded.(flds{i}) = accumarray([zbn(kp), tbn(kp)], ...      % bin indices
                                       gridded.(flds{i})(kp),...    % values
                                       [length(zg), length(tg)],... % output size
                                       @(x) mean(x,'omitnan'), NaN);              % function to apply & fill value
    end

    % Make lat & lon 1D
    gridded.lat = mean(gridded.lat,1,'omitnan');
    gridded.lon = mean(gridded.lon,1,'omitnan');

    % Remove 'pos' field (no longer makes sense)
    gridded = rmfield(gridded,'pos');

    % Replace time and z fields
    gridded.z = zg(:);
    gridded.dt = tg;
    out = gridded;
    fprintf(' Done!\n')

  case 'time'
    %%% Project sensor measurements onto slice beneath ship and bin in time

    %% Compute ship speed from GPs data
    % remove non-unique timestamps
    [~,idx] = unique(gps.dn);
    dt = datetime(gps.dn(idx),'ConvertFrom','datenum');
    lt = gps.lat(idx);
    ln = gps.lon(idx);
    % remove NaNs
    idx = ~(isnan(lt.*ln) | isnat(dt));
    dt = dt(idx);
    lt = lt(idx);
    ln = ln(idx);
    % compute velocity
    wgs84 = referenceEllipsoid('wgs84','m');
    lt0 = mean(lt,'omitnan');
    ln0 = mean(ln,'omitnan');
    lt2y = distance('rh',lt0-0.5,ln0,lt0+0.5,ln0,wgs84); % meters N/S per deg N
    ln2x = distance('rh',lt0,ln0-0.5,lt0,ln0+0.5,wgs84); % meters E/W per deg W at lat lt0
    y  =  lt2y * (lt-lt0) ; % meters N/S
    x  =  ln2x * (ln-ln0) ; % meters E/W
    delta_t = diff(dt);
    t  = dt(1:end-1) + delta_t/2;
    delta_t = delta_t/seconds(1);
    vx = interp1(t, diff(x)./delta_t, gridded.dt);
    vy = interp1(t, diff(y)./delta_t, gridded.dt);
    spd = sqrt(vx.^2 + vy.^2);

    %% Apply speed-dependent sensor time offsets
    spd2 = ones(length(gridded.pos),1)*spd;
    dt_base = ones(length(gridded.pos),1)*gridded.dt;
    dt_offset = dt_base - seconds(gridded.x ./ spd2);

    %% Bin the data
    % define bin edges and output time vector
    bp = cfg.binned_period; % convert binned period to days (datenum)
    tbin = gridded.dt(1):bp:gridded.dt(end); % bin edges
    out.dt = tbin(1:end-1) + bp/2; % use bin centers for output time vector
    % assign time bin numbers to each measurement
    [~,~,tbin] = histcounts(dt_offset,tbin);
    % we also need depth bin numbers - just use sensor index
    dbin = (1:length(gridded.pos))'*ones(1,length(gridded.dt));
    % use accumarray to average all data within each bin
    flds = {'t','p','s','z'};
    for i = 1:length(flds)
        out.(flds{i}) = accumarray([dbin(:),tbin(:)],gridded.(flds{i})(:),[],@(x) mean(x,'omitnan'));
    end
    
    gps_dt = datetime(gps.dn,'ConvertFrom','datenum');
    out.lat = interp1(gps_dt,gps.lat,out.dt);
    out.lon = interp1(gps_dt,gps.lon,out.dt);


  case 'space'
    % Assign a lat/lon to each measurement and then bin spatially
    warning('''Space'' bin method not yet implemented. Returning point cloud!');
    return
end
