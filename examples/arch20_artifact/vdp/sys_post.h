// some helper functions for the conditions to be checked inside the post-function
void f(float* xx, const float* x);
void f(float* xx, const float* x){
    float tau = 0.05;
    xx[0] = x[0] + tau*x[1];
    xx[1] = x[1] + tau*(-x[0] + (1-x[0]*x[0])*x[1]);
}
char is_in_A(const float* x);
char is_in_A(const float* x){
    if (x[0] >= -5.0 && x[0] <= 5.0 && x[1] >= -5.0 && x[1] <= 5.0 )
        return 1;
    else
        return 0;
}
char is_in_B(const float* x);
char is_in_B(const float* x){
    if (x[0] >= -1.2 && x[0] <= -0.9 && x[1] >= -2.9 && x[1] <= -2.0)
        return 1;
    else
        return 0;
}
char rand_Bernoulli();
char rand_Bernoulli(){
    unsigned int id = get_global_id(0) + get_global_id(1)*get_global_size(0);
    float r = ((float)(id%100))/100.0;
    float th = 0.8;
    if(r >= th)
        return 1;
    else
        return 0;
}
char is_cond_w(const float* x, const float* w, const float* x_post);
char is_cond_w(const float* x, const float* w, const float* x_post){
    if ((is_in_A(w) == 1 ) && !(w[0] == x_post[0] && w[1] == x_post[1])){
        return 1;
    }
    else{
        return 0;
    }
}



// The post function
void sys_post(float* xp, const float* x, const float* u, const float* w);
void sys_post(float* xp, const float* x, const float* u, const float* w){

    // compute post (works only on dim \in {0,1})
    f(xp, x);

    // 1:  a normal post
    if (is_cond_w(x,w,xp) == 1 && is_in_B(x) == 0){
        xp[2] = 0.0; 
        return;
    }

    // 2: \phi_1
    if (is_cond_w(x,w,xp) == 0 && is_in_B(x) == 0){
        xp[2] = 1.0; 
        return;
    }    

    // 3: normal post
    if (is_cond_w(x,w,xp) == 1 && is_in_B(x) == 1 && rand_Bernoulli() == 0){
        xp[2] = 0.0; 
        return;
    }        

    // 4: \phi_1
    if (is_cond_w(x,w,xp) == 0 && is_in_B(x) == 1 && rand_Bernoulli() == 0){
        xp[2] = 1.0; 
        return;
    }        

    // 5: \phi_2
    if (is_cond_w(x,w,xp) == 1 && is_in_B(x) == 1 && rand_Bernoulli() == 1){
        xp[2] = -1.0; 
        return;
    }        

    // 6: \phi_2
    if (is_cond_w(x,w,xp) == 0 && is_in_B(x) == 1 && rand_Bernoulli() == 1){
        xp[2] = -1.0; 
        return;
    }                    

    // in case all of the above fails
	xp[2] = 0.0; 
}