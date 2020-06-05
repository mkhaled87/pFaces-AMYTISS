#!/bin/bash

# get and show system size
n="$@"
echo "We will run the integrator example with n=" "$n"

# set device selection
dev="-CG -d 1"
echo "We will run pFaces using the following device config:" "$dev"

# config 
project_name="int$n"
overrides="\"project_name=$project_name\""

# run it
pfaces -cfg int$n.cfg -k amytiss.cpu@../../../kernel-pack -p -co "$overrides" $dev

