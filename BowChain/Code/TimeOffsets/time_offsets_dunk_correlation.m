function offsets = time_offsets_dunk_correlation(data,cfg)

    % initialise the offsets
    offsets = zeros(length(data),1);

    % get the serial number of the sensor we're using as our time base
    if isfield(cfg,'time_base_sensor_sn')
        sensor_sn = cfg.time_base_sensor_sn;
    else
        warning('No sensor specified as the time base for computing offsets. Using sensor 1.')
        sensor_sn = cfg.sensor_sn{1};
    end
    % serial numbers should be a char array
    if isnumeric(sensor_sn)
        sensor_sn = num2str(sensor_sn);
    end

    % get the position of the sensor we're using as our time base
    time_base_index = find(strcmp(cfg.sensor_sn,sensor_sn));
    if isempty(time_base_index)
        warning(['Could not find sensor ' cfg.time_base_sensor_sn '. No time offsets calculated.'])
        return 
    end
    time_base_index = time_base_index(1);

    % get the dunk_interval
    if isfield(cfg,'dunk_interval')
        dunk_interval = cfg.dunk_interval;
    else 
        warning('No dunk interval specified. No time offsets calculated.')
        return 
    end

    % get the time and temperature for our base 
    base_idx = (data{time_base_index}.dn >= datenum(dunk_interval(1))) & ...
            (data{time_base_index}.dn <= datenum(dunk_interval(2)));
    base_dn = data{time_base_index}.dn(base_idx);
    base_t = data{time_base_index}.t(base_idx);

    % fill in any nans in base_t
    base_t = fillmissing(base_t,'linear');

    % subtract off a mean to make correlation cleaner
    mean_t = mean(base_t);
    base_t = base_t - mean_t;

    for ii = 1:length(offsets)
        if ii == time_base_index
            % skip base time
            continue
        end
        fprintf('\tComputing offset for sensor %02d ... ', ii);
        disp_fig = isfield(cfg,'display_figures') && cfg.display_figures;
        offsets(ii) = compute_dunk_xcorr(data{ii}.dn,data{ii}.t - mean_t,base_dn,base_t,disp_fig);
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
        idx = (data{ii}.dn >= datenum(dunk_interval(1))) & ...
            (data{ii}.dn <= datenum(dunk_interval(2)));
        h1 = plot(ax1,datetime(data{ii}.dn(idx),'ConvertFrom','datenum'),data{ii}.t(idx),color=c,linewidth=lw);
        h2 = plot(ax2,datetime(data{ii}.dn(idx)+offsets(ii),'ConvertFrom','datenum'),data{ii}.t(idx),color=c,linewidth=lw);
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
    if isfield(cfg,'dir_fig') && ~isempty(cfg.dir_fig)
        print(fig,fullfile(cfg.dir_fig,'time_offsets.png'),'-dpng','-r600')
    end
    % display figure until closed
    if isfield(cfg,'display_figures') && cfg.display_figures
        uiwait(fig)
    end
end