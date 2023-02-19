function data = proc_load_mat(config,sensors)
data = cell(length(sensors),1);

% create a figure
fig = figure(visible='off',Units='Normalized',OuterPosition=[0,0,1,1]);
hold on

% load data
fprintf('Loading raw data from .mat files ...\n')
for i = 1:length(sensors)
    data{i} = load(sensors(i).file_mat);
    if ~any(isfinite(data{i}.dn))
        warning('No data found for %s [%s]',sensors(i).sensor_type,sensors(i).sn)
    else
        msg = '\tLoaded data from %s [%s]\n';
        fprintf(msg,sensors(i).sensor_type,sensors(i).sn)
    end

    % add line to figure
    dn = data{i}.dn;
    dt = datetime(dn,'ConvertFrom','datenum');
    pp(i) = plot(dt, ...
        sensors(i).pos*ones(size(dn)), ...
        '.', ...
        MarkerSize=4, ...
        DisplayName=sensors(i).sn ...
    );
    text(dt(end),sensors(i).pos, sprintf('  %s',sensors(i).sn),FontSize=8)
end


% indicate important intervals on figure
function draw_interval(interval_name,fmt)
    if ~any(isnat(config.(interval_name)))
        line = xline(config.(interval_name),fmt,interval_name, ...
            Interpreter='none',LabelVerticalAlignment = 'bottom');
        line(1).LabelHorizontalAlignment = 'left'; line(2).LabelHorizontalAlignment = 'right';
    end
end

draw_interval('deployment_duration','r')
draw_interval('zero_pressure_interval','b')
draw_interval('dunk_interval','g')
draw_interval('cohere_interval','g')

% set labels and legend
set ( gca, 'ydir', 'reverse' )
xlabel('Time')
ylabel('Pos [ m ]')
title('Raw datapoints')

% save figure
if ~isempty(config.dir_fig)
    print(fig,fullfile(config.dir_fig,'raw_datapoints.png'),'-dpng','-r600')
end
% display figure until closed
if config.display_figures
    uiwait(fig)
end

end
