function save_sections(data,gridded,cfg,sensors)

    if ~cfg.save_output; return; end
    
    if ~isempty(cfg.dir_sections) && ~isempty(cfg.section_times)
        fprintf('Saving section files\n');
        write_sections_to_nc(data,gridded,cfg,sensors);
        fprintf('Finished making section files!\n')
    end
end