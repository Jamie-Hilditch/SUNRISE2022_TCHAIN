function offset = compute_dunk_offset(dn,temp,base_dn,base_t)
    
    % the max lag
    max_lag = 10/(60*60*24); % 10 seconds

    base_t_std = sum(base_t.^2)^0.5;

    % remove nans from temp
    idx = isfinite(temp);
    % create an interpolant object
    interpolant = griddedInterpolant(dn(idx),temp(idx));

    % create a function that computes 1 - the correlation given a lag
    function rho_comp = correlation_comp(lag)
        % interpolate the temp onto the base time - lag
        lagged_temp = interpolant(base_dn - lag);
        % compute the correlation
        rho_comp = 1 - sum(lagged_temp.*base_t)./sum(lagged_temp.^2)^0.5./base_t_std;
    end

    % use squared error
    % function epsilon = squared_difference(lag)
    %     % interpolate the temp onto the base time - lag
    %     lagged_temp = interpolant(base_dn - lag);
    %     epsilon = sum((lagged_temp - base_t).^2);
    % end

    % set optimisation options 
    options = optimset('Display','none','TolX',0.1/(60*60*24));

    % find the lag that maximised the correlation
    [offset, rho_comp] = fminbnd(@correlation_comp,-max_lag,max_lag,options);
    % [offset, rho_comp] = fminbnd(@squared_difference,-max_lag,max_lag,options);
    disp(['Offset = ' num2str(offset) ' Correlation = ' num2str(1 - rho_comp)]);
end