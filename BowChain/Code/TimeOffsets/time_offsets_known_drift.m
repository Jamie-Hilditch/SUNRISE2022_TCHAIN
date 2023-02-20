function offsets = time_offsets_known_drift(data,cfg)

offsets = seconds(zeros(length(data),1));
for i = 1:length(data)
    dt0 = cfg.time_synched;
    dt1 = cfg.time_drift_measured;
    dt = data{i}.dt;
    drift = interp1([dt0 dt1],[seconds(0) cfg.drift(i)], dt);
    data{i}.time_offsets = -drift/seconds(1);
    offsets(i) = - drift;
    fprintf('Removed %d second clock drift from %s\n',cfg.drift(i)/seconds(1),cfg.sensor_sn{i});
end
