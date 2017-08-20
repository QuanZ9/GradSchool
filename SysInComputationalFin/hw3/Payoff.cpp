//
//  Payoff.cpp
//  lab1_3
//
//  Created by Xinyu Min on 8/31/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//


#include "Payoff.h"
#include <algorithm>
#include <iostream>
using std::max;
using std::endl;
using std::cerr;
using std::cout;

PayoffVanilla::PayoffVanilla(Option::Type type,double strike)
    : PayoffWithType(type), strike_(strike)
{
}

double PayoffVanilla::operator()(double spot) const
{
    if (type_==Option::Call)
    {
        return max(spot-strike_,0.0);
    }
    else if(type_==Option::Put)
    {
        return max(strike_-spot,0.0);
    }
    else
    {
        cerr<<"Wrong Type!"<<endl;
        return 0.0;
    }
}


Payoff* PayoffVanilla::copy() const
{
    return new PayoffVanilla(*this);
}

