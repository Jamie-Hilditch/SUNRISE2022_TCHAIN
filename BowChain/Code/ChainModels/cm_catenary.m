function gridded = cm_catenary(gridded,~)
    % fits a catenary to the pressure sensors
    % details of the method can be found in the README.md file

    fprintf('Using catenary chain model. This may take a while ...\n')

    % define z' as a function of s,b,c
    zprime = @(s,b,c) sqrt(s.^2 - 2*b.*s + c.^2) - c;

    % define a function to compute b,c exactly from two points
    function [ b,c ] = bc_exact(s1,zp1,s2,zp2)
        A = [s1,zp1;s2,zp2];
        y = [(s1^2 - zp1^2)/2; (s2^2 - zp2^2)/2];
        x = A\y;
        b = x(1); c = x(2);
        if b < 0 || c < b
            b = nan; c= nan;
        end
    end

    % now define the function to be minimised
    function [r, grad, Hess] = squared_error(b,c,s,zp)
        err = zprime(s,b,c)-zp;
        invsqrt = 1./sqrt(s.^2-2*s.*b + c^2); % common factor
        r = mean(err.^2);
        drdb = mean(2*err.*-s.*invsqrt);
        drdc = mean(2*err.*(c*invsqrt - 1));
        grad = [drdb, drdc];
        d2rdb2 = mean(2*s.^2.*invsqrt.^2 + 2*err.*-s.^2.*invsqrt.^3);
        d2rdbdc = mean(2*-s.*invsqrt.*(c*invsqrt - 1) + 2*err.*s.*c.*invsqrt.^3);
        d2rdc2 = mean(2*(c*invsqrt - 1).^2 + 2*err.*(s.^2 - 2*s.*b).*invsqrt.^3);
        Hess = [d2rdb2, d2rdbdc; d2rdbdc, d2rdc2];
    end

    % need these for parfor loop
    bc_exact_handle = @bc_exact;
    squared_error_handle = @squared_error;
    
    % define arrays for results
    Ntimes = length(gridded.dn);
    catenary_z0 = nan(1,Ntimes);
    catenary_s0 = nan(1,Ntimes);
    catenary_a = nan(1,Ntimes);
    catenary_b = nan(1,Ntimes);
    catenary_c = nan(1,Ntimes);
    catenary_rms_error = nan(1,Ntimes);
    
    % exact variables for parfor loop
    pressure = gridded.p;
    pos = gridded.pos;
    x_grid = nan(size(gridded.x));
    z_grid = nan(size(gridded.x));

    % for each timestep (parallelise the for loop because this can be really slow)
    parfor i = 1:Ntimes
        % get the pressure sensors
        p = pressure(:,i);
        hasp = ~isnan(p);
        z = -p(hasp);
        if length(z) < 3; continue; end % not enough sensors to fit catenary
        z0 = z(1); % first pressure sensor
        if z0 > 0; continue;  end % sensor is out of the water
        zp = z(2:end) - z0; % fit to remaining pressure sensors
        ppos = pos(hasp); % position of pressure sensors on chain
        s = ppos(2:end) - ppos(1); % define s = 0 at first pressure sensor
        
        % b - s > 0 on chain
        bmin = s(end)

        % compute the exact b and c for every pair of remaining pressure sensors
        Npressure = length(zp);
        b_exact = nan(Npressure*(Npressure-1)/2,1);
        c_exact = nan(Npressure*(Npressure-1)/2,1);
        ii = 1;
        for jj = 2:Npressure
            for kk = 1:jj-1
                [b_exact(ii), c_exact(ii)] = bc_exact_handle(s(jj),zp(jj),s(kk),zp(kk));
                ii = ii + 1;
            end
        end

        % initial condition for the minimisation will be median of exact values
        b0 = median(b_exact,'omitnan');
        c0 = median(c_exact,'omitnan');
        if isnan(b0) || b0 < bmin; b0 = bmin*1.1; end
        if isnan(c0) || c0 < b0; c0 = b0*1.1; end

        % function to be minimised
        func = @(x) squared_error_handle(x(1),x(2),s,zp);

        % now set the minimisation problem
        options = optimoptions( ...
            'fminunc', ...
            Algorithm='trust-region', ...
            SpecifyObjectiveGradient=true, ...
            HessianFcn='objective', ...
            Display='off', ...
            MaxIterations=50 ...
        );
            
        % solve minimisation problem
        try
            [x, fval, exitflag, output] = fminunc(func,[b0,c0],options);
        catch ME
            warning(ME.message)
            continue
        end
        % if unsuccessful continue without saving values
        if exitflag <= 0
            fprintf('i = %06d: Exited with exitflag %d and message %s\n', ...
                i,exitflag,output.message);
            continue
        end
        
        % get b,c and rms_error
        b = x(1);
        c = x(2);
        rms_error = sqrt(fval);

        % compute a and s0
        if b <= bmin; continue; end % b must be larger than the chain
        if b > c; continue; end % otherwise a is complex
        a = sqrt(c^2 - b^2);
        s0 = (b - sqrt(b^2 + 4*z0^2 -8*z0*c))/2;

        % save values
        catenary_a(i) = a;
        catenary_b(i) = b;
        catenary_c(i) = c;
        catenary_rms_error(i) = rms_error;
        catenary_z0(i) = z0;
        catenary_s0(i) = s0;

        % compute z and x
        s = pos - ppos(1); % need all the sensor positions
        x_grid(:,i) = a*(asinh((b - s0)/a) - asinh((b - s)/a));
        z_grid(:,i) = sqrt(s.^2 -2*b*s + c^2) - c + z0;

        
    end

    % for debugging
    % keyboard

    % now save x and z positions 
    gridded.x = x_grid;
    gridded.z = z_grid;

    % save info
    gridded.info.catenary_a = catenary_a;
    gridded.info.catenary_b = catenary_b;
    gridded.info.catenary_c = catenary_c;
    gridded.info.catenary_rms_error = catenary_rms_error;
    gridded.info.catenary_z0 = catenary_z0;
    gridded.info.catenary_s0 = catenary_s0;
    gridded.info.catenary_s_to_x = 'a(asinh(b-s0/a) - asinh((b-s)/a))';
    gridded.info.catenary_s_to_z = 'z0 + (a^2 + (b^2 - s^2))^0.5 - (a^2 + b^2)^0.5';

    fprintf('Done!\n')
end