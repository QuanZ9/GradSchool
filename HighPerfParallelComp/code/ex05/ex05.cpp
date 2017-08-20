#include <iostream>
#include <stdlib.h>
#include <sys/time.h>
#include <math.h>
#include <omp.h>
#include <stdio.h>
#include "./interactions.c"

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
    cout << "L = " << L << endl;
    double krepul = 100;
    double M = 1;

    // initialize arrays
    double* pos = new double[nParticle*3];
    double* forces = new double[nParticle*3];
    fill(forces, forces+nParticle*3, 0);
    unsigned int seed = 1234;
    
    //ex05 - cell list
    int maxNumPairs = 1000000;
    int* pairs = new int[maxNumPairs*2];
    int numPairs;
    int boxdim = 4.0;
    double cutoff2 = 5.0;
    double* distance2 = new double[maxNumPairs];
    int pi;
    int pj;


    omp_set_num_threads(1);
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
            pos[i*3] = 1.0 * rand_r(&seed) / RAND_MAX * L;
            pos[i*3+1] = 1.0 * rand_r(&seed) / RAND_MAX * L;
            pos[i*3+2] = 1.0 * rand_r(&seed) / RAND_MAX * L;
        }
    }
    // during each step, partical positions change
    for (int k = 0; k < steps; ++k){
        interactions(nParticle, pos, L, boxdim, cutoff2, distance2, pairs, maxNumPairs, &numPairs);
        if (k% 500 == 0){
            cout << "step " << k << "--- num pairs: " << numPairs << endl;
        }
        // #pragma omp parallel for
        for (int i = 0; i < numPairs; ++i){
            pi = pairs[i*2+0];
            pj = pairs[i*2+1];
            ri = &pos[3*pi];
            rj = &pos[3*pj];
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
                forces[3*pi+0] += f*dx / s;
                #pragma omp atomic
                forces[3*pi+1] += f*dy / s;
                #pragma omp atomic
                forces[3*pi+2] += f*dz / s;
                #pragma omp atomic
                forces[3*pj+0] -= f*dx / s;
                #pragma omp atomic
                forces[3*pj+1] -= f*dy / s;
                #pragma omp atomic
                forces[3*pj+2] -= f*dz / s;
            }
        }
        // #pragma omp parallel for
        for (int i = 0; i < nParticle; ++i){
            for (int p = 0; p < 3; ++p){
                y = (1.0 * rand_r(&seed) / RAND_MAX * 2 - 1.0);
                pos[i*3+p] += M * forces[i*3+0] * timeStep + sqrt(2 * timeStep) * y;
                while (pos[i*3+p] >= L){
                    pos[i*3+p] -= L;
                }
                while (pos[i*3+p] < 0){
                    pos[i*3+p] += L;
                }
            }
        }
    } 
    gettimeofday(&end, NULL);
    runtime = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000000.0;
    cout << "runtime is " << runtime << endl;
    delete[] pos;
    delete[] forces;
    delete[] pairs;
    delete[] distance2;
    return 0;
}
