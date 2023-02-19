function [gridded, sensors] = post_chain_hook(gridded,cfg,sensors)

func = [cfg.cruise '_post_chain_hook'];
if exist(func,'file')
    [gridded, sensors] = feval(func,gridded,cfg,sensors);
end
