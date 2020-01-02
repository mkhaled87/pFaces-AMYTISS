#include "amytissPDFs.h"
#include <symbolicc++.h>

// class: amytissAbstractPDF
//---------------------------
amytissAbstractPDF::amytissAbstractPDF(std::shared_ptr<pfacesConfigurationReader>& _spCfg){
    spCfg = _spCfg;

    ssDim = (size_t)_spCfg->readConfigValueInt(AMYTISS_CONFIG_PARAM_states_dim);
    ssEta = pfacesUtils::sStr2Vector<concrete_t>(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_eta));
    ssLb = pfacesUtils::sStr2Vector<concrete_t>(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_lb));
    ssUb = pfacesUtils::sStr2Vector<concrete_t>(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_states_ub));         
}


// class: amytissPDF_NormalDistribution
//---------------------------
amytissPDF_NormalDistribution::amytissPDF_NormalDistribution(std::shared_ptr<pfacesConfigurationReader>& _spCfg)
:amytissAbstractPDF(_spCfg){   

    det_covar_matrix = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_det_covariance_matrix);
    cutting_probability = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_cutting_probability);
    std::string cutting_region = _spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_cutting_region);   

    if (cutting_region != std::string("") && cutting_probability == 0) {
        fixed_cutting_Region_provied = true;
        cutting_region = pfacesUtils::strReplaceAll(cutting_region, "{", "");
        cutting_region = pfacesUtils::strReplaceAll(cutting_region, "}", "");

        std::vector<concrete_t> vals = pfacesUtils::sStr2Vector<concrete_t>(cutting_region);
        if (vals.size() != ssDim * 2)
            throw std::runtime_error("amytissPDF_NormalDistribution: Invalid number of elemenmts in the provided fixed cuttinging region.");

        for (size_t i = 0; i < ssDim; i++){
            fixed_cutting_region_lb.push_back(vals[2 * i + 0]);
            fixed_cutting_region_ub.push_back(vals[2 * i + 1]);
        }
    }    

    std::vector<concrete_t> tmp_covar_line = 
        pfacesUtils::sStr2Vector<concrete_t>(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_inv_covariance_matrix));

    if (tmp_covar_line.size() != ssDim * ssDim && tmp_covar_line.size() != ssDim)
        throw std::runtime_error("amytissPDF_NormalDistribution:: The provided inv-covariance-matrix has invalid size !");

    if (tmp_covar_line.size() == ssDim * ssDim) {
        for (size_t i = 0; i < ssDim; i++) {
            std::vector<concrete_t> row;
            for (size_t j = 0; j < ssDim; j++) {
                row.push_back(tmp_covar_line[i * ssDim + j]);
            }
            inv_covar_matrix.push_back(row);
        }
    }

    if (tmp_covar_line.size() == ssDim) {
        for (size_t i = 0; i < ssDim; i++) {
            std::vector<concrete_t> row;
            for (size_t j = 0; j < ssDim; j++) {
                if(i == j)
                    row.push_back(tmp_covar_line[i]);
                else
                    row.push_back(0.0);
            }
            inv_covar_matrix.push_back(row);
        }
    }    
}

std::string 
amytissPDF_NormalDistribution::getAdditionalDefines(){
    std::stringstream ssE;

    // representing the inv-sigma mateix a a set of defines
    for (size_t i = 0; i < ssDim; i++)
        for (size_t j = 0; j < ssDim; j++)
            ssE << "#define SigmaInv_" << i << "_" << j << " " << std::fixed << inv_covar_matrix[i][j] << std::endl;

    // a general rule to make inv-sigma as a function
    ssE << "#define SigmaInv(I,J) SigmaInv_##I##_##J" << std::endl;

    std::string strRet = ssE.str();
    return strRet;    
}

