function data = parse_rbr_solo(f_in)
    data = struct();
    rbr = RSKopen(f_in);
    tmp = RSKreaddata(rbr);
    [tmp,~] = RSKcorrecthold(tmp,channel='Temperature');
    data.dn = tmp.data.tstamp;
    data.t = tmp.data.values;
    % include code to add salinity to structure here
end
