function exportPrismMDP(inputFilePath, outFilePath)
    tic
    amytissDataFile = DataFile(inputFilePath, true, true);
    [ss_quantizer, is_quantizer] = makeQuantizers(amytissDataFile);
    org_cut_region_lb = str2double(split(amytissDataFile.getMetadataElement('org-cutting-region-lb'),','))';
    org_cut_region_ub = str2double(split(amytissDataFile.getMetadataElement('org-cutting-region-ub'),','))';
    ss_eta = str2double(split(amytissDataFile.getMetadataElement('ss-eta'),','))';    
    num_reach_states = str2double(amytissDataFile.getMetadataElement('num-reach-states'));
    

    num_states = ss_quantizer.getNumSymbols();
    num_inputs = is_quantizer.getNumSymbols();

    outFile = fopen(outFilePath,'w');
    
    fprintf(outFile, '//Transition probabilities\n\n');
    fprintf(outFile, 'mdp\n\n');
    fprintf(outFile, 'module M1\n\n');

    fprintf(outFile, '//Definition of the states\n');
    fprintf(outFile, 's : [0..%d]\n\n', num_states);

    fprintf('Generating ... [%%]: 0..');
    last_prog_perc = 0;
    one_pdf_loaded = false;
    reference_pdf = zeros(1,num_reach_states);
    for u_flat = 0 : num_inputs-1
        for x_flat = 0 : num_states-1
            
            xu_ejected = false;
            
            if ~one_pdf_loaded
                xubag = amytissXUBag(amytissDataFile, x_flat, u_flat);
            end
            x_sym = ss_quantizer.unflatten(x_flat);
            u_sym = is_quantizer.unflatten(u_flat);
            x_conc = ss_quantizer.desymbolize(x_sym);
            u_conc = is_quantizer.desymbolize(u_sym);   
            
            % mu and cutting region
            mu = sys_post(x_conc, u_conc);
            try
                mu_aligned = ss_quantizer.align(mu)';
            catch
                continue;
            end
            cut_region_lb = org_cut_region_lb+mu_aligned;
            cut_region_ub = org_cut_region_ub+mu_aligned;
            cut_region_quantizer = NdQuantizer(cut_region_lb, cut_region_ub, ss_eta, zeros(size(ss_eta)));            
                         
            %for all states in the cutting region
            one_line = [];
            for xp_flat = 0:num_reach_states-1
                if ~one_pdf_loaded
                    if xubag.is_safe_or_reach
                        p = xubag.getPmin(xp_flat);
                    else
                        p = xubag.getP1min(xp_flat);
                    end
                    reference_pdf(xp_flat+1) = p;
                else
                    p = reference_pdf(xp_flat+1);
                end
                
                xp_sym = cut_region_quantizer.unflatten(xp_flat);
                xp_conc = cut_region_quantizer.desymbolize(xp_sym);
                try
                    xp_flat_in_globe = ss_quantizer.flatten(ss_quantizer.symbolize(xp_conc));
                catch
                    continue;
                end
                
                
                if ~xu_ejected
                    xu_ejected = true;
                    one_line = [one_line '[a' num2str(u_flat) '] s = ' num2str(x_flat) ' -> '];
                end                
                one_line = [one_line num2str(p) ' : (s'' = '  num2str(xp_flat_in_globe) ')' ];
                
                % last one ?
                if xp_flat ~= (num_reach_states-1)
                    one_line = [one_line ' + '];
                end
            end
            fprintf(outFile,'%s;\n', one_line);
            one_pdf_loaded = true;
        end
        prog_perc = (u_flat/num_inputs)*100;
        rounded_pro_perc = floor(prog_perc/5)*5;
        if rounded_pro_perc > last_prog_perc
            fprintf('%d..',rounded_pro_perc);
            last_prog_perc = rounded_pro_perc;
        end
    end	

    fprintf(outFile,'\nendmodule\n\n');
    fclose(outFile);
    fprintf('100\n');
    wall_time = toc;
    fprintf('Time to save: %d sec.\n',wall_time);
end

