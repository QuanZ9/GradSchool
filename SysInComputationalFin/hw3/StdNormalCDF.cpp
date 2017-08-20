//
//  StdNormalCDF.cpp
//  hw3
//
//  Created by Xinyu Min on 9/17/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#include "StdNormalCDF.h"
#include <math.h>

double StdNormalCDF::operator()(double x) const
{
    double z = 1.0 / (1.0 + B * x);
    double rz = z * (z * (z * (z * (z * A5 + A4) + A3) + A2) + A1);
    if (x >= 0)
    {
        return 1 - NORMALIZER * exp(-1.0 * x * x / 2.0) * rz;
    }
    else
    {
        return 1 - operator()(-x);
    }
}


const double StdNormalCDF::A1 = 0.319381530;
const double StdNormalCDF::A2 = -0.35653782;
const double StdNormalCDF::A3 = 1.781477937;
const double StdNormalCDF::A4 = -1.821255978;
const double StdNormalCDF::A5 = 1.330274429;
const double StdNormalCDF::B = 0.2316419;
const double StdNormalCDF::NORMALIZER = 0.39894228;     // really 1/sqrt(2*pi);
