function data = Polly_20220626_sensor_077565_remove_bad_temp(data,~,sensors)
    idx = find(strcmp({sensors.sn},'77565'));
    dt = data{idx}.dt;
    time = datetime('2022-07-01 19:14:58');
    tidx = dt >= time;
    data{idx}.t(tidx) = nan;
    fprintf('Removed bad temperature data from sensor 77565 after %s\n',time)
end