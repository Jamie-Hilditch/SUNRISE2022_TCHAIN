function preproc_raw2mat(config, sensors)
% Convert raw sensor data to .mat format

fprintf('Converting raw data to .mat files ...\n')

for i = 1:length(sensors)
    
    % Check if .mat files already exist
    [~,fname,fext] = fileparts(sensors(i).file_raw);
    if exist(sensors(i).file_mat,'file') && ~config.raw2mat
        % Skip
        fprintf('\t%s.mat already exists\n',fname)
    else
        fprintf('\t%s%s --> %s.mat\n',fname,fext,fname)

        % Parse raw sensor data
        data = feval(sensors(i).parse_func,...
                     sensors(i).file_raw);
        data.dt = datetime(data.dn,'ConvertFrom','datenum');
        % Save .mat file
        data.sn = sensors(i).sn;
        save(sensors(i).file_mat,'-struct','data');
    end
end
