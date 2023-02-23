function [gridded ,sensors] = proc_grid_init(data,config,sensors,varargin)

N = length(sensors);
perd_base = seconds(1/config.freq_base);
% Use a custom datenum range if specified
if nargin > 3
    interval = varargin{1};
else
    interval = config.deployment_duration;
end

% get start and end times
start_dt = compute_best_start_time(interval(1),perd_base,data);
if isnat(interval(2))
    data_end_times = cellfun(@(S) S.dt(1),data);
    end_dt = min(data_end_times);
else
    end_dt = interval(2);
end

%% Initialize gridded variables
gridded = struct();
gridded.dt = start_dt:perd_base:end_dt;

flds = {'t','p','s','x','z'};
for f = 1:length(flds)
    gridded.(flds{f}) = nan(N,length(gridded.dt));
end

% Subsample/interpolate all data onto intermediate time base
for i = 1:length(data)
    % set method of interpolation   
    if config.force_linear
        interp_method = 'linear';
    else
        % Determine interpolation method based on sampling period
        perd_sens = mean(diff(data{i}.dt),'omitnan');
        if perd_sens <= perd_base
            interp_method = 'nearest';
        else
            interp_method = 'linear';
        end
    end
    
    % add the interpolation method to config
    sensors(i).interp_method = interp_method;

    % Interpolate data onto base_time
    [~,idx] = unique(data{i}.dt);
    t_idx = false(N,1);
    t_idx(idx) = true;
    for f = 1:length(flds)
        if isfield(data{i},flds{f})
            d_idx = isfinite(data{i}.(flds{f}));
            idx = (t_idx & d_idx);
            if ~any(idx)
                warning('No finite data for field %s from sensor %s',flds{f},sensors(i).sn)
                continue
            end
            gridded.(flds{f})(i,:) = ...
                interp1(data{i}.dt(idx),data{i}.(flds{f})(idx),gridded.dt,...
                        interp_method);
        end
    end
    gridded.pos(i,:) = sensors(i).pos;
end

% % Add lat and lon fields if GPS file is specifeid
% if ~isempty(config.file_gps)
%     gridded.lat = [];
%     gridded.lon = [];
% end

gridded.info = struct();

