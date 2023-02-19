function offsets = time_offsets_cohere(gridded,~,cfg)

offsets = zeros(size(gridded.t,1),1);
for i = 2:length(offsets)
  % Get time offset
  % TODO rewrite this method to use datetimes not datenums
  offsets(i) = determine_t_offset(datenum(gridded.dt)',gridded.t(i-1,:)',...
                                  datenum(gridded.dn)',gridded.t(i,:)',datenum(cfg.cohere_interval));
end
offsets = cumsum(offsets);
