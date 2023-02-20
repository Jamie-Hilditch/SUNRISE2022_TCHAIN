function data = Aries_20220703_sensor_203188_despike_pressure(data,cfg,sensors)
    
    idx = find(strcmp({sensors.sn},'203188'));
    pressure = data{idx}.p;
    dt = data{idx}.dt;
    start_time = datetime('2022-07-05 09:00');
    end_time = datetime('2022-07-05 16:00');
    tidx = (dt >= start_time) & (dt <= end_time);

    fprintf('Despiking pressure from sensor 203188 between %s and %s\n',start_time,end_time)
    pressure_segment = pressure(tidx);
    pressure_segment = despike(pressure_segment,windowLength=25,display_figure=cfg.display_figures);
    data{idx}.p(tidx) = pressure_segment;

    
end