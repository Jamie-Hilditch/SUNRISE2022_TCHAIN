function offsets = time_offsets_dunk_correlation(data,cfg,sensors)

    % initialise the offsets
    offsets = seconds(zeros(length(data),1));

    % get the serial number of the sensor we're using as our time base
    sensor_sn = cfg.time_base_sensor_sn;

    % get the position of the sensor we're using as our time base
    time_base_index = find(strcmp({sensors.sn},sensor_sn));
    if isempty(time_base_index)
        warning(['Could not find sensor ' cfg.time_base_sensor_sn '. No time offsets calculated.'])
        return 
    end
    time_base_index = time_base_index(1);

    % get the dunk_interval
    dunk_interval = cfg.dunk_interval;
    if any(isnat(dunk_interval))
        warning('dunk_interval contains NaTs. No time offsets calculated.')
        return
    end

    % get the time and temperature for our base 
    base_idx = (data{time_base_index}.dt >= dunk_interval(1)) & ...
            (data{time_base_index}.dt <= dunk_interval(2));
    base_dt = data{time_base_index}.dt(base_idx);
    base_t = data{time_base_index}.t(base_idx);

    % fill in any nans in base_t
    base_t = fillmissing(base_t,'linear');

    % subtract off a mean to make correlation cleaner
    % mean_t = mean(base_t);
    % base_t = base_t - mean_t;

    % use median to find a point in the dunk
    median_t = median(base_t);
    % compute correlation on differences from the dunk value
    base_t = abs(base_t - median_t);
    
    % create a figure for the correlation
    if cfg.display_figures; figure(); end

    for ii = 1:length(offsets)
        % skip base time
        if ii == time_base_index; continue; end
        
        % get sensor temperature difference
        sensor_t = abs(data{ii}.t - median_t);

        fprintf('\tComputing offset for sensor %6s ... ', sensors(ii).sn);
        
        offsets(ii) = compute_dunk_xcorr(data{ii}.dt,sensor_t,base_dt,base_t,cfg.display_figures);
    end 

    % close any figures we might have made
    close all

    % make a plot of dunk interval before and after offsets
    fig = figure(visible='off',Units='Normalized',OuterPosition=[0,0,1,1]);
    ax1 = subplot(2,1,1);
    hold on
    ax2 = subplot(2,1,2);
    hold on
    for ii = 1:length(offsets)
        if ii == time_base_index
            lw = 2;
            c = 'r';
        else
            lw = 0.5;
            c = 'k';
        end
        idx = (data{ii}.dt >= dunk_interval(1)) & ...
            (data{ii}.dt <= dunk_interval(2));
        h1 = plot(ax1,data{ii}.dt(idx),data{ii}.t(idx),color=c,linewidth=lw);
        h2 = plot(ax2,data{ii}.dt(idx)+offsets(ii),data{ii}.t(idx),color=c,linewidth=lw);
        if ii == time_base_index
            top1 = h1;
            top2 = h2;
        end
    end
    uistack(top1,'top')
    uistack(top2,'top')
    linkaxes([ax1,ax2])
    xlim(dunk_interval)
    xlabel('Time')
    ylabel(ax1,'T [ degC ]')
    ylabel(ax2,'T [ degC ]')
    title(ax1,'Without offsets')
    title(ax2,'With offsets')
    sgtitle('Dunk Interval')
    % save figure
    if ~isempty(cfg.dir_fig)
        print(fig,fullfile(cfg.dir_fig,'time_offsets.png'),'-dpng','-r600')
    end
    % display figure until closed
    if cfg.display_figures
        uiwait(fig)
    end
end