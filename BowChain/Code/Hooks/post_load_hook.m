function [data, sensors] = post_load_hook(data, cfg, sensors)

func = [cfg.cruise '_post_load_hook'];
if exist(func,'file')
    [data, sensors] = feval(func,data,cfg,sensors);
end
