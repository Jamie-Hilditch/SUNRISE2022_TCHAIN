function [data, offsets] = proc_time_offsets(data,cfg)

% Compute offsets
apply_offsets = true;
switch cfg.time_offset_method
  case 'known_drift'
    % Correct for a measured clock drift
    offsets = time_offsets_known_drift(data,cfg);
  case 'cohere'
    fprintf('Calibrating clocks over interval: %s,%s\n',...
                 datestr(cfg.cohere_interval(1)),...
                 datestr(cfg.cohere_interval(2)));
    % Sample data over cohere interval
    tcalgrid = proc_grid_init(data,cfg,cfg.cohere_interval);
    % compute and apply offsets to raw data
    offsets = time_offsets_cohere(tcalgrid,data,cfg);
    close all
  case 'dunk_correlation'
    fprintf('Calibrating clocks using dunk interval: %s,%s\n',...
                 cfg.dunk_interval(1),...
                 cfg.dunk_interval(2));
    offsets = time_offsets_dunk_correlation(data,cfg);
  otherwise
    fprintf('No time offsets applied\n')
    offsets = zeros(length(data),1);
    apply_offsets = false;
end

% Apply offsets
if apply_offsets
    fprintf('Applying time offsets\n')
    for i = 1:length(data)
        data{i}.dn = data{i}.dn + offsets(i);
        fprintf('\tRemoved %.2fs time offset from %s\n',...
                     offsets(i)*86400,data{i}.sn)
    end
end
