function [covar] = readCovarianceMatrix(exampleDataFile)    
    ss_dim = str2double(exampleDataFile.getMetadataElement('ss-dimension'));
    inv_covar_str = exampleDataFile.getMetadataElement('inv-covariance-matrix');
    det_covar = str2double(exampleDataFile.getMetadataElement('det-covariance-matrix'));
    inv_var_elements = str2double(split(inv_covar_str,','));
    if ss_dim == length(inv_var_elements)
        inv_covar = diag(inv_var_elements);
        covar = inv(inv_covar);
    elseif ss_dim^2 == length(inv_var_elements)
        inv_covar = reshape(inv_var_elements, ss_dim, ss_dim);
        covar = inv(inv_covar);
    else
        error('covar matrix in file is invalid !');
    end
    
    err = abs(det_covar - det(covar));
    if err > 0.0001 
        warning(['There is an error of ' num2str(err) ' between the computed and supplied determinant of the covarianace matrix. Just double check !']);
    end
end

