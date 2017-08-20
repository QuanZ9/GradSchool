//
//  Option.cpp
//  lab2_1
//
//  Created by Xinyu Min on 9/4/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#include "Option.h"
#include "PayoffBridge.h"

// constructor
Option::Option(const PayoffBridge& payoff, double expiry)
    : payoff_(payoff), expiry_(expiry)
{
}

double Option::PayoffOnExpiry(double spot) const
{
    return payoff_(spot);
}
