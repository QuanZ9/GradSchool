#include "interactions.h"
#include "bd.h"


struct box
{
    int head;
};

// it is possible to use smaller boxes and more complex neighbor patterns
#define NUM_BOX_NEIGHBORS 13
int box_neighbors[NUM_BOX_NEIGHBORS][3] =
{
    {-1,-1,-1},
    {-1,-1, 0},
    {-1,-1,+1},
    {-1, 0,-1},
    {-1, 0, 0},
    {-1, 0,+1},
    {-1,+1,-1},
    {-1,+1, 0},
    {-1,+1,+1},
    { 0,-1,-1},
    { 0,-1, 0},
    { 0,-1,+1},
    { 0, 0,-1}
};
// interactions function
//
// Construct a list of particle pairs within a cutoff distance
// using Verlet cell lists.  The L*L*L domain is divided into
// BOX_DIM*BOX_DIM*BOX_DIM cells.  We require cutoff < L/BOX_DIM 
// and BOX_DIM >= 4.  Periodic boundaries are used.
// Square of distance is also returned for each pair.
// Note that only one of (i,j) and (j,i) are returned (not both).
// The output is not sorted by index in any way.
//
// npos = number of particles
// pos  = positions stored as [pos1x pos1y pos1z pos2x ...]
//        The positions must be wrapped inside the box, i.e., pos in [0,L]^3
// L    = length of one side of box
// BOX_DIM = number of cells on one side of box
// cutoff2 = square of cutoff
// distances2[maxnumpairs] = OUTPUT square of distances for particles 
//                           within cutoff
// pairs[maxnumpairs*2] = OUTPUT particle pairs stored as 
//                        [pair1i pair1j pair2i pair2j ...]
// maxnumpairs = max number of pairs that can be stored in user-provided arrays
// numpairs_p = pointer to actual number of pairs (OUTPUT)
//
// function returns 0 if successful, or nonzero if error occured


int interactions(int npos, const double *pos, double L, double cutoff2, double* forces)
{
    //printf("interactions begins...\n");
    
    if (BOX_DIM < 4 || cutoff2 > (L/BOX_DIM)*(L/BOX_DIM))
    {
        //printf("interactions: bad input parameters\n");
        return 1;
    }
    //construct cell list
    struct box b[BOX_DIM][BOX_DIM][BOX_DIM];
    struct box *bp;


    int d2, dx, dy, dz;
    int p1, p2;
    struct box *neigh_bp;
    int neigh_idx, neigh_idy, neigh_idz;
    double tp[3];
    
    // box indices
    int idx, idy, idz;

    // allocate memory for particles in each box
    for (idx=0; idx<BOX_DIM; idx++)
    for (idy=0; idy<BOX_DIM; idy++)
    for (idz=0; idz<BOX_DIM; idz++)
        b[idx][idy][idz].head = -1;

    // allocate implied linked list
    int *next = (int *) malloc(npos*sizeof(int));
    if (next == NULL)
    {
        //printf("interactions: could not malloc array for %d particles\n", npos);
        return 1;
    }

    // traverse all particles and assign to boxes
    int i;
    for (i=0; i<npos; i++)
    {
        // initialize entry of implied linked list
        next[i] = -1;

        // which box does the particle belong to?
        // assumes particles have positions within [0,L]^3
        
        for (int k = 0; k < 3; ++k){
            tp[k] = pos[3*i + k];
            while (tp[k] < 0){
                tp[k] += L;
            }
            while (tp[k] >= L){
                tp[k] -= L;
            }
        }
        idx = (int)(tp[0]/L*BOX_DIM);
        idy = (int)(tp[1]/L*BOX_DIM);
        idz = (int)(tp[2]/L*BOX_DIM);

        // add to beginning of implied linked list
        bp = &b[idx][idy][idz];
        // //printf("%f\t%f\t%f\n", pos[3*i], pos[3*i+1], pos[3*i+2]);
        next[i] = bp->head;
        //printf("particle %d/%d:\n", i, npos);
        //printf("\t (%f, %f, %f) in %d, %d, %d\n", pos[3*i], pos[3*i+1], pos[3*i+2], idx, idy, idz);
        bp->head = i;
    
    
        assert(tp[0] >= 0);
        assert(tp[0] < L);
        assert(tp[1] >= 0);
        assert(tp[1] < L);
        assert(tp[2] >= 0);
        assert(tp[2] < L); 
    
    }


    //loop through all bins and compute forces for each particle
    // cellList and pos are shared read-only arrays
    // forces is a shared array but only one thread is supposed to write to a position. No race condition. 
    for (idx=0; idx<BOX_DIM; idx++)
    {
        for (idy=0; idy<BOX_DIM; idy++)
        {
            for (idz=0; idz<BOX_DIM; idz++)
            {
                bp = &b[idx][idy][idz];
            
                // within box interactions
                p1 = bp->head;
                while (p1 != -1)
                {
                    p2 = next[p1];
                    while (p2 != -1)
                    {
                        // do not need minimum image since we are in same box
                        dx = pos[3*p1+0] - pos[3*p2+0];
                        dy = pos[3*p1+1] - pos[3*p2+1];
                        dz = pos[3*p1+2] - pos[3*p2+2];
            
                        if ((d2 = dx*dx+dy*dy+dz*dz) < cutoff2)
                        {
                            forces[p1] += 100 * (2*A - sqrt(d2));
                        }
                        p2 = next[p2];
                    }
                    p1 = next[p1];
                }
            
                // interactions with other boxes
                int j;
                for (j=0; j<NUM_BOX_NEIGHBORS; j++)
                {
                    neigh_idx = (idx + box_neighbors[j][0] + BOX_DIM) % BOX_DIM;
                    neigh_idy = (idy + box_neighbors[j][1] + BOX_DIM) % BOX_DIM;
                    neigh_idz = (idz + box_neighbors[j][2] + BOX_DIM) % BOX_DIM;
            
                    neigh_bp = &b[neigh_idx][neigh_idy][neigh_idz];
            
                    // when using boxes, the minimum image computation is 
                    // known beforehand, thus we can  compute position offsets 
                    // to compensate for wraparound when computing distances
                    double xoffset = 0.;
                    double yoffset = 0.;
                    double zoffset = 0.;
                    if (idx + box_neighbors[j][0] == -1)     xoffset = -L;
                    if (idy + box_neighbors[j][1] == -1)     yoffset = -L;
                    if (idz + box_neighbors[j][2] == -1)     zoffset = -L;
                    if (idx + box_neighbors[j][0] == BOX_DIM) xoffset =  L;
                    if (idy + box_neighbors[j][1] == BOX_DIM) yoffset =  L;
                    if (idz + box_neighbors[j][2] == BOX_DIM) zoffset =  L;
            
                    p1 = neigh_bp->head;
                    while (p1 != -1)
                    {   
                        p2 = bp->head;
                        while (p2 != -1)
                        {
                            // compute distance vector
                            dx = pos[3*p1+0] - pos[3*p2+0] + xoffset;
                            dy = pos[3*p1+1] - pos[3*p2+1] + yoffset;
                            dz = pos[3*p1+2] - pos[3*p2+2] + zoffset;
            
                            if ((d2 = dx*dx+dy*dy+dz*dz) < cutoff2)
                            {
                                forces[p1] += 100 * (2*A - sqrt(d2));
                            }
            
                            p2 = next[p2];
                        }
                        p1 = next[p1];
                    }
                }
            }
        }
    }
    //printf("At interactions exit: %f, %f\n", pos[0], forces[0]);
    //printf("interactions ends...\n");
    free(next);
    //printf("interactions returns...\n");
    return 0;
}



