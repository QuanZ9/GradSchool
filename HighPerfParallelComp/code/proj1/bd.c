#include "bd.h"
#include "interactions.h"


int bd(
  int npos,
  double *pos,
  double *forces,
  double *buf,
  const int *types)
{
    double f = sqrt(2.*DELTAT);
    double L = pow(1.0/3 * 3.14 * A*A*A * npos / UTILIZATION, 1.0/3);
    
    //printf("L = %f\n", L);
    
    double cutoff2 = 4*A*A;

    for (int step=0; step<INTERVAL_LEN; step++)
    {
        // generate random values from standard normal distribution
        // note: this MKL function is sequential but vectorized
        vdRngGaussian(VSL_RNG_METHOD_GAUSSIAN_BOXMULLER,
            stream, 3*npos, buf, 0., 1.);
        //printf("bd.c before calling interactions\n");
        
        interactions(npos, pos, L, cutoff2, forces);
        
        //printf("npos = %d\n", npos);
        //printf("pos[0] = %f\n", pos[0]);
        //printf("forces[0] = %f\n", forces[0]);
        
        //printf("bd.c after calling interactions\n");

        // update positions with Brownian displacements
        //printf("bd.c before for loop\n");
        for (int i=0; i<3*npos; i++)
        {
            pos[i] += f*buf[i] + 1.0*forces[i]*DELTAT;
            forces[i] = 0.0;
        }
        //printf("bd.c after for loop\n");
        // getchar();
    }
}
