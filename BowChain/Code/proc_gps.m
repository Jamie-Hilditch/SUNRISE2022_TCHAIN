%% proc_gps(gridded,cfg)
% Compute locations of samples by applying positional offsets to GPS data.
% cfg.file_gps must point to a .mat file containing the following variables:
%  - dn/time: datenum vector
%  - lat: latitude vector (deg E)
%  - lon: longitude vector (deg N)
% and preferably also
%  - heading: heading vector (deg T)

function gridded = proc_gps(gridded,cfg)

if isfield(cfg,'file_gps')
    % Load gps data
    gps = load(cfg.file_gps);

    % extract gps from gps
    if isfield(gps,'gps')
        gps = gps.gps;
    end
    
    % rename fields
    if isfield(gps,'time')
        gps = renameStructField(gps,'time','dn');
    end

    [~,iu] = unique(gps.dn);

    % Interpolate GPS data to sensor time
    lat = interp1(gps.dn(iu),gps.lat(iu),gridded.dn);
    lon = interp1(gps.dn(iu),gps.lon(iu),gridded.dn);

    if isfield(gps,'heading')
        hi = cosd(gps.heading) + 1i*sind(gps.heading);
        h = mod(180/pi*angle(interp1(gps.dn(iu),hi(iu),gridded.dn)),360);
    else
        % compute velocity to get heading
        wgs84 = referenceEllipsoid('wgs84','m');
        lt0 = nanmean(lat);
        ln0 = nanmean(lon);
        lt2y = distance('rh',lt0-0.5,ln0,lt0+0.5,ln0,wgs84); % meters N/S per deg N
        ln2x = distance('rh',lt0,ln0-0.5,lt0,ln0+0.5,wgs84); % meters E/W per deg W at lat lt0
        y  =  lt2y * (lat-lt0) ; % meters N/S
        x  =  ln2x * (lon-ln0) ; % meters E/W
        vx = gradient(x,gridded.dn);
        vy = gradient(y,gridded.dn);
        h = mod(90 - 180/pi*atan2(vy,vx),360);
    end


    % Make lat/lon/heading the same size as gridded data
    nsens = length(gridded.pos);
    h = repmat(h,nsens,1);
    lat = repmat(lat,nsens,1);
    lon = repmat(lon,nsens,1);

    % Apply positional offsets in the direction of ship motion
    arc = distdim(gridded.x,'meters','degrees','earth'); % convert m to arclength
    [gridded.lat, gridded.lon] = reckon(lat,lon,gridded.x,h); % apply arclength offset
end
