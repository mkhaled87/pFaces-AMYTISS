#include <pfaces-sdk.h>
#include <symbolicc++.h>

#include "amytissPDFs.h"

/* some global defines */
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace amytiss{

std::string to_string(NOISE_TYPE ntype) {
    switch (ntype) {
        case NOISE_TYPE::ADDITIVE: {
            return "additive";
        }
        case NOISE_TYPE::MULTIPLICATIVE: {
            return "multiplicative";
        }
        default:
            throw std::runtime_error("Invalid NOISE_TYPE.");
    }
}
NOISE_TYPE parse_noise_type(std::string strNtype) {
    if (strNtype == to_string(NOISE_TYPE::ADDITIVE))
        return NOISE_TYPE::ADDITIVE;
    if (strNtype == to_string(NOISE_TYPE::MULTIPLICATIVE))
        return NOISE_TYPE::MULTIPLICATIVE;
    throw std::runtime_error(std::string("Unidentified NOISE_TYPE: ") + strNtype);
}

std::string to_string(PDF_CLASS pclass) {
    switch (pclass) {
        case PDF_CLASS::NORMAL_DISTRIBUTION:{
            return "normal_distribution";
        }
        case PDF_CLASS::UNIFORM_DISTRIBUTION: {
            return "uniform_distribution";
        }
        case PDF_CLASS::EXPONENTIAL_DISTRIBUTION: {
            return "exponential_distribution";
        }
        case PDF_CLASS::BETA_DISTRIBUTION: {
            return "beta_distribution";
        }
        case PDF_CLASS::CUSTOM: {
            return "custom";
        }
        default:
            throw std::runtime_error("Invalid PDF_CLASS.");
    }
}
PDF_CLASS parse_pdf_class(std::string strPclass) {
    if (strPclass == to_string(PDF_CLASS::NORMAL_DISTRIBUTION))
        return PDF_CLASS::NORMAL_DISTRIBUTION;
    if (strPclass == to_string(PDF_CLASS::UNIFORM_DISTRIBUTION))
        return PDF_CLASS::UNIFORM_DISTRIBUTION;
    if (strPclass == to_string(PDF_CLASS::EXPONENTIAL_DISTRIBUTION))
        return PDF_CLASS::EXPONENTIAL_DISTRIBUTION;
    if (strPclass == to_string(PDF_CLASS::BETA_DISTRIBUTION))
        return PDF_CLASS::BETA_DISTRIBUTION;
    if (strPclass == to_string(PDF_CLASS::CUSTOM))
        return PDF_CLASS::CUSTOM;
    throw std::runtime_error(std::string("Unidentified PDF_CLASS: ") + strPclass);
}

std::string to_string(PDF_TRUNCATION tmode) {
    switch (tmode) {
        case PDF_TRUNCATION::NO_TRUNCATION:{
            return "no_truncation";
        }
        case PDF_TRUNCATION::FIXED_TRUNCATION: {
            return "fixed_truncation";
        }
        case PDF_TRUNCATION::CUTTING_PROBABILITY: {
            return "cutting_probability";
        }
        default:
            throw std::runtime_error("Invalid PDF_TRUNCATION.");
    }
}
PDF_TRUNCATION parse_pdf_truncation(std::string strTmode) {
    if (strTmode == to_string(PDF_TRUNCATION::NO_TRUNCATION))
        return PDF_TRUNCATION::NO_TRUNCATION;
    if (strTmode == to_string(PDF_TRUNCATION::FIXED_TRUNCATION))
        return PDF_TRUNCATION::FIXED_TRUNCATION;
    if (strTmode == to_string(PDF_TRUNCATION::CUTTING_PROBABILITY))
        return PDF_TRUNCATION::CUTTING_PROBABILITY;
    throw std::runtime_error(std::string("Unidentified PDF_TRUNCATION: ") + strTmode);
}

// class: amytissPDF
//---------------------------
#define AMYTISS_CONFIG_PARAM_noise_type	"noise.type"
#define AMYTISS_CONFIG_PARAM_noise_pdf_class	"noise.pdf_class"
#define AMYTISS_CONFIG_PARAM_noise_pdf_truncation	"noise.pdf_truncation"
std::shared_ptr<amytissPDF> amytissPDF::constructPDF(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb) {

    PDF_CLASS pdf_class = parse_pdf_class(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_pdf_class));

    if(pdf_class == PDF_CLASS::NORMAL_DISTRIBUTION)
        return std::make_shared<amytissPDF_NormalDistribution>(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb);

    if (pdf_class == PDF_CLASS::UNIFORM_DISTRIBUTION)
        return std::make_shared<amytissPDF_UniformDistribution>(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb);

    if (pdf_class == PDF_CLASS::EXPONENTIAL_DISTRIBUTION)
        return std::make_shared<amytissPDF_ExponentialDistribution>(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb);

    throw std::runtime_error("Invalid type of PDF.");
}
amytissPDF::amytissPDF(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg,
    size_t _ssDim, 
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb){
        
    spCfg = _spCfg;
    ssDim = _ssDim;
    ssEta = _ssEta;
    ssLb = _ssLb;
    ssUb = _ssUb;

    noise_type = parse_noise_type(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_type));
    pdf_class = parse_pdf_class(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_pdf_class));
    trunc_mode = parse_pdf_truncation(_spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_pdf_truncation));

    if (noise_type == NOISE_TYPE::MULTIPLICATIVE && trunc_mode != PDF_TRUNCATION::NO_TRUNCATION)
        throw std::runtime_error("For multiplicative noise, only 'no_truncation' is allowed for PDF truncation.");
}
amytissPDF::~amytissPDF(){}
NOISE_TYPE amytissPDF::getNoiseType() {
    return noise_type;
}
PDF_CLASS amytissPDF::getClass() {
    return pdf_class;
}
PDF_TRUNCATION amytissPDF::getTruncationMode(){
    return trunc_mode;
}


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
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb)
:amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb){   

    det_covar_matrix = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_det_covariance_matrix);
    cutting_probability = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_cutting_probability);
    std::string cutting_region = _spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_cutting_region);   


    // Fixed truncation ?
    if (cutting_region != std::string("") && cutting_probability == 0) {
        if (trunc_mode != PDF_TRUNCATION::FIXED_TRUNCATION) {
            trunc_mode = PDF_TRUNCATION::FIXED_TRUNCATION;
            pfacesTerminal::showInfoMessage(
                std::string("PDF truncation is set to fixed_truncation as you provided a specific cutting region: ") +
                cutting_region
            );
        }
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
        if (trunc_mode != PDF_TRUNCATION::CUTTING_PROBABILITY) {
            trunc_mode = PDF_TRUNCATION::CUTTING_PROBABILITY;
            pfacesTerminal::showInfoMessage(
                std::string("PDF truncation is set to cutting_probability as you provided a specific cutting probability level: ") +
                std::to_string(cutting_probability)
            );
        }
    } else {
        if (trunc_mode != PDF_TRUNCATION::NO_TRUNCATION) {
            trunc_mode = PDF_TRUNCATION::NO_TRUNCATION;
            pfacesTerminal::showInfoMessage("PDF truncation is set to no_truncation as you did provided any specific cutting probability level or cutting region.");
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

        pfacesTerminal::showMessage(std::string("Computing the probability distribution function (PDF) symbolically .... "), false);
        pfacesTimer timer;
        timer.tic();

		// required symbic vectors/matricies
		Symbolic x("x", (int)ssDim);
		Symbolic SigmaInv("SigmaInv", (int)ssDim, (int)ssDim);

		// e = -0.5*(x)'*inv(Sigma)*(x)
		Symbolic e = -0.5 * x.transpose() * SigmaInv * x;
		concrete_t val = (concrete_t)(1.0l / std::sqrt(std::pow(2.0l * M_PI, ssDim) * det_covar_matrix));

		// the pdf as a strings	
		std::stringstream ssE;
		ssE << "return " << val << "*exp((float)(" << e << "));";
		std::string strRet = ssE.str();

        double time = timer.toc().count();
        pfacesTerminal::showMessage(std::string("done ! [") + std::to_string(time) + std::string(" seconds]"));

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
        case PDF_TRUNCATION::NO_TRUNCATION:{
            cuttingBoundsLb = ssLb;
			cuttingBoundsUb = ssUb;        
            break;
        }

        case PDF_TRUNCATION::FIXED_TRUNCATION:{
            cuttingBoundsLb = fixed_cutting_region_lb;
			cuttingBoundsUb = fixed_cutting_region_ub;
            break;
        }

        case PDF_TRUNCATION::CUTTING_PROBABILITY:{
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



// class: amytissPDF_UniformDistribution
//---------------------------
#define AMYTISS_CONFIG_PARAM_noise_active_region	"noise.active_region"
#define OUT_FILE_PARAM_PDF_AMPLITUDE "pdf-amplitude"
amytissPDF_UniformDistribution::amytissPDF_UniformDistribution(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb)
    :amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb) {

    // check if an active region is provided
    std::string active_region = _spCfg->readConfigValueString(AMYTISS_CONFIG_PARAM_noise_cutting_region);
    if (active_region.empty() || active_region == std::string(""))
        throw std::runtime_error("For uniform distribution, you must provide an active_region in which the PDF is non-zero.");

    // parsing the active region
    active_region = pfacesUtils::strReplaceAll(active_region, "{", "");
    active_region = pfacesUtils::strReplaceAll(active_region, "}", "");
    std::vector<concrete_t> vals = pfacesUtils::sStr2Vector<concrete_t>(active_region);
    if (vals.size() != ssDim * 2)
        throw std::runtime_error("amytissPDF_UniformDistribution: Invalid number of elemenmts in the provided active region.");

    for (size_t i = 0; i < ssDim; i++) {
        active_region_lb.push_back(vals[2 * i + 0]);
        active_region_ub.push_back(vals[2 * i + 1]);

        if ((active_region_lb[i] > active_region_ub[i]) || (active_region_ub[i] != -1*active_region_lb[i]))
            throw std::runtime_error("amytissPDF_UniformDistribution: Invalid active region: it must be symmetric around the origin.");
    }

    // truncation mode is always fixed and will be set to the active region
    trunc_mode = PDF_TRUNCATION::FIXED_TRUNCATION;

    // computing the pdf amplitude
    concrete_t active_region_volume = 1;
    for (size_t i = 0; i < ssDim; i++){
        active_region_volume *= active_region_ub[i] - active_region_lb[i];
    }
    amplitude = 1.0/active_region_volume;
}

std::string
amytissPDF_UniformDistribution::getAdditionalDefines() {
    return "";
}

std::string
amytissPDF_UniformDistribution::getPDFBody() {

    // the pdf as a strings	
    std::stringstream ssE;
    ssE << "return " << amplitude << ";";
    std::string strRet = ssE.str();

    return strRet;
}

std::pair<std::vector<concrete_t>, std::vector<concrete_t>>
amytissPDF_UniformDistribution::getOriginatedCuttingBound() {
    return std::make_pair(active_region_lb, active_region_ub);
}

void amytissPDF_UniformDistribution::addToOutputFileMetadata(StringDataDictionary& metadata) {
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_PDF_AMPLITUDE,std::to_string(amplitude)));
}


