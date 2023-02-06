function [data, config] = proc_load_mat(config)
data = cell(length(config.sensors),1);

% create a figure
fig = figure(visible='off',Units='Normalized',OuterPosition=[0,0,1,1]);
hold on

% load data
fprintf('Loading raw data from .mat files ...\n')
for i = 1:length(config.sensors)
    data{i} = load(config.sensors(i).file_mat);
    if ~any(isfinite(data{i}.dn))
        warning('No data found for %s [%s]',config.sensors(i).sensor_type,config.sensors(i).sn)
    else
        msg = '\tLoaded data from %s [%s]\n';
        fprintf(msg,config.sensors(i).sensor_type,config.sensors(i).sn)
    end

    % add line to figure
    dn = data{i}.dn;
    dt = datetime(dn,'ConvertFrom','datenum');
    pp(i) = plot(dt, ...
        config.sensors(i).pos*ones(size(dn)), ...
        '.', ...
        MarkerSize=4, ...
        DisplayName=config.sensors(i).sn ...
    );
    text(dt(end),config.sensors(i).pos, sprintf('  %s',config.sensors(i).sn),FontSize=8)
end

% Set time limits to the min & max of sensor values if they're inf
if isinf(config.dn_range(1))
    config.dn_range(1) = min(cellfun(@(c) c.dn(1), data));
end

if isinf(config.dn_range(end))
    config.dn_range(end) = max(cellfun(@(c) c.dn(end), data));
end

% indicate important intervals on figure
xline(datetime(config.dn_range,'ConvertFrom','datenum'),'r','dn_range', ...
    Interpreter='none',LabelHorizontalAlignment='center',LabelVerticalAlignment = 'bottom');
if isfield(config,'zero_pressure_interval') && ~isempty(config.zero_pressure_interval)
    line = xline(config.zero_pressure_interval,'b','zero_pressure_interval', ...
        Interpreter='none',LabelVerticalAlignment = 'bottom');
    line(1).LabelHorizontalAlignment = 'left'; line(2).LabelHorizontalAlignment = 'right';
end
if isfield(config,'dunk_interval') && ~isempty(config.dunk_interval)
    line = xline(config.dunk_interval,'g','dunk_interval', ...
        Interpreter='none',LabelVerticalAlignment = 'bottom');
    line(1).LabelHorizontalAlignment = 'left'; line(2).LabelHorizontalAlignment = 'right';
end

% set labels and legend
set ( gca, 'ydir', 'reverse' )
xlabel('Time')
ylabel('Pos [ m ]')
title('Raw datapoints')
% ldg = legend(pp);
% ldg.Location = 'bestoutside';
% ldg.NumColumns = 2;

% save figure
if isfield(config,'dir_fig') && ~isempty(config.dir_fig)
    print(fig,fullfile(config.dir_fig,'raw_datapoints.png'),'-dpng','-r600')
end
% display figure until closed
if isfield(config,'display_figures') && config.display_figures
    uiwait(fig)
end
