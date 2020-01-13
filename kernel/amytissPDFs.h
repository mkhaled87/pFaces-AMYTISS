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
    std::vector<concrete_t> amytissGetPositiveZeroOriginatedCuttingBounds();

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