// class: amytissPDF_ExponentialDistribution
//---------------------------
#define AMYTISS_CONFIG_PARAM_noise_decay_rate	"noise.decay_rate"
#define OUT_FILE_PARAM_DECAY_RATE "pdf-decay-rate"
amytissPDF_ExponentialDistribution::amytissPDF_ExponentialDistribution(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb)
    :amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb) {

    if(_ssDim > 1)
        throw std::runtime_error("amytissPDF_ExponentialDistribution: we only support Exponential distributions for one-dimensional systems.");

    // read the decay rate
    decay_rate = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_decay_rate);

    // truncation mode is always fixed and will be set to the active region
    trunc_mode = PDF_TRUNCATION::NO_TRUNCATION;
}

std::string
amytissPDF_ExponentialDistribution::getAdditionalDefines() {
    return "";
}

std::string
amytissPDF_ExponentialDistribution::getPDFBody() {

    // the pdf as a strings	
    std::stringstream ssE;
    ssE << "if(x[0] < 0.0f)" << std::endl;
    ssE << "return 0.0f;" << std::endl;
    ssE << "else" << std::endl;
    ssE << "return 1.0f - exp((float)(-1.0f*" << decay_rate << "*" << "x[0]));";
    std::string strRet = ssE.str();

    return strRet;
}

