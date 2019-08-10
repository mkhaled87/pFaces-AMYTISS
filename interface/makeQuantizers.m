function [ss_quantizer, is_quantizer] = makeQuantizers(pfacesDataFile)

    ss_lb  = str2double(strsplit(pfacesDataFile.getMetadataElement('ss-lower-point'), ','));
    ss_ub  = str2double(strsplit(pfacesDataFile.getMetadataElement('ss-upper-point'), ','));
    ss_eta = str2double(strsplit(pfacesDataFile.getMetadataElement('ss-eta'), ','));
    ss_err = zeros(size(ss_lb));

    is_lb=str2double(strsplit(pfacesDataFile.getMetadataElement('is-lower-point'), ','));
    is_ub=str2double(strsplit(pfacesDataFile.getMetadataElement('is-upper-point'), ','));
    is_eta = str2double(strsplit(pfacesDataFile.getMetadataElement('is-eta'), ','));
    is_err = zeros(size(is_lb));

    cutting_region_lb=str2double(strsplit(pfacesDataFile.getMetadataElement('org-cutting-region-lb'), ','));
    cutting_region_ub=str2double(strsplit(pfacesDataFile.getMetadataElement('org-cutting-region-ub'), ','));
    
    ss_quantizer = NdQuantizer(ss_lb, ss_ub, ss_eta, ss_err);
    is_quantizer = NdQuantizer(is_lb, is_ub, is_eta, is_err);
    
    %checking the quantizers against stored information
    q_ss_steps = ss_quantizer.getPerDimensionSteps();
    q_is_steps = is_quantizer.getPerDimensionSteps();
    ss_steps = str2double(strsplit(pfacesDataFile.getMetadataElement('ss-steps'), ','));
    is_steps = str2double(strsplit(pfacesDataFile.getMetadataElement('is-steps'), ','));
    
    if(~all(ss_steps == q_ss_steps))
        error('The quantization steps computed in MATLAB is different from the ones stored in the file for SS.');
    end
    
    if(~all(is_steps == q_is_steps))
        error('The quantization steps computed in MATLAB is different from the ones stored in the file for IS.');
    end
end

