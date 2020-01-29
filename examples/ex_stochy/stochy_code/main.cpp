/*
 * Stochy main file
 *
 *  Created on: 14 Jan 2020
 *      Author: M.Khaled
 */

#include "taskExec.h"
#include "time.h"
#include <iostream>
#include <nlopt.hpp>

int main(int argc, char **argv) {

	std::cout << " _______  _______  _______  _______  __   __  __   __ " << std::endl;
	std::cout << "|       ||       ||       ||       ||  | |  ||  | |  |" << std::endl;
	std::cout << "|  _____||_     _||   _   ||       ||  |_|  ||  |_|  |" << std::endl;
	std::cout << "| |_____   |   |  |  | |  ||       ||       ||       |" << std::endl;
	std::cout << "|_____  |  |   |  |  |_|  ||      _||       ||_     _|" << std::endl;
	std::cout << " _____| |  |   |  |       ||     |_ |   _   |  |   |  " << std::endl;
	std::cout << "|_______|  |___|  |_______||_______||__| |__|  |___| " << std::endl;
	std::cout << std::endl;
	std::cout << " Welcome!  Copyright (C) 2018  natchi92 " << std::endl;
	std::cout << std::endl;


	if (argc < 2) {
	std::cout << "No dimension was given" << std::endl;
	exit(-1);
	}

	int dim = strtol(argv[1], NULL, 0);
	std::cout << "Running verification with " << dim << " continuous variables." << std::endl;

	// Define the boundary for each dimesnion
	arma::mat bound(dim, 2);
	arma::mat grid(1, dim);
	arma::mat reft(1, dim);
	for (unsigned d = 0; d < dim; d++) {
		bound(d,0) = -1.0;
		bound(d,1) =  1.0;
		grid(0,d) = 1.0;
		reft(0,d) = 1.0;
	}
	
	std::cout << "bound.n_col = " << bound.n_cols << std::endl;

	// Define time horizon
	int T = 6;

	// Select task to perform
	taskSpec_t cs3Spec(imdp, T, synthesis_safety, bound, grid, reft);
	std::cout << "Completed creating a speciifcation object." << std::endl;

	// make a model
	arma::mat Am3 = 0.8 * arma::eye(dim, dim);
	arma::mat sigmam3 = 0.2 * arma::eye(dim, dim);
	ssmodels_t model03(Am3, sigmam3);
	std::cout << "Completed creating a sub-system from a continous-time model." << std::endl;

	// SHS
	std::vector<ssmodels_t> models4 = {model03};
	shs_t<arma::mat, int> cs3SHS(models4);
	std::cout << "Completed crating a SHS from 1 sub-model." << std::endl;

	// Problem to solve
	inputSpec_t<arma::mat, int> cs3Input(cs3SHS, cs3Spec);
	performTask(cs3Input);
	std::cout << "Completed synthesis task." << std::endl;
    
}
