#ifndef AMYTISS_PDFS
#define AMYTISS_PDFS

#include <iostream>
#include <string>
#include <vector>

#include "amytiss.h"

// the truncation mode requesteed from the PDF object will be long to one of the 
// following types
enum class PDF_TRUNCATION_MODE{
    NO_TRUNCATION,
    FIXED_TRUNCATION,
    CUTTING_PROBABILITY
};

// an abstract class to represent a unified interface for the structure of PDFs to be 
// implemented in AMYTISS.
class amytissAbstractPDF{
protected:
    std::shared_ptr<pfacesConfigurationReader> spCfg;

    size_t ssDim;
    std::vector<concrete_t> ssEta, ssLb, ssUb;
public:
    // to save the config locally for future use
    amytissAbstractPDF(std::shared_ptr<pfacesConfigurationReader>& _spCfg);

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
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound(PDF_TRUNCATION_MODE trunc_mode) = 0;

};


// PDF:: Normal Distribution
// ------------------------------
class amytissPDF_NormalDistribution : public amytissAbstractPDF {
    
    std::vector<std::vector<concrete_t>> inv_covar_matrix;
    concrete_t det_covar_matrix;
    concrete_t cutting_probability;

    bool fixed_cutting_Region_provied = false;
    std::vector<concrete_t> fixed_cutting_region_lb;
    std::vector<concrete_t> fixed_cutting_region_ub;

    // some private functions
    std::vector<concrete_t> amytissGetPositiveZeroOriginatedCuttingBounds();

public:
    amytissPDF_NormalDistribution(std::shared_ptr<pfacesConfigurationReader>& _spCfg);

    std::string getAdditionalDefines();
    std::string getPDFBody();
    std::pair<std::vector<concrete_t>, std::vector<concrete_t>> getOriginatedCuttingBound(PDF_TRUNCATION_MODE trunc_mode);
};


#endif