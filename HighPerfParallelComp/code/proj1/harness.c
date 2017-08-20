#include <stdlib.h>
#include <stdio.h>
#include <unistd.h> // access
#include <math.h>
#include <assert.h>
#include <mkl_vsl.h>
#include "timer.h"
#include "bd.h"

VSLStreamStatePtr stream;
const int stream_seed = 777;

// return number of particles in trajectory file
int traj_read_npos(const char *filename)
{
    int npos;
    FILE *fp = fopen(filename, "r");
    fscanf(fp, "%d\n", &npos);
    assert(npos > 0);
    fclose(fp);
    return npos;
}

// read first frame of trajectory file
int traj_read(
  const char *filename, 
  char *label,
  int npos,
  double *pos, 
  int *types)
{
    int npos_read;
    FILE *fp = fopen(filename, "r");
    assert(fp);

    fscanf(fp, "%d\n", &npos_read);
    fgets(label, LINE_LEN, fp);

    assert(npos == npos_read);

    for (int i=0; i<npos; i++, pos+=3)
        fscanf(fp, "%d %lf %lf %lf\n", &types[i], &pos[0], &pos[1], &pos[2]);

    fclose(fp);

    return 0;
}

// append positions to trajectory file
int traj_write(
  const char *filename, 
  const char *label,
  int npos, 
  const double *pos, 
  const int *types)
{
    FILE *fp = fopen(filename, "a");
    assert(fp);

    fprintf(fp, "%d\n", npos);
    fprintf(fp, "%s\n", label);

    for (int i=0; i<npos; i++, pos+=3)
        fprintf(fp, "%d %f %f %f\n", types[i], pos[0], pos[1], pos[2]);

    fclose(fp);

    return 0;
}

int main(int argc, char **argv)
{
    if (argc != 4)
    {
        fprintf(stderr, "usage: bd in.xyz out.xyz num_intervals\n");
        return -1;
    }

    char *input_filename  = argv[1];
    char *output_filename = argv[2];
    int num_intervals = atoi(argv[3]);

    if (access(output_filename, F_OK) != -1)
    {
        printf("Output file already exists: %s\nExiting...\n", output_filename);
        return -1;
    }

    int npos = traj_read_npos(input_filename);
    printf("Number of particles: %d\n", npos);
    printf("Number of intervals to simulate: %d\n", num_intervals);

    double *pos   = (double *) malloc(3*npos*sizeof(double));
    double *buf   = (double *) malloc(3*npos*sizeof(double));
    double *forces   = (double *) malloc(3*npos*sizeof(double));
    int    *types = (int *)    malloc(  npos*sizeof(int));
    assert(pos);
    assert(buf);
    assert(types);
    assert(forces);
    // initialize random number stream
    vslNewStream(&stream, VSL_BRNG_SFMT19937, stream_seed);

    char label[LINE_LEN];
    double start_time, box_width;

    traj_read(input_filename, label, npos, pos, types);
    sscanf(label, "%lf %lf", &start_time, &box_width);
    printf("Simulation box width: %f\n", box_width);

    double t1, t0 = time_in_seconds();

    // simulate for num_intervals, writing frame after each interval
    for (int interval=1; interval<=num_intervals; interval++)
    {
        printf("interval : %d\n", interval);
        bd(npos, pos, forces, buf, types);
        sprintf(label, "%f %f",
            start_time+interval*INTERVAL_LEN*DELTAT, box_width);
        traj_write(output_filename, label, npos, pos, types);

        if (interval % 100 == 0)
            printf("Done interval: %d\n", interval);
    }
    t1 = time_in_seconds();
    printf("Time: %f for %d intervals\n", t1-t0, num_intervals);
    printf("Time per time step: %g\n", (t1-t0)/num_intervals/INTERVAL_LEN);

    free(pos);
    free(buf);
    free(types);
    free(forces);
    vslDeleteStream(&stream);

    return 0;
}
