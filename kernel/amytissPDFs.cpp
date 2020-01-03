#include <pfaces-sdk.h>
#include <symbolicc++.h>

#include "amytissPDFs.h"

/* some global defines */
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace amytiss{

// class: amytissPDF
//---------------------------
amytissPDF::amytissPDF(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg,
    size_t _ssDim, 
    const std::vector<concrete_t> _ssEta, const std::vector<concrete_t> _ssLb, const std::vector<concrete_t> _ssUb){
        
    spCfg = _spCfg;
    ssDim = _ssDim;
    ssEta = _ssEta;
    ssLb = _ssLb;
    ssUb = _ssUb;

    trunc_mode = PDF_TRUNCATION_MODE::NO_TRUNCATION;         
}
amytissPDF::~amytissPDF(){}


// class: amytissPDF_NormalDistribution
//---------------------------
#define AMYTISS_CONFIG_PARAM_noise_inv_covariance_matrix	"noise.inv_covariance_matrix"
#define AMYTISS_CONFIG_PARAM_noise_det_covariance_matrix	"noise.det_covariance_matrix"
#define AMYTISS_CONFIG_PARAM_noise_cutting_probability	"noise.cutting_probability"
#define AMYTISS_CONFIG_PARAM_noise_cutting_region	"noise.cutting_region"
#define OUT_FILE_PARAM_INV_COVAR_MATRIX "inv-covariance-matrix"
#define OUT_FILE_PARAM_DET_COVAR_MATRIX "det-covariance-matrix"
#define OUT_FILE_PARAM_CUTTING_PROP "cutting-probability"

amytissPDF_NormalDistribution::amytissPDF_NormalDistribution(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim, 
    const std::vector<concrete_t> _ssEta, const std::vector<concrete_t> _ssLb, const std::vector<concrete_t> _ssUb)
:amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb){   

    det_covar_matrix = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_det_covariance_matrix);
    cutting_probability = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_cutting_probability);
    std::string cutting_region = _spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_cutting_region);   


    // Fixed truncation ?
    if (cutting_region != std::string("") && cutting_probability == 0) {
        trunc_mode =  PDF_TRUNCATION_MODE::FIXED_TRUNCATION;
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

    // cutting probability based or no truncation ?
    if (cutting_region == std::string("") && cutting_probability != 0){
        trunc_mode = PDF_TRUNCATION_MODE::CUTTING_PROBABILITY;
    } else {
        trunc_mode = PDF_TRUNCATION_MODE::NO_TRUNCATION;
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

        pfacesTerminal::showMessage(std::string("Computing the probability distribution function (PDF) symbolically .... "));

		// required symbic vectors/matricies
		Symbolic x("x", (int)ssDim);
		Symbolic Mu("Mu", (int)ssDim);
		Symbolic SigmaInv("SigmaInv", (int)ssDim, (int)ssDim);

		// e = -0.5*(x-Mu)'*inv(Sigma)*(x-Mu)
		Symbolic xMinusMu = x - Mu;
		Symbolic e = -0.5 * xMinusMu.transpose() * SigmaInv * xMinusMu;
		concrete_t val = (concrete_t)(1.0l / std::sqrt(std::pow(2.0l * M_PI, ssDim) * det_covar_matrix));

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

    concrete_t val = (concrete_t)(1.0l / std::sqrt(std::pow(2.0l * M_PI, ssDim) * det_covar_matrix));
    concrete_t logVal = (concrete_t)(-2 * std::log(cutting_probability / val));

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
amytissPDF_NormalDistribution::getOriginatedCuttingBound(){
    	
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

void amytissPDF_NormalDistribution::addToOutputFileMetadata(StringDataDictionary& metadata){

    metadata.push_back(std::make_pair(OUT_FILE_PARAM_INV_COVAR_MATRIX,
        spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_inv_covariance_matrix)));
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_DET_COVAR_MATRIX,
        spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_det_covariance_matrix)));		
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_CUTTING_PROP,
        spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_cutting_probability)));
}

}
