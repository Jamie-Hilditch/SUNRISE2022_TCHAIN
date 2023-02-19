function [gridded, sensors] = post_grid_hook(gridded,cfg,sensors)

func = [cfg.cruise '_post_grid_hook'];
if exist(func,'file')
    [gridded, sensors] = feval(func,gridded,cfg,sensors);
end
