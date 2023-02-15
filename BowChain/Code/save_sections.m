function save_sections(data,gridded,cfg)
    
    if isnonemptyfield(cfg,'dir_sections') && isnonemptyfield(cfg,'section_times')
        fprintf('Saving section files\n');
        write_sections_to_nc(data,gridded,cfg);
        fprintf('Finished making section files!\n')
    end
end