std::pair<std::vector<concrete_t>, std::vector<concrete_t>>
amytissPDF_ExponentialDistribution::getOriginatedCuttingBound() {
    std::vector<concrete_t> empty;
    return std::make_pair(empty, empty);
}

void amytissPDF_ExponentialDistribution::addToOutputFileMetadata(StringDataDictionary& metadata) {
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_DECAY_RATE, std::to_string(decay_rate)));
}

// class: amytissPDF_BetaDistribution
//---------------------------
#define AMYTISS_CONFIG_PARAM_noise_alpha "noise.alpha"
#define AMYTISS_CONFIG_PARAM_noise_beta "noise.beta"
#define OUT_FILE_PARAM_alpha "pdf-alpha"
#define OUT_FILE_PARAM_beta "pdf-beta"
amytissPDF_BetaDistribution::amytissPDF_BetaDistribution(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb)
    :amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb) {

    if (_ssDim > 1)
        throw std::runtime_error("amytissPDF_BetaDistribution: we only support Beta distributions for one-dimensional systems.");

    // read the decay rate
    alpha = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_alpha);
    beta = _spCfg->readConfigValueReal(AMYTISS_CONFIG_PARAM_noise_beta);

    // truncation mode is always fixed and will be set to the active region
    trunc_mode = PDF_TRUNCATION::NO_TRUNCATION;
}

