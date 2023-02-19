function sensors = preproc_setup(config)

fprintf('Identifying sensors and finding data ...\n')

setup_override_fname = ['setup_override_' config.cruise '.m'];
if isfile(setup_override_fname)
    fprintf('\tOverriding default setup with %s.\n',setup_override_fname)
    sensors = feval(setup_override_fname,config);
    return
end

pos_ind = 0; % position index

sensor_dir_func = ['sensor_dirs_' config.cruise '.m'];

for i = 1:length(config.sensor_sn)
    % Associate a parsing function and file extension with a serialnum
    [sensor_type, parse_func, ext, sn, status] = get_sensor_info(config.sensor_sn{i});
    if status==0 % found parsing func and file ext for serial
        if isfile(sensor_dir_func)
            [fpath_raw, fpath_proc] = feval(sensor_dir_func,config,sn);
        else
            fpath_raw = config.dir_raw;
            fpath_proc = config.dir_proc;
        end
        if ~isfolder(config.dir_proc)
            mkdir(config.dir_proc);
        end

        file_raw = dir(fullfile(fpath_raw,['*' sn '*' ext]));
        if length(file_raw) == 1
            pos_ind = pos_ind + 1;
            fn_raw = file_raw.name;
            [~,fname,~] = fileparts(fn_raw);
            fn_mat = [fname, '.mat'];
            sensors(pos_ind) = struct(...
                'sn'          , sn                          ,...
                'file_raw'    , fullfile(fpath_raw,fn_raw)  ,...
                'file_mat'    , fullfile(fpath_proc,fn_mat) ,...
                'sensor_type' , sensor_type                 ,...
                'parse_func'  , parse_func                  ,...
                'pos'         , config.sensor_pos(i)        ,...
                'pos_ind'     , pos_ind);
            msg = '\t%s [%s]\n';
            fprintf(msg,sensor_type,sn);
        else
            msg = '\t%s [%s]: %d raw file(s), skipped!\n';
            fprintf(msg,sensor_type,sn,length(file_raw));
        end
    else
        fprintf('\tNo sensor information found for [%s]\n',sn)
    end
end