#if 0
#include "mex.h"

// matlab: function pairs = interactions(pos, L, BOX_DIM, cutoff)
//  assumes pos is in [0,L]^3
//  assumes BOX_DIM >= 4
//  pairs is an int array, may need to convert to double for matlab use
void
mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int npos;
    const double *pos;
    double L;
    int BOX_DIM;
    double cutoff;

    npos   = mxGetN(prhs[0]);
    pos    = mxGetPr(prhs[0]);
    L      = mxGetScalar(prhs[1]);
    BOX_DIM = (int) mxGetScalar(prhs[2]);
    cutoff = mxGetScalar(prhs[3]);

    // estimate max number of pairs, assuming somewhat uniform distribution
    double ave_per_box = npos / (double)(BOX_DIM*BOX_DIM*BOX_DIM) + 1.;
    int maxnumpairs = (int) (0.7*npos*ave_per_box*(NUM_BOX_NEIGHBORS+1) + 1.);
    //printf("interactions: maxnumpairs: %d\n", maxnumpairs);

    // allocate storage for output
    int *pairs = (int *) malloc(2*maxnumpairs*sizeof(int));
    double *distances2 = (double *) malloc(maxnumpairs*sizeof(double));
    if (pairs == NULL || distances2 == NULL)
    {
        //printf("interactions: could not allocate storage\n");
        return;
    }

    int numpairs; // actual number of pairs
    int ret;
    ret = interactions(npos, pos, L, BOX_DIM, cutoff*cutoff, distances2, 
                       pairs, maxnumpairs, &numpairs);
    if (ret != 0)
    {
        //printf("interactions: error occured\n");
        if (ret == -1)
            //printf("interactions: estimate of required storage was too low\n");
        return;
    }
    //printf("interactions: numpairs: %d\n", numpairs);

    // allocate matlab output matrix
    plhs[0] = mxCreateDoubleMatrix(numpairs, 3, mxREAL);
    double *data = (double *) mxGetPr(plhs[0]);

    // first col of data array is row indices
    // second col of data array is col indices
    // third col of data array is distance2
    int i;
    for (i=0; i<numpairs; i++)
    {
        data[i]            = pairs[2*i];
        data[i+numpairs]   = pairs[2*i+1];
        data[i+numpairs*2] = distances2[i];
    }

    free(pairs);
    free(distances2);
}

//#else
int main()
{
    int npos = 3;
    double pos[] = {0., 0., 0.,  0., 0., 3.5,  0., 3.5, 0.};
    double L = 8;
    int pairs[1000*2];
    int numpairs;

    interactions(npos, pos, L, 8, 99., pairs, 1000, &numpairs);

    //printf("numpairs %d\n", numpairs);

    return 0;
}
#endif

