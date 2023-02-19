function dt_start = compute_best_start_time(target,perd_base,data)
    % compute the start time that minimises the amount of interpolation we
    % need to do

    if isnat(target)
        data_start_times = cellfun(@(S) S.dt(1),data);
        target = max(data_start_times);
    end

    fprintf('Computing best start time near %s\n',target);
    
    % possible start times
    min_start = target - perd_base/2;
    max_start = target + perd_base/2;
    trial_step = perd_base/20;
    potential_start_times = min_start:trial_step:max_start;
    
    % extract a subset of the dns around the target from the data
    function [ dts ] = get_subset_dt(S)
        [~,nearest_idx] = min(abs(S.dt - target));
        nearest = S.dt(nearest_idx);
        min_dt = min_start - abs(min_start - nearest);
        max_dt = max_start + abs(max_start - nearest);
        dts = S.dt(S.dt >= min_dt & S.dt <= max_dt);
    end
    subsets = cellfun(@(S) get_subset_dt(S),data,'UniformOutput',false);

    % given a potential start time, compute the total over all sensors of 
    % the difference between the start time and it's nearest neighbour 
    function [ diff ] = compute_time_differences(pot_start)
        % for each sensor compute the time difference between the potential
        % start time and it's nearest neighbour
        dns2diff = @(dts) min(abs(dts - pot_start));
        diffs = cellfun(dns2diff,subsets);
        % now sum for the total
        diff = sum(diffs);
    end
    
    time_differences = arrayfun(@(ps) compute_time_differences(ps),potential_start_times);
    
    % choose the start time that minimises the total difference
    [~,idx] = min(time_differences);
    dt_start = potential_start_times(idx);

    fprintf('Using start time %s\n',dt_start);
end