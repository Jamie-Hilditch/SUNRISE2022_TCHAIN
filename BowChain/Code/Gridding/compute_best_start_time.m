function dn_start = compute_best_start_time(target,perd_base,data)
    % compute the start time that minimises the amount of interpolation we
    % need to do

    fprintf('Computing best start time near %s\n',datetime(target,'ConvertFrom','datenum'));
    
    % possible start times
    min_start = target - perd_base/2;
    max_start = target + perd_base/2;
    trial_step = perd_base/20;
    potential_start_times = min_start:trial_step:max_start;
    
    % extract a subset of the dns around the target from the data
    function [ dns ] = get_subset_dn(S)
        nearest = min(abs(S.dn - target));
        min_dn = min_start - abs(min_start - nearest);
        max_dn = max_start + abs(max_start - nearest);
        dns = S.dn(S.dn >= min_dn & S.dn <= max_dn);
    end
    subsets = cellfun(@(S) get_subset_dn(S),data,'UniformOutput',false);

    % given a potential start time, compute the total over all sensors of 
    % the difference between the start time and it's nearest neighbour 
    function [ diff ] = compute_time_differences(pot_start)
        % for each sensor compute the time difference between the potential
        % start time and it's nearest neighbour
        dns2diff = @(dns) min(abs(dns - pot_start));
        diffs = cellfun(dns2diff,subsets);
        % now sum for the total
        diff = sum(diffs);
    end
    
    time_differences = arrayfun(@(ps) compute_time_differences(ps),potential_start_times);
    
    % choose the start time that minimises the total difference
    [~,idx] = min(time_differences);
    dn_start = potential_start_times(idx);

    fprintf('Using start time %s\n',datetime(dn_start,'ConvertFrom','datenum','Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end