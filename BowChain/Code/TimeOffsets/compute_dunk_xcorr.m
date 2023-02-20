function offset = compute_dunk_xcorr(dt,temp,base_dt,base_t,display_figure)
    
    % time spacing of base 
    delta_t = mean(diff(base_dt));

    % make the max lag half the dunk interval
    maxlag = int32((base_dt(end)-base_dt(1))/2/delta_t);

    % remove nans from temp
    idx = isfinite(temp);
    % interpolate onto base time grid
    % interpolant = griddedInterpolant(dt(idx),temp(idx));
    % interpolated_t = interpolant(base_dt);
    interpolated_t = interp1(dt(idx),temp(idx),base_dt);
    
    % compute the cross-correlation
    % [r,lags] = xcorr(base_t,interpolated_t,maxlag,'unbiased');
    [lags,r, ~, ~, ~] = crosscorr_NAN42(base_t,interpolated_t,maxlag);
    % find the lag with maximum correlation
    [max_r,idx] = max(r);
    lag_idx = lags(idx);
    offset = lag_idx*delta_t;

    if abs(lag_idx) == maxlag
        warning('Maximum correlation found on boundary')
    end

    % make a quick plot
    % plot(lags*dt*days2seconds,r/norm,'b-',offset*days2seconds,max_r/norm,'kx');
    if display_figure
        plot(lags*delta_t/seconds(1),r,'b-',offset/seconds(1),max_r,'kx');
        xlabel('Offset [s]');
        ylabel('Normalised X-corr');
        pause(0.5);
    end

    disp(['Offset = ' num2str(offset/seconds(1)) 's Correlation = ' num2str(max_r)]);

end