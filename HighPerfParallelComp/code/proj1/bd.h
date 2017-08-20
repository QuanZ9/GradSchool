#ifndef BD_H
#define BD_H


#include <mkl_vsl.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h> // access
#include <math.h>
#include <assert.h>
#include "timer.h"

#define INTERVAL_LEN 1000
#define DELTAT       1e-4
#define LINE_LEN     100
#define A 1
#define UTILIZATION 0.2
#define BOX_DIM 4


extern VSLStreamStatePtr stream;
extern const int stream_seed;

int bd(int npos, double *pos, double *forces, double *buf, const int *types);


#endif /* BD_H */
