function data = parse_rbr_duet(f_in)
    data = struct();
    rbr = RSKopen(f_in);
    tmp = RSKreaddata(rbr);
    [tmp,~] = RSKcorrecthold(tmp);
    data.dn = tmp.data.tstamp;
    data.t = tmp.data.values(:,getchannelindex(tmp, 'Temperature'));
    data.p = tmp.data.values(:,getchannelindex(tmp, 'Pressure'));
end
