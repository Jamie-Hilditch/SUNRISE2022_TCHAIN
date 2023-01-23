function data = proc_pressure_cal(data,cfg)

if isfield(cfg,'zero_pressure_interval') && ~isempty(cfg.zero_pressure_interval)
    % Sample onto pressure calibration interval
    pcalgrid = proc_grid_init(data,cfg,datenum(cfg.zero_pressure_interval));
    % Compute pressure offsets
    fprintf('Calibrating pressure data over interval: %s,%s\n',...
                 cfg.zero_pressure_interval(1),...
                 cfg.zero_pressure_interval(2));
    for i = 1:length(pcalgrid.pos)
        if isfield(data{i},'p') && ~all(isnan(pcalgrid.p(i,:)))
            p0 = mean(pcalgrid.p(i,:),'omitnan');
            if ~isnan(p0)
                data{i}.p = data{i}.p - p0;
                fprintf('Removed %.2fdbar pressure offset from %s\n',...
                             p0,data{i}.sn)
            end
        end
    end
end

