function [ data, p_offsets ] = proc_pressure_cal(data,cfg)

p_offsets = nan(length(data),1);

if any(isnat(cfg.zero_pressure_interval)); return; end

fprintf('Calibrating pressure data over interval: %s,%s\n',...
             cfg.zero_pressure_interval(1),...
             cfg.zero_pressure_interval(2));

for i = 1:length(data)
    % skip sensors without pressure
    if ~isfield(data{i},'p'); continue; end
    % get indices of zero pressure interval
    idx = (data{i}.dt >= cfg.zero_pressure_interval(1)) & ...
        (data{i}.dt <= cfg.zero_pressure_interval(2));
    % get mean pressure
    p0 = mean(data{i}.p(idx),'omitnan');
    if ~isnan(p0)
        data{i}.p = data{i}.p - p0;
        data{i}.p_offset = p0;
            fprintf('\tRemoved %.2fdbar pressure offset from %s\n',...
                         p0,data{i}.sn)
    else 
        fprintf(2,'\tWARNING: No pressure offset removed from %s\n',data{i}.sn)
        p0 = 0;
    end
    p_offsets(i) = p0;
end


% make a plot of zero pressure interval before and after offsets
fig = figure(visible='off',Units='Normalized',OuterPosition=[0,0,1,1]);
ax1 = subplot(2,1,1);
hold on
ax2 = subplot(2,1,2);
hold on
for ii = 1:length(data)
    if ~isfield(data{ii},'p'); continue; end
    lw = 0.5;
    idx = (data{ii}.dt >= cfg.zero_pressure_interval(1)) & ...
        (data{ii}.dt <= cfg.zero_pressure_interval(2));
    plot(ax1,data{ii}.dt(idx),data{ii}.p(idx) + p_offsets(ii),linewidth=lw,DisplayName=data{ii}.sn);
    plot(ax2,data{ii}.dt(idx),data{ii}.p(idx),linewidth=lw,DisplayName=data{ii}.sn);
end

linkaxes([ax1,ax2],'x')
xlabel('Time')
ylabel(ax1,'p [ dbar ]')
ylabel(ax2,'p [ dbar ]')
title(ax1,'Without pressure offsets')
title(ax2,'With pressure offsets')
legend(ax1)
legend(ax2)
sgtitle('Zero Pressure Interval')
% save figure
if ~isempty(cfg.dir_fig)
    print(fig,fullfile(cfg.dir_fig,'pressure_offsets.png'),'-dpng','-r600')
end
% display figure until closed
if cfg.display_figures
    uiwait(fig)
end

