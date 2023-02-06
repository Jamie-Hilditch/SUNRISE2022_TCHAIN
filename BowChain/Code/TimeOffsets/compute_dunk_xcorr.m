function offset = compute_dunk_xcorr(dn,temp,base_dn,base_t,display_figure)
    
    % time spacing of base 
    dt = mean(diff(base_dn));

    % for converting dn to secs
    days2seconds = 60*60*24;

    % make the max lag half the dunk interval
    maxlag = int32((base_dn(end)-base_dn(1))/2/dt);

    % remove nans from temp
    idx = isfinite(temp);
    % interpolate onto base time grid
    interpolant = griddedInterpolant(dn(idx),temp(idx));
    interpolated_t = interpolant(base_dn);
    
    % compute the cross-correlation
    % [r,lags] = xcorr(base_t,interpolated_t,maxlag,'unbiased');
    [lags,r, ~, ~, ~] = crosscorr_NAN42(base_t,interpolated_t,maxlag);
    % find the lag with maximum correlation
    [max_r,idx] = max(r);
    lag_idx = lags(idx);
    offset = lag_idx*dt;

    if abs(lag_idx) == maxlag
        warning('Maximum correlation found on boundary')
    end

    % make a quick plot
    % plot(lags*dt*days2seconds,r/norm,'b-',offset*days2seconds,max_r/norm,'kx');
    if display_figure
        plot(lags*dt*days2seconds,r,'b-',offset*days2seconds,max_r,'kx');
        xlabel('Offset [s]');
        ylabel('Normalised X-corr');
        pause(0.5);
    end

    disp(['Offset = ' num2str(offset*days2seconds) 's Correlation = ' num2str(max_r)]);
end