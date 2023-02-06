function [gridded ,config] = proc_grid_init(data,config,varargin)

N = length(config.sensors);
perd_base =1/(config.freq_base*86400);
% Use a custom datenum range if specified
if nargin > 2
    dn_range = varargin{1};
else
    dn_range = config.dn_range;
end

%% Initialize gridded variables
gridded = struct();
start_dn = compute_best_start_time(dn_range(1),perd_base,data);
gridded.dn = start_dn:perd_base:(dn_range(2));
flds = {'t','p','s','x','z'};
for f = 1:length(flds)
    gridded.(flds{f}) = nan(N,length(gridded.dn));
end

% Subsample/interpolate all data onto intermediate time base
for i = 1:length(data)
    % set method of interpolation   
    if isfield(config,'force_linear') && config.force_linear
        interp_method = 'linear';
    else
        % Determine interpolation method based on sampling period
        perd_sens = mean(diff(data{i}.dn),'omitnan');
        if perd_sens <= perd_base
            interp_method = 'nearest';
        else
            interp_method = 'linear';
        end
    end
    
    % add the interpolation method to config
    config.sensors(i).interp_method = interp_method;

    % Interpolate data onto base_time
    [~,idx] = unique(data{i}.dn);
    t_idx = false(N,1);
    t_idx(idx) = true;
    for f = 1:length(flds)
        if isfield(data{i},flds{f})
            d_idx = isfinite(data{i}.(flds{f}));
            idx = (t_idx & d_idx);
            gridded.(flds{f})(i,:) = ...
                interp1(data{i}.dn(idx),data{i}.(flds{f})(idx),gridded.dn,...
                        interp_method);
        end
    end
    gridded.pos(i,:) = config.sensors(i).pos;
end

% Add lat and lon fields if GPS file is specifeid
if isfield(config,'file_gps')
    gridded.lat = [];
    gridded.lon = [];
end

gridded.info = struct();

