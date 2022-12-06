#!/bin/sh

# Testing example: ex_toy_reach
cd examples/ex_toy_reach
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..

# Testing example: ex_toy_safety
cd examples/ex_toy_safety
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..

# Testing example: ex_toy_reachavoid
cd examples/ex_toy_reachavoid
pfaces -CG -k amytiss.cpu@../../kernel-pack -cfg ./toy2d.cfg -d 1 -p
cd ../..
