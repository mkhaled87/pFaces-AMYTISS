#!/bin/bash

DEV=1

pfaces -CG -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe.cfg -p;
pfaces -CG -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe_ofa.cfg -p;
pfaces -CG -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid.cfg -p;
pfaces -CG -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid_ofa.cfg -p;
