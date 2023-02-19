function offsets = time_offsets_known_drift(data,cfg)

offsets = zeros(length(data),1);
for i = 1:length(data)
    dt0 = cfg.time_synched;
    dt1 = cfg.time_drift_measured;
    dt = data{i}.dt;
    drift = interp1([dt0 dt1],[seconds(0) cfg.drift], dt);
    offsets(i) = - drift;
    fprintf('Removed %d second clock drift from %s\n',cfg.drift(i),cfg.sensor_sn{i});
end
