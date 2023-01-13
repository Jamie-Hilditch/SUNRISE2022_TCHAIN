function data = proc_time_offsets(data,cfg)

% Compute offsets
apply_offsets = true;
switch cfg.time_offset_method
  case 'known_drift'
    % Correct for a measured clock drift
    offsets = time_offsets_known_drift(data,cfg);
  case 'cohere'
    disp(sprintf('Calibrating clocks over interval: %s,%s',...
                 datestr(cfg.cohere_interval(1)),...
                 datestr(cfg.cohere_interval(2))));
    % Sample data over cohere interval
    tcalgrid = proc_grid_init(data,cfg,cfg.cohere_interval);
    % compute and apply offsets to raw data
    offsets = time_offsets_cohere(tcalgrid,data,cfg);
    close all
  case 'dunk_correlation'
    disp(sprintf('Calibrating clocks using dunk interval: %s,%s',...
                 datestr(cfg.dunk_interval(1)),...
                 datestr(cfg.dunk_interval(2))));
    offsets = time_offsets_dunk_correlation(data,cfg);
  otherwise
    disp('No time offsets applied')
    apply_offsets = false;
end

% Apply offsets
if apply_offsets
    for i = 1:length(data)
        data{i}.dn = data{i}.dn + offsets(i);
        disp(sprintf('Removed %.2fs time offset from %s',...
                     offsets(i)*86400,data{i}.sn))
    end
end
