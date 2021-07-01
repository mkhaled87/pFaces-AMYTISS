#ifndef M_PI
#define M_PI 3.1415926f
#endif

// some maps : see the file ./InMap_Ident/Details.pdf for more details
inline float map_steering(const float angle_in){
    float p1 = -0.1167;
    float p2 = 0.01949;
    float p3 = 0.3828;
    float p4 = -0.0293;
    float x = angle_in;
    return p1*x*x*x + p2*x*x + p3*x + p4;
}
inline float map_speed(const int speed_in){
	switch(speed_in) {
		case  6: return  0.70f;
		case  5: return  0.65f;
		case  4: return  0.60f;
		case  3: return  0.55f;
		case  2: return  0.50f;
		case  1: return  0.45f;
		case  0: return  0.00f;
		case -1: return -0.45f;
		case -2: return -0.50f;
		case -3: return -0.55f;
		case -4: return -0.60f;
		case -5: return -0.65f;
		case -6: return -0.70f;
	}
	return 0.0f;
}
inline void get_v_params(float u_speed, float* a, float* b){
	float K,T;
    if (u_speed == 0.0f){
        K = 0.0f; 
		T = 0.25f;
	}
	else if (u_speed == 0.45f){
        K = 1.9953f; 
		T = 0.9933f;
    }
	else if (u_speed == 0.50f){
        K = 2.3567f;
		T = 0.8943f;
    }
	else if (u_speed == 0.55f){
        K = 3.0797f; 
		T = 0.88976f;
    }
	else if (u_speed == 0.60f){
        K = 3.2019f; 
		T = 0.87595f;
    }
	else if (u_speed == 0.65f){
        K = 3.3276f; 
		T = 0.89594f;
    }
	else if (u_speed == 0.70f){
        K = 3.7645f; 
		T = 0.92501f;
    }
	else if (u_speed == -0.45f){
        K = 1.8229f; 
		T = 1.8431f;
    }
	else if (u_speed == -0.50f){
        K = 2.3833f; 
		T = 1.2721f;
    }
	else if (u_speed == -0.55f){
        K = 2.512f; 
		T = 1.1403f;
    }
	else if (u_speed == -0.60f){
        K = 3.0956f; 
		T = 1.1278f;
    }
	else if (u_speed == -0.65f){
        K = 3.55f; 
		T = 1.1226f;
    }
	else if (u_speed == -0.70f){
        K = 3.6423f; 
		T = 1.1539f;
	}
    else{
        printf("get_v_params: Invalid input !\n");
		K = 0.0f;
		T = 0.0f;
	}
    *a = -1.0f/T;
    *b = K/T;
}

// post state
void sys_post(float* xp, const float* x, const float* u);
void sys_post(float* xp, const float* x, const float* u) {
	
	float u_steer = map_steering(u[0]);
	float u_speed = map_speed(u[1]);
	float L = 0.165f;
	float a,b;
	float Ts = 0.500f;
	int divider = 10;
	float f[4];
	get_v_params(u_speed, &a, &b);

	// Let's have new smaller Ts
    Ts = Ts/((float)divider);

	// init xp
	for (int i=0; i<4; i++){
		xp[i] = x[i];
	}

	// solve
    for (int k=0; k <divider; k++){
        
		f[0] = x[3]*cos(x[2]);
		f[1] = x[3]*sin(x[2]);
		f[2] = (x[3]/L)*tan(u_steer);
		f[3] = a*x[3] + b*u_speed;	
		
        // post state for the given Ts
		for (int i=0; i<4; i++){
			xp[i] = xp[i] + Ts*f[i];
		}
    }
}
