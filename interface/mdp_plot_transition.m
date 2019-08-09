function mdp_plot_transition(filename, x_conc, u_conc, min_or_max)

    if nargin ~= 4
        min_or_max = 'min';
    end

    % reading the data file and making some needed objects
    toy2dDataFile = DataFile(filename, true, true);
    [ss_quantizer, is_quantizer] = makeQuantizers(toy2dDataFile);
    symbolicDynamics = ReadDynamicsSymbolic(toy2dDataFile, [], [], {'(float)'});
    sigma = readCovarianceMatrix(toy2dDataFile);
    cutting_probability = str2double(toy2dDataFile.getMetadataElement('cutting-probability'))';
    org_cut_region_lb = str2double(split(toy2dDataFile.getMetadataElement('org-cutting-region-lb'),','))';
    org_cut_region_ub = str2double(split(toy2dDataFile.getMetadataElement('org-cutting-region-ub'),','))';
    ss_lb = str2double(split(toy2dDataFile.getMetadataElement('ss-lower-point'),','))';
    ss_ub = str2double(split(toy2dDataFile.getMetadataElement('ss-upper-point'),','))';
    ss_eta = str2double(split(toy2dDataFile.getMetadataElement('ss-eta'),','))';

    % alligning the given x,u to the grid
    x_conc = ss_quantizer.align(x_conc)';
    u_conc = is_quantizer.align(u_conc)';

    % symbolizing/flattening (x_conc) and (u_conc) to (x_sym) (u_sym) 
    x_sym = ss_quantizer.symbolize(x_conc);
    u_sym = is_quantizer.symbolize(u_conc);
    x_flat = ss_quantizer.flatten(x_sym);
    u_flat = is_quantizer.flatten(u_sym); 
    xubag = amytissXUBag(toy2dDataFile, x_flat, u_flat);

    % mu and cutting region
    mu = sys_post(x_conc, u_conc);
    mu_aligned = ss_quantizer.align(mu)';
    cut_region_lb = org_cut_region_lb+mu_aligned;
    cut_region_ub = org_cut_region_ub+mu_aligned;
    cut_region_quantizer = NdQuantizer(cut_region_lb, cut_region_ub, ss_eta, zeros(size(ss_eta)));


    %% Plotting
    % plotting src/dest
    plot3(x_conc(1), x_conc(2), 0, '*b');
    plot3(mu(1), mu(2), 0, '*r');
    plot3(mu_aligned(1), mu_aligned(2), 0, '*r');
    plot3(x_conc(1), x_conc(1), 0, '*g', 'LineWidth',3);
    quiver(x_conc(1),x_conc(2),mu_aligned(1)-x_conc(1),mu_aligned(2)-x_conc(2),0,'b','LineWidth',3);

    % plotting cutting region
    p1 = [cut_region_lb(1) cut_region_lb(2)];
    p2 = [cut_region_ub(1) cut_region_lb(2)];
    p3 = [cut_region_ub(1) cut_region_ub(2)];
    p4 = [cut_region_lb(1) cut_region_ub(2)];
    plot3( [p1(1) p2(1) p3(1) p4(1) p1(1)], [p1(2) p2(2) p3(2) p4(2) p1(2)], cutting_probability*ones(1,5),'r','LineWidth',3)

    % plotting probabilities
    num_reach_states = str2double(toy2dDataFile.getMetadataElement('num-reach-states'));
    sum_p_min = 0;
    sum_p_max = 0;
    for k=1:num_reach_states
        
        if xubag.is_safe_or_reach
            p_min = xubag.getPmin(k-1);
            p_max = xubag.getPmax(k-1);

            if strcmp(min_or_max, 'min')
                p = p_min;
            else
                p = p_max;
            end
        else
            p = xubag.getP1min(k-1);
        end

        xsym = cut_region_quantizer.unflatten(k-1);
        xconc = cut_region_quantizer.desymbolize(xsym);
        drawbar(xconc(1),xconc(2),p,ss_eta(1)/2);
        
        if xubag.is_safe_or_reach
            sum_p_min = sum_p_min + p_min;
            sum_p_max = sum_p_max + p_max;
        else
            sum_p_min = sum_p_min + p;
        end
    end

    if xubag.is_safe_or_reach
        disp(['Sum P-min = ' num2str(sum_p_min)]);
        disp(['Sum P-max = ' num2str(sum_p_max)]);
    else
        disp(['Sum P1 = ' num2str(sum_p_min)]);
    end

    % finalize
    axis([ss_lb(1) ss_ub(1) ss_lb(2) ss_ub(2)]);
    set(gca,'xtick',[ss_lb(1):ss_eta(1):ss_ub(1)]-ss_eta(1)/2);
    set(gca,'ytick',[ss_lb(2):ss_eta(2):ss_ub(2)]-ss_eta(2)/2);
    grid on;

    x1 = ss_lb(1):ss_eta(1):ss_ub(1);
    x2 = ss_lb(2):ss_eta(2):ss_ub(2);
    [X1,X2] = meshgrid(x1,x2);
    X = [X1(:) X2(:)];
    y = mvnpdf(X,mu,sigma);
    y = reshape(y,length(x2),length(x1));
    o = surf(x1,x2,y);
    alpha(o,0.3);

end

