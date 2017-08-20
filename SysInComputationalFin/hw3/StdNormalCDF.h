//
//  StdNormalCDF.h
//  hw3
//
//  Created by Xinyu Min on 9/17/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#ifndef __hw3__StdNormalCDF__
#define __hw3__StdNormalCDF__

class StdNormalCDF
{

public:
    double operator()(double x) const;

private:
    static const double A1;
    static const double A2;
    static const double A3;
    static const double A4;
    static const double A5;
    static const double B;
    static const double NORMALIZER;
};

#endif /* defined(__hw3__StdNormalCDF__) */
