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
    int nPartical = 10000;
    int steps = 5000;
    double timeStep = 0.0001;

    // initialize arrays
    double* pos = new double[nPartical*3];
    double* distance= new double[10];
    unsigned int seed = 1234;
    
    omp_set_num_threads(1);
    double diff = 0;
    // set initial positions for particals
    #pragma omp parallel
    {
        #pragma omp for
        for (int i = 0; i < nPartical; ++i){
            pos[i*3] = 1.0 * rand_r(&seed) / RAND_MAX;
            pos[i*3+1] = 1.0 * rand_r(&seed) / RAND_MAX;
            pos[i*3+2] = 1.0 * rand_r(&seed) / RAND_MAX;
        }
    
        double* newPos = new double[3];
        // during each step, partical positions change
        #pragma omp for reduction(+:diff)
        for (int k = 0; k < steps; ++k){
            // record average moving distance every 500 steps
            if ((k+1) % 500 == 0){
                distance[k] = sqrt(diff) / nPartical;
                cout << "Step " << k << ": " << distance[k] << endl;
                // diff = 0;
            }
            for (int i = 0; i < nPartical; ++i){ 
                for (int p = 0; p < 3; ++p){
                    newPos[p] = pos[i*3+p] + sqrt(2 * timeStep) * (1.0 * rand_r(&seed) / RAND_MAX * 2 - 1.0);
                    // cout << 1.0 * rand_r(&seed) / RAND_MAX*2 - 1.0 << endl;
                    diff += (newPos[p] - pos[i*3+p]) * (newPos[p] - pos[i*3+p]);
                    pos[i*3+p] = newPos[p];

                    cout << newPos[p] << " ";
                }
                cout << endl;
            }
        }
    }
    gettimeofday(&end, NULL);
    runtime = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1000000.0;
    cout << "runtime is " << runtime << endl;
    return 0;
}
