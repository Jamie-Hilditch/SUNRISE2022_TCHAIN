function [timeseries, spikes] = despike(timeseries,options)
    % despike a timeseries using a similar algorithm to RBR despike
    % 1) construct a reference timeseries using a median filter
    % 2) find residual between the original and reference timeseries
    % 3) residuals greater than threshold*std are considered spikes
    % 4) replace spikes with nans
    % inputs:
    %   timeseries: timeseries to be despiked
    % keyword inputs:
    %   threshold: number of standard deviations used to find spikes
    %   windowLength: window length of the median filter 
    %   display_figure: if true create a figure showing timeseries and
    % spikes
    %
    % Jamie Hilditch 2023
    arguments 
        timeseries (1,:) {mustBeFloat}
        options.threshold (1,1) double = 2
        options.windowLength (1,1) int32 {mustBePositive} = 3
        options.display_figure (1,1) logical = false
    end
    
    % extract optional arguments
    threshold = options.threshold;
    windowLength = options.windowLength;
    display_figure = options.display_figure;
    
    % create the reference timeseries using median filter
    reference = medfilt1(timeseries,windowLength,'omitnan');

    % compute residuals and standard deviation
    residuals = timeseries - reference;
    standard_deviation = std(residuals,'omitnan');

    % find spikes
    spikes = find(abs(residuals) > threshold*standard_deviation);
    
    % make figure if requested
    if display_figure
        fig = figure;
        hold on
        p1 = plot(timeseries,'r',DisplayName='Original timeseries');
        p2 = plot(reference,'k',DisplayName='Reference timeseries');
        p3 = plot(reference + threshold*standard_deviation,'g--',DisplayName='Threshold');
        plot(reference - threshold*standard_deviation,'g--',DisplayName='')
        p4 = plot(spikes,timeseries(spikes),'bo',DisplayName='Spikes');
        legend([p1,p2,p3,p4])
        title('Despiking Timeseries')
        uiwait(fig);
    end

    % set spikes to nan
    timeseries(spikes) = nan;
end