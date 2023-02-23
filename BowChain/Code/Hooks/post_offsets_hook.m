function [data, time_offsets, pressure_offsets, sensors] = post_offsets_hook(data, time_offsets, pressure_offsets, cfg, sensors)

func = [cfg.cruise '_post_offsets_hook'];
if exist(func,'file')
    [data, time_offsets, pressure_offsets, sensors] = feval(func,data, time_offsets, pressure_offsets, cfg, sensors);
end
