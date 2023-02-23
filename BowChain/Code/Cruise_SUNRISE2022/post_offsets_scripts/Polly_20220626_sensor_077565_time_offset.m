function [data, time_offsets] = Polly_20220626_sensor_077565_time_offset(data,time_offsets,sensors)
    true_offset = seconds(0.5);
    idx = find(strcmp({sensors.sn},'77565'));
    old_offset = time_offsets(idx);
    data{idx}.dt = data{idx}.dt - old_offset + true_offset;
    time_offsets(idx) = true_offset;
    fprintf('Corrected time offset for sensor 77565. New offset is %.1fs\n',true_offset/seconds(1))
end