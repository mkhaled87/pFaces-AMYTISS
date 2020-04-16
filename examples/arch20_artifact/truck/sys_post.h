// The post function
void sys_post(float* xp, const float* x, const float* u);
void sys_post(float* xp, const float* x, const float* u){

    // decide a good solving step for this syste based on Ts
    // this is to be chosen imperically for each system and we use
    // matlab's ODE45 solver as a reference for error
	float Tau = 0.100f;
    int divider = 200;
	
	// Truck Params
    float L   = 1.5;      // Wheel base of the truck (from rear axle to front axle)
    float d1  = 4.5;      // distance between rear axle of the trailer and the rear axle of the truck
	
	// the rhs
	float f[4];
    
    // now we have new smaller Ts
    float Ts = Tau/((float)divider);
	
	// init xp
	for (int i=0; i<4; i++){
		xp[i] = x[i];
	}
	
	// solve
    for (int k=0; k <divider; k++){
        
		// the dynamics model
        f[0] = u[0]*cos(x[2]);
        f[1] = u[0]*sin(x[2]);
        f[2] = (u[0]/L)*tan(u[1]);
        f[3] = (u[0]/d1)*sin(x[3]-x[2]);        
		
        // post state for the given Ts
		for (int i=0; i<4; i++){
			xp[i] = xp[i] + Ts*f[i];
		}
    }
}