std::string 
amytissPDF_NormalDistribution::getPDFBody(){
		// required symbic vectors/matricies
		Symbolic x("x", ssDim);
		Symbolic Mu("Mu", ssDim);
		Symbolic SigmaInv("SigmaInv", ssDim, ssDim);

		// e = -0.5*(x-Mu)'*inv(Sigma)*(x-Mu)
		Symbolic xMinusMu = x - Mu;
		Symbolic e = -0.5 * xMinusMu.transpose() * SigmaInv * xMinusMu;
		concrete_t val = 1.0l / std::sqrt(std::pow(2.0l * M_PI, ssDim) * det_covar_matrix);

		// the pdf as a strings	
		std::stringstream ssE;
		ssE << val << "*exp((float)(" << e << "));";
		std::string strRet = ssE.str();

		return strRet;
}


/* since we are dealing with symmetrix normal distribution, we can give the cutting bound as the distance from the origin */
std::vector<concrete_t> 
amytissPDF_NormalDistribution::amytissGetPositiveZeroOriginatedCuttingBounds() {

    std::vector<concrete_t> ret;

    if(cutting_probability == 0){
        for (size_t i = 0; i < ssDim; i++)
            ret.push_back(ssUb[i]);

        return ret;
    }

    concrete_t val = 1.0l / std::sqrt(std::pow(2.0l * M_PI, ssDim) * det_covar_matrix);
    concrete_t logVal = (-2 * std::log(cutting_probability / val));

    if (logVal < 0.0)
        throw std::runtime_error("amytissGetPositiveZeroOriginatedCuttingBounds: Invalid value for the cutting-probability. Are you setting a cutting prbability above the PDF max value ?");

    for (size_t i = 0; i < ssDim; i++) {
        concrete_t val = std::sqrt(logVal / inv_covar_matrix[i][i]);
        concrete_t valAligned = pfacesFlatSpace::alignValueToQuantizationGrid(val, ssEta[i], ssLb[i], ssUb[i]);

        ret.push_back(valAligned);	
    }

    return ret;
}


std::pair<std::vector<concrete_t>, std::vector<concrete_t>> 
amytissPDF_NormalDistribution::getOriginatedCuttingBound(PDF_TRUNCATION_MODE trunc_mode){
    	
    std::vector<concrete_t> cuttingBoundsLb, cuttingBoundsUb;


    switch(trunc_mode){
        case PDF_TRUNCATION_MODE::NO_TRUNCATION:{
            cuttingBoundsLb = ssLb;
			cuttingBoundsUb = ssUb;        
            break;
        }

        case PDF_TRUNCATION_MODE::FIXED_TRUNCATION:{
            cuttingBoundsLb = fixed_cutting_region_lb;
			cuttingBoundsUb = fixed_cutting_region_ub;
            break;
        }

        case PDF_TRUNCATION_MODE::CUTTING_PROBABILITY:{
            // get the originated (centered at 0) cutting bound that does not consider the effect of W on the dynamics
            std::vector<concrete_t> positiveCuttingBounds = 
                amytissGetPositiveZeroOriginatedCuttingBounds();

            // assing the bounds including inflation from the disturbances
            for (size_t i = 0; i < positiveCuttingBounds.size(); i++) {
                concrete_t valAlignedUb = pfacesFlatSpace::alignValueToQuantizationGrid(
                    positiveCuttingBounds[i], ssEta[i], ssLb[i], ssUb[i]);

                concrete_t valAlignedLb = pfacesFlatSpace::alignValueToQuantizationGrid(
                    -1*positiveCuttingBounds[i], ssEta[i], ssLb[i], ssUb[i]);

                cuttingBoundsLb.push_back(valAlignedLb);
                cuttingBoundsUb.push_back(valAlignedUb);
            }        
            break;
        }

        default:
            throw std::runtime_error("amytissPDF_NormalDistribution::getOriginatedCuttingBound: Invalid/Unsupported PDF_TRUNCATION_MODE.");            
    }

    return std::make_pair(cuttingBoundsLb, cuttingBoundsUb);
}