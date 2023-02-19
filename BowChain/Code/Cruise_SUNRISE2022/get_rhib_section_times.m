function section_times = get_rhib_section_times(directory,min_time)
    % extract section start and end times from the parsed rhib log files
    arguments
        directory {mustBeFolder}
        min_time (1,1) duration = hours(1)
    end
    
    % get the parsed log files
    parsed_files = dir(fullfile(directory,'screen_root_*.log.parsed.mat'));
    filenames = {parsed_files.name};
    
    % function to extract the relevant fields
    function field = get_leg_info_field(fn,fieldname)
        leg_info = load(fullfile(directory,fn),'leg_info');
        field = leg_info.leg_info.(fieldname);
    end
    
    % get all the start and end times from the different files
    start_times = cellfun(@(fn) get_leg_info_field(fn,'startdate'),filenames,UniformOutput=false);
    end_times = cellfun(@(fn) get_leg_info_field(fn,'enddate'),filenames,UniformOutput=false);
    
    % concatenate the start and end times into one array
    start_times = cell2mat(start_times);
    end_times = cell2mat(end_times);
    
    % convert to datetimes
    start_times = datetime(start_times,'ConvertFrom','datenum');
    end_times = datetime(end_times,'ConvertFrom','datenum');
    
    % find all the sections that are longer than the min_time
    idx = (end_times - start_times) >= min_time;
    
    % transpose and stack into section_times array
    section_times = [start_times(idx)', end_times(idx)'];

end
