function [ data, p_offsets ] = proc_pressure_cal(data,cfg)

% ********************************************** %
% Why was Dylan gridding the pressure data here? %
% ********************************************** %
grid_pressure = false;

p_offsets = nan(length(data),1);

if ~isfield(cfg,'zero_pressure_interval') || isempty(cfg.zero_pressure_interval)
    return
end

fprintf('Calibrating pressure data over interval: %s,%s\n',...
             cfg.zero_pressure_interval(1),...
             cfg.zero_pressure_interval(2));

if ~grid_pressure
    for i = 1:length(data)
        % skip sensors without pressure
        if ~isfield(data{i},'p'); continue; end
        % get indices of zero pressure interval
        idx = (data{i}.dn >= datenum(cfg.zero_pressure_interval(1))) & ...
            (data{i}.dn <= datenum(cfg.zero_pressure_interval(2)));
        % get mean pressure
        p0 = mean(data{i}.p(idx),'omitnan');
        if ~isnan(p0)
            data{i}.p = data{i}.p - p0;
            data{i}.p_offset = p0;
                fprintf('\tRemoved %.2fdbar pressure offset from %s\n',...
                             p0,data{i}.sn)
        else 
            fprintf('\tNo pressure offset removed from %s\n',data{i}.sn)
            p0 = 0;
        end
        p_offsets(i) = p0;
    end
else
    % Dylan's code 

    % Sample onto pressure calibration interval
    pcalgrid = proc_grid_init(data,cfg,datenum(cfg.zero_pressure_interval));
    % Compute pressure offsets
    for i = 1:length(pcalgrid.pos)
        if isfield(data{i},'p') && ~all(isnan(pcalgrid.p(i,:)))
            p0 = mean(pcalgrid.p(i,:),'omitnan');
            if ~isnan(p0)
                data{i}.p = data{i}.p - p0;
                data{i}.p_offset = p0;
                fprintf('\tRemoved %.2fdbar pressure offset from %s\n',...
                             p0,data{i}.sn)
            else 
                fprintf('\tNo pressure offset removed from %s\n',data{i}.sn)
                p0 = 0; 
            end
            p_offsets(i) = p0;
        end
    end
end

