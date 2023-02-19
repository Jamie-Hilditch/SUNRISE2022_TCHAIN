function gridded = proc_chain_model(gridded,cfg)
gridded = feval(cfg.chain_model,gridded,cfg);

% make a plot of the depths
fig = figure(visible='off',Units='Normalized',OuterPosition=[0,0,1,1]);
has_p = any(~isnan(gridded.p),2);
pz = plot(gridded.dt,gridded.z(~has_p,:),'k-',linewidth=0.5,DisplayName='z from chain model (no pressure)');
hold on
ppz = plot(gridded.dt,gridded.z(has_p,:),'b-',linewidth=0.5,DisplayName='z from chain model (has pressure)');
pp = plot(gridded.dt,-gridded.p,'r-',linewidth=0.5,Displayname='Exact from pressure');
legend([pz(1) ppz(1) pp(1)])
xlabel('Time')
ylabel('z [ m ]')
title(sprintf('Chain model: %s',cfg.chain_model),interpreter='None')
% save figure
if ~isempty(cfg.dir_fig)
    print(fig,fullfile(cfg.dir_fig,'z_chain_model.png'),'-dpng','-r600')
end
% display figure until closed
if cfg.display_figures
    uiwait(fig)
end