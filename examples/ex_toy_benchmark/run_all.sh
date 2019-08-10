#!/bin/bash

DEV=1

pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe.cfg -p;
pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_safe_ofa.cfg -p;
pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid.cfg -p;
pfaces -CGH -d $DEV -k amytiss.cpu@../../kernel-pack -cfg toy2d_reachavoid_ofa.cfg -p;
