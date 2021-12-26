#ifndef AMYTISS_PDFS
#define AMYTISS_PDFS

#include <iostream>
#include <string>
#include <vector>

namespace amytiss{

// the type of noise
enum class NOISE_TYPE {
    ADDITIVE,
    MULTIPLICATIVE
};
std::string to_string(NOISE_TYPE ntype);
NOISE_TYPE parse_noise_type(std::string strNtype);

// the class of PDF
enum class PDF_CLASS {
    NORMAL_DISTRIBUTION,
    UNIFORM_DISTRIBUTION,
    EXPONENTIAL_DISTRIBUTION,
    BETA_DISTRIBUTION,
    CUSTOM
};
std::string to_string(PDF_CLASS pclass);
PDF_CLASS parse_pdf_class(std::string strPclass);

// the truncation mode requesteed from the PDF object will be long to one of the    
// following types
enum class PDF_TRUNCATION {
    NO_TRUNCATION,
    FIXED_TRUNCATION,
    CUTTING_PROBABILITY
};
std::string to_string(PDF_TRUNCATION tmode);
PDF_TRUNCATION parse_pdf_truncation(std::string strTmode);

// an abstract class to represent a unified interface for the structure of PDFs to be 
// implemented in AMYTISS.
class amytissPDF{
public:
    /* this function creates dynamically a PDF of different classes based on the provided config */
    static std::shared_ptr<amytissPDF> constructPDF(
        const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb
        );

protected:
    std::shared_ptr<pfacesConfigurationReader> spCfg;

    size_t ssDim;
    std::vector<concrete_t> ssEta, ssLb, ssUb;

    NOISE_TYPE noise_type;
    PDF_CLASS pdf_class;
    PDF_TRUNCATION trunc_mode;

public:
    // to save the config locally for future use
    amytissPDF(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim, 
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb
    );
    virtual ~amytissPDF()=0;
    NOISE_TYPE getNoiseType();
    PDF_CLASS getClass();
    PDF_TRUNCATION getTruncationMode();

    // will be called to ask the concrete class to declare any additional defies required
    // for computing by the symbolic PDF in the CL code
    virtual 
    std::string getAdditionalDefines() = 0;

    // the PDF's as function to be injected in the CL code
    // the PDF developer should assume the following prototype:
    // concrete_t pdf(const concrete_t* x, const concrete_t* Mu);
    // where x is the state vector and Mu is the mean vecrtor
    virtual 
    std::string getPDFBody() = 0;

    // a function that will respond to the requested PDF_TRUNCATION_MODE and provide lower/upper
    // bounds for the cutting region assuming a zero-centered PDF.
    virtual 
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound() = 0;


    // this function will be called before the saving of the output file
    // the PDF object can use this to save additional date in the output
    // file to be used by the Matlab interface
    virtual
    void addToOutputFileMetadata(StringDataDictionary& metadata) = 0;


    // a function to align points to quantization levels
    // LB is the base here and eta is used to jump to quantization levels.
    // UB is a guide and should not exceed and error of (quantization_allowed_preccision) from the closest level!
    static
    concrete_t alignValueToQuantizationGrid(
        const concrete_t value, const concrete_t eta, 
        const concrete_t lb, const concrete_t ub) {

        // checking the quantization domain/levels
        if(lb>ub)
            throw std::runtime_error("alignValueToQuantizationGrid: The lb is greater than the ub !");

        const concrete_t quantization_allowed_preccision = 0.0000001f;

        concrete_t domain_length = std::abs(ub - lb);

        if (quantization_allowed_preccision > domain_length)
            throw std::runtime_error("alignValueToQuantizationGrid: The quantization space is bigger than the precision error !");

        if(eta > domain_length)
            throw std::runtime_error("alignValueToQuantizationGrid: Eta is greater than (ub-lb) !");

        symbolic_t domain_slots_count = (symbolic_t)std::round(domain_length / eta);
        concrete_t expected_ub = lb + ((concrete_t)domain_slots_count)*eta;

        if (std::abs(expected_ub - ub) > quantization_allowed_preccision)
            throw std::runtime_error("alignValueToQuantizationGrid: The quantization parametes are not consistent since (lb+round((ub-lb)/eta)*eta) not delta-close to (lb) !");

        // aligning the value
        if (value >= ub)
            return expected_ub;

        if (value <= lb)
            return lb;

        concrete_t distance = std::abs(value-lb);
        symbolic_t num_slots = (symbolic_t)std::round(distance / eta);
        concrete_t new_distance = lb + num_slots*eta;

        return new_distance;
    }

};

// PDF:: Normal Distribution
// ------------------------------
class amytissPDF_NormalDistribution : public amytissPDF {
    
    std::vector<std::vector<concrete_t>> inv_covar_matrix;
    concrete_t det_covar_matrix;
    concrete_t cutting_probability;

    std::vector<concrete_t> fixed_cutting_region_lb;
    std::vector<concrete_t> fixed_cutting_region_ub;

    // some private functions
    std::vector<concrete_t> getRHSCuttingPoint();

public:
    amytissPDF_NormalDistribution(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim, 
    const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound();
    void addToOutputFileMetadata(StringDataDictionary& metadata);
};


// PDF:: Uniform Distribution
// ------------------------------
class amytissPDF_UniformDistribution : public amytissPDF {

    concrete_t amplitude;

    std::vector<concrete_t> active_region_lb;
    std::vector<concrete_t> active_region_ub;


public:
    amytissPDF_UniformDistribution(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound();
    void addToOutputFileMetadata(StringDataDictionary& metadata);
};

// PDF:: Exponential Distribution
// ------------------------------
class amytissPDF_ExponentialDistribution : public amytissPDF {
    concrete_t decay_rate;

public:
    amytissPDF_ExponentialDistribution(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound();
    void addToOutputFileMetadata(StringDataDictionary& metadata);
};

// class: amytissPDF_BetaDistribution
//---------------------------
class amytissPDF_BetaDistribution : public amytissPDF {
    concrete_t alpha;
    concrete_t beta;
public:
    amytissPDF_BetaDistribution(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound();
    void addToOutputFileMetadata(StringDataDictionary& metadata);
};


// PDF:: Custom
// ------------------------------
class amytissPDF_Custom : public amytissPDF {
    std::vector<concrete_t> ssLb;
    std::vector<concrete_t> ssUb;
public:
    amytissPDF_Custom(const std::shared_ptr<pfacesConfigurationReader> _spCfg, size_t _ssDim,
        const std::vector<concrete_t>& _ssEta, const std::vector<concrete_t>& _ssLb, const std::vector<concrete_t>& _ssUb);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound();
    void addToOutputFileMetadata(StringDataDictionary& metadata);
};

}

#endif