std::string
amytissPDF_BetaDistribution::getAdditionalDefines() {

    std::stringstream ssE;

    ssE << "#define PDF_alpha " << alpha << std::endl;
    ssE << "#define PDF_beta " << beta << std::endl;
    ssE << "#define PDF_B(alpha, beta) ((tgamma((float)alpha)*tgamma((float)beta))/(tgamma((float)(alpha + beta))))" << std::endl;

    std::string strRet = ssE.str();
    return strRet;
}

std::string
amytissPDF_BetaDistribution::getPDFBody() {
    // the pdf as a strings	
    std::stringstream ssE;
    ssE << "if(x[0] < 0.0f)" << std::endl;
    ssE << "return 0.0f;" << std::endl;
    ssE << "else" << std::endl;
    ssE << "return ((pow((float)x[0],(float)(PDF_alpha-1.0f)))*(1-x[0])*(pow((float)x[0],(float)(PDF_beta-1.0f))))/(PDF_B(PDF_alpha, PDF_beta));";
    std::string strRet = ssE.str();
}

std::pair<std::vector<concrete_t>, std::vector<concrete_t>>
amytissPDF_BetaDistribution::getOriginatedCuttingBound() {
    std::vector<concrete_t> empty;
    return std::make_pair(empty, empty);
}

void amytissPDF_BetaDistribution::addToOutputFileMetadata(StringDataDictionary& metadata) {
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_alpha, std::to_string(alpha)));
    metadata.push_back(std::make_pair(OUT_FILE_PARAM_beta, std::to_string(beta)));
}


// class: amytissPDF_Custom
//---------------------------
amytissPDF_Custom::amytissPDF_Custom(
    const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb)
    :amytissPDF(_spCfg, _ssDim, _ssEta, _ssLb, _ssUb) {
    ssLb = _ssLb;
    ssUb = _ssUb;
    trunc_mode = PDF_TRUNCATION::NO_TRUNCATION;
}

std::string
amytissPDF_Custom::getAdditionalDefines() {
    return "#include \"custom_pdf.cl\"";
}

std::string
amytissPDF_Custom::getPDFBody() {
    return "return custom_pdf(x, Mu);";
}

std::pair<std::vector<concrete_t>, std::vector<concrete_t>>
amytissPDF_Custom::getOriginatedCuttingBound() {
    return std::make_pair(ssLb, ssUb);
}

void amytissPDF_Custom::addToOutputFileMetadata(StringDataDictionary& metadata) {
    (void)metadata;
}


}
