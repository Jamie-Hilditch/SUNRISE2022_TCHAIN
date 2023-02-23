function [data, pressure_offsets] = Pelican_20220625_sensor_060558_pressure_offset(data,pressure_offsets,sensors)
    idx = find(strcmp({sensors.sn},'60558'));
    dt = data{idx}.dt;
    tidx = dt <= datetime('2022-06-25 16:27:30');
    p0 = mean(data{idx}.p(tidx),'omitnan');
    data{idx}.p = data{idx}.p - p0;
    pressure_offsets(idx) = p0;
    fprintf('Removed %.2f pressure offset from sensor 60558\n',p0);
end