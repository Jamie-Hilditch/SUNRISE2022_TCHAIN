function data = parse_rbr_concerto(f_in)
    data = struct();
    [rbr] = RSKopen(f_in);
    tmp = RSKreaddata(rbr);
    [tmp,~] = RSKcorrecthold(tmp);
    CT_lag = RSKcalculateCTlag(tmp);
    tmp = RSKalignchannel(tmp, 'channel', 'Conductivity', 'lag', CT_lag);
    tmp = RSKderivesalinity(tmp);
    data.dn = tmp.data.tstamp;
    data.c = tmp.data.values(:,getchannelindex(tmp, 'Conductivity'));
    data.t = tmp.data.values(:,getchannelindex(tmp, 'Temperature'));
    data.p = tmp.data.values(:,getchannelindex(tmp, 'Pressure'));
    data.s = tmp.data.values(:,getchannelindex(tmp, 'Salinity'));
end
