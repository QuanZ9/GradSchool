#include <iostream>
#include <stdlib.h>
#include <sys/time.h>
#include <math.h>
#include <omp.h>
#include <stdio.h>

using namespace std;

int main(){
    // calculate runtime
    struct timeval start;
    struct timeval end;
    double runtime = 0;
    gettimeofday(&start, NULL);

    // set parameters
    int nParticle = 1000;
    int steps = 5000;
    double timeStep = 0.0001;
    int a = 1;
    double phi = 0.1;
    double L = pow(1.0/3 * 3.14 * a*a*a * nParticle / phi, 1.0/3);
    double krepul = 100;
    double M = 1;

    // initialize arrays
    double* pos = new double[nParticle*3];
    double* forces = new double[nParticle*3];
    fill(forces, forces+nParticle, 0);
    unsigned int seed = 1234;
    
    omp_set_num_threads(16);
    double* ri;
    double* rj;
    double dx, dy, dz;
    double s, s2;
    double y;
    double f;
    #pragma omp parallel
    {
        // set initial positions for particals
        #pragma omp for
        for (int i = 0; i < nParticle; ++i){
            pos[i*3] = 1.0 * rand_r(&seed) / RAND_MAX;
            pos[i*3+1] = 1.0 * rand_r(&seed) / RAND_MAX;
            pos[i*3+2] = 1.0 * rand_r(&seed) / RAND_MAX;
        }
    }
        // during each step, partical positions change
        for (int k = 0; k < steps; ++k){
            if (k% 500 == 0){
                cout << k << endl;
            }
            #pragma omp parallel for
            for (int i = 0; i < nParticle; ++i){
                for (int j = i+1; j < nParticle; ++j){
                    ri = &pos[3*i];
                    rj = &pos[3*j];
                    dx = remainder(ri[0]-rj[0], L);
                    dy = remainder(ri[1]-rj[1], L);
                    dz = remainder(ri[2]-rj[2], L);
                
                    s2 = dx*dx + dy*dy + dz*dz;
                    if (s2 < 4*a*a){
                        s = sqrt(s2);
                        if (s < 0.000001){
                            s = 0.000001;
                        }
                        f = krepul * (2 * a - s);
                        #pragma omp atomic
                        forces[3*i+0] += f*dx / s;
                        #pragma omp atomic
                        forces[3*i+1] += f*dy / s;
                        #pragma omp atomic
                        forces[3*i+2] += f*dz / s;
                        #pragma omp atomic
                        forces[3*j+0] -= f*dx / s;
                        #pragma omp atomic
                        forces[3*j+1] -= f*dy / s;
                        #pragma omp atomic
                        forces[3*j+2] -= f*dz / s;
                    }
                }
                y = (1.0 * rand_r(&seed) / RAND_MAX * 2 - 1.0);
                pos[i*3+0] += M * forces[i*3+0] * timeStep + sqrt(2 * timeStep) * y;
    
                y = (1.0 * rand_r(&seed) / RAND_MAX * 2 - 1.0);
                pos[i*3+1] += M * forces[i*3+1] * timeStep + sqrt(2 * timeStep) * y;
    
                y = (1.0 * rand_r(&seed) / RAND_MAX * 2 - 1.0);
                pos[i*3+2] += M * forces[i*3+2] * timeStep + sqrt(2 * timeStep) * y;
            }
        }
    gettimeofday(&end, NULL);
    runtime = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000000.0;
    cout << "runtime is " << runtime << endl;
    delete[] pos;
    delete[] forces;
    return 0;
}
