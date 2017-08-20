//
//  PayoffAsian.h
//  lab1_3
//
//  Created by Xinyu Min on 8/31/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#ifndef __lab1_3__PayoffAsian__
#define __lab1_3__PayoffAsian__

#include "Payoff.h"
#include <vector>

// Payoff class for an asian call option with fixed strike under arithmetic averaging
class PayoffAsianCall: public Payoff
{
public:

    PayoffAsianCall(double strike) : strike_(strike) {};
    virtual double operator()(std::vector<double> & spot) const;
    virtual double operator()(double spot) const;
    virtual ~PayoffAsianCall() {};

private:

    double strike_;
};

#endif /* defined(__lab1_3__PayoffAsian__) */
