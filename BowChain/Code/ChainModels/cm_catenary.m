function gridded = cm_catenary(gridded,~)
    % fits a catenary to the pressure sensors
    % details of the method can be found in the README.md file

    fprintf('Using catenary chain model. This may take a while ...\n')

    % define a function to compute k,th exactly from two points
    function [ k,th ] = two_point_exact(s1,zp1,s2,zp2)
        A = [s1,zp1;s2,zp2];
        
        % singular matrix -> k = 0
        if rcond(A) < 1e-15 
            k = 0;
            th = asin(-s1/zp1);
            return
        end

        y = [(s1^2 - zp1^2)/2; (s2^2 - zp2^2)/2];
        x = A\y;
        th = asin(x(1)/x(2));
        k = tan(th)/x(1);

        if ~isreal(th) || ~isreal(k)
            th = nan;
            k = nan;
        end
    end

    % now define the function to be minimised
    function [r, grad, Hess] = squared_error(k,th,s,zp) 
        % All the quantities have removable singularities at k = 0
        % If k = 0, we compute the limit exactly for the function value and
        % the derivative then make k nonzero to get a very good approximation 
        % to the Hessian
        if k == 0
            err = -sin(th).*s-zp;
            r = mean(err.^2);
            drdk = mean(2*err.*0.5*cos(th)^3.*s.^2);
            drdth = mean(2*err.*tan(th).*(sin(th) - 1).*s);
    
            % make k some tiny nonzero number to compute Hessian
            k = 10*eps;
            invsqrt = 1./sqrt(k.^2.*s.^2-2*k.*s.*tan(th) + sec(th).^2); % common factor
        else
            err = (sqrt(sec(th).^2 - 2*k.*s.*tan(th) + k.^2.*s.^2) - sec(th))./k - zp;
            r = mean(err.^2);
            invsqrt = 1./sqrt(k.^2.*s.^2-2*k.*s.*tan(th) + sec(th).^2); % common factor
            drdk = mean(2*err.*((k.*s.*tan(th) - sec(th).^2).*invsqrt + sec(th))./k.^2);
            drdth = mean(2*err.*((sec(th).^2.*(tan(th) - k.*s).*invsqrt - sec(th).*tan(th))./k));
        end
    
        d2rdk2 = mean( ...
          2*(  ...
              (((k.*s.*tan(th) - sec(th).^2).*invsqrt + sec(th))./k.^2).^2 + ...
              err.*( ...
                     k.^-3.*((s.^2.*k.^2).*invsqrt.^3 - ...
                     2*((k.*s.*tan(th) - sec(th)^2).*invsqrt + sec(th))) ...
                   ) ...
            ) ...
        );
        d2rdkdth = mean(...
            2*k.^-3.*((k.*s.*tan(th) - sec(th).^2).*invsqrt + sec(th)).* ...
            (sec(th).^2.*(tan(th) - k.*s).*invsqrt - sec(th).*tan(th)) + ...
            2*err.*( ...
                    k.^-2.*(sec(th)^2*((k*s - tan(th)).^3 - tan(th)).*invsqrt.^3 + sec(th)*tan(th)) ...
                    ) ...
        );
        d2rdth2 = mean( ...
            2*k^-2*(sec(th).^2.*(tan(th) - k.*s).*invsqrt - sec(th).*tan(th)).^2 + ...
            2*err.*k^-1.*( ...
                         -sec(th)^4*(tan(th) - k.*s).^2.*invsqrt.^3 + ...
                         sec(th)^2.*(sec(th)^2 + 2*tan(th)*(tan(th) - k.*s)).*invsqrt ...
                         - sec(th)*tan(th)^2 - sec(th)^3 ...
                         ) ...
        );
                      
    
        grad = [drdk; drdth];
        Hess = [d2rdk2, d2rdkdth; d2rdkdth, d2rdth2];
           
    end

    % need these for parfor loop
    two_point_exact_handle = @two_point_exact;
    squared_error_handle = @squared_error;
    
    % define arrays for results
    Ntimes = length(gridded.dt);
    catenary_z0 = nan(1,Ntimes);
    catenary_s0 = nan(1,Ntimes);
    catenary_k = nan(1,Ntimes);
    catenary_th = nan(1,Ntimes);
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
        s0 = ppos(1); % define x = 0 at top of the chain
        s = ppos(2:end) - s0; % define s = 0 at first pressure sensor

        % compute the exact k and th for every pair of remaining pressure sensors
        Npressure = length(zp);
        k_exact = nan(Npressure*(Npressure-1)/2,1);
        th_exact = nan(Npressure*(Npressure-1)/2,1);
        ii = 1;
        for jj = 2:Npressure
            for kk = 1:jj-1
                [k_exact(ii), th_exact(ii)] = two_point_exact_handle(s(jj),zp(jj),s(kk),zp(kk));
                ii = ii + 1;
            end
        end

        % initial condition for the minimisation will be median of exact values
        k0 = median(k_exact,'omitnan');
        th0 = median(th_exact,'omitnan');
        if isnan(k0); k0 = 0; end
        if isnan(th0); th0 = pi/4; end

        % function to be minimised
        func = @(x) squared_error_handle(x(1),x(2),s,zp);

        % now set the minimisation problem
        options = optimoptions( ...
            'fminunc', ...
            Algorithm='trust-region', ...
            SpecifyObjectiveGradient=true, ...
            HessianFcn='objective', ...
            Display='off', ...
            MaxIterations=200 ...
        );
            
        % solve minimisation problem
        try
            [x, fval, exitflag, output] = fminunc(func,[k0,th0],options);
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
        
        % get k,th and rms_error
        k = x(1);
        th = x(2);
        rms_error = sqrt(fval);

        % save values
        catenary_k(i) = k;
        catenary_th(i) = th;
        catenary_rms_error(i) = rms_error;
        catenary_z0(i) = z0;
        catenary_s0(i) = s0;

        % compute z and x
        s = pos - s0; % need all the sensor positions
        if k ~= 0
            x_grid(:,i) = (asinh(tan(th) + k*s0) - asinh(tan(th) - k.*s))/k;
            z_grid(:,i) = (sqrt(sec(th)^2 - 2*k.*s.*tan(th) + k^2.*s.^2) - sec(th))/k + z0;
        else
            x_grid(:,i) = (s + s0).*cos(th);
            z_grid(:,i) = z0 - sin(th).*s;
        end

        
    end

    % for debugging
    % keyboard

    % now save x and z positions 
    gridded.x = -x_grid;
    gridded.z = z_grid;

    % save info
    gridded.info.catenary_k = catenary_k;
    gridded.info.catenary_th = catenary_th;
    gridded.info.catenary_rms_error = catenary_rms_error;
    gridded.info.catenary_z0 = catenary_z0;
    gridded.info.catenary_s0 = catenary_s0;
    gridded.info.catenary_s_to_x = '(asinh(tan(th)+k*s0) - asinh(tan(th)-k*s))/k';
    gridded.info.catenary_s_to_z = 'z0 + (sec(th)^2 - 2*k*s*tan(th) + k^2*s^2)^0.5 - sec(th))/k';

end