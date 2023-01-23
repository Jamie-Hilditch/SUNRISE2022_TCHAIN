function gridded = cm_catenary(gridded,cfg)

% A catenary chain hanging from a ship has the form x(z) = k*cosh(z/k)
% We want to solve for the k parameter and compute all sensor z positions using:
% - l: sensor distances (arclengths) along chain (known)
% - z: sensor z-positions (partially known via pressure)
% - x: Unknown sensor x-positions (unknown)

% l, x, and z are all related via the following formulas:
l2x = @(l,a) a.*asinh(l./a); % Along-chain position to backward position
x2z = @(x,a) -a.*cosh(x./a) + a; % Backward position to vertical position
%l2z = @(l,a) -a.*cosh(asinh(l./a)) + a; % along-chain position to vertical position
l2z = @(l,a) a.*(1 - sqrt(1 + (l./a).^2)); % rewrite using hyp-trig identities
lz2a = @(l,z) (z.^2 - l.^2)./z/2; % get a from z and l

% Want to minimize the difference between l2z(l) and z
a = nan(size(gridded.dn));
%hasp = find(~all(isnan(gridded.p),2));
%amax = 1e3;  % almost flat
%amin = 1e-5; % almost vertical

for i = 1:length(gridded.dn)
    hasp = find(~isnan(gridded.p(:,i)));
    z = -gridded.p(hasp,i);
    l = gridded.pos(hasp);
    a_exact = lz2a(l,z);
    amin = min(a_exact,[],'all','omitnan')/2;
    amax = max(a_exact,[],'all','omitnan')*2;
    minfunc = @(a) rssq(z - l2z(l,a));
%     if i == 1
%         a(i) = fminbnd(minfunc,amin,amax); % search full range
%     else
%         % search within a smaller range around last estimate
%         a(i) = fminbnd(minfunc,max(amin,a(i-1)/2),min(amax,a(i-1)*2));
%     end
    a(i) = fminbnd(minfunc,amin,amax);
    if ~mod(i,1000)
        fprintf('Computing catenary chain shapes (%.2f%%)\n',100*i/length(gridded.dn))
    end
end

gridded.info.catenary_a = a;
gridded.info.catenary_pos_to_x = 'a*asinh(l/a)';
% gridded.info.catenary_pos_to_z = '-a*cosh(asinh(l/a)) + a';
gridded.info.catenary_pos_to_z = 'a*(1 - (1 + (l/2)^2)^0.5)';

gridded.x = -l2x(gridded.pos,a);
gridded.z = l2z(gridded.pos,a);

fprintf('\nDone!\n')
