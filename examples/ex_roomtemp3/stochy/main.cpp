/*
 * Stochy example for the system: 
 *
 *  Created on: 18 Jan 2020
 *      Author: M. Khaled
 */

#include "taskExec.h"
#include "time.h"
#include <iostream>
#include <nlopt.hpp>

int main(int argc, char **argv) {

  // To specify model manually 
  arma::mat Aq0 = {{0.64, 0.0, 0.36},{0.36, 0.14, 0.0},{0.0, 0.36, 0.64}};
  arma::mat Gq0 = {{1.0, 0.0, 0.0},{0.0, 1.0, 0.0},{0.0, 0.0, 1.0}};
  ssmodels_t model(Aq0,Gq0);
  arma::mat Bq0 = {{6.0, 0.0}, {0.0, 0.0}, {0.0, 8.0}};
  model.B = Bq0;
  std::vector<ssmodels_t> models = {model};
  shs_t<arma::mat,int> cs1SHS(models);
  
  // Specify verification task
  // Starting with FAUST^2 
  std::cout << " Formal verification via FAUST^2" << std::endl;
  std::cout << std::endl;
  
  // Define max error for 576 states
  double eps =2.5;

  // Define safe/target set
  arma::mat Safe = {{0.0, 8.0}, {0.0, 8.0}, {0.0, 8.0}};
  arma::mat Target = {{0.0, 8.0}, {0.0, 8.0}, {0.0, 8.0}};

  // Define input set
  arma::mat Input = {{0.0, 1.1}, {0.0, 1.1}};

  // Define grid type
  // (1 = uniform, 2 = adaptive (global lipschitz), 3 = adaptive (local lipschitz))
  // For comparison with IMDP we use uniform grid
  int gridType = 1;

  // Assumptions on Kernel (Approximate (monte)  or Exact(integrals))
  // Kernel = 2 ; (monte);
  // Kernel = 1;  ( integral);
  int AssumptionKernel = 2;

  // Time horizon
  int K = 16;

  // Library (1 = simulator, 2 = faust^2, 3 = imdp)
  int lb = 2;

  // Property type
  // (1 = verify safety, 2= verify reach-avoid, 3 = safety synthesis, 4 = reach-avoid synthesis)
  int p = 1;
      
  // Task specification
  //  taskSpec_t cs1SpecFAUST(lb, K, p, Safe,Input, eps, gridType, 1);
  taskSpec_t cs1SpecFAUST(lb, K, p, Safe,Target,Input, eps, gridType);
  cs1SpecFAUST.assumptionsKernel = AssumptionKernel;

  // Combine model and associated task
  inputSpec_t<arma::mat, int> cs1InputFAUST(cs1SHS, cs1SpecFAUST);

  // Perform  Task
  performTask(cs1InputFAUST);
  std::cout << " Done!"   << std::endl;
 
}