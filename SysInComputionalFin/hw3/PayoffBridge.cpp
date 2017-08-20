//
//  PayoffBridge.cpp
//  lab2_3
//
//  Created by Xinyu Min on 9/4/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#include "PayoffBridge.h"
#include "Payoff.h"

// constructor
PayoffBridge::PayoffBridge(Payoff& payoff)
{
    p_payoff_ = payoff.copy();

}
// copy constructor
PayoffBridge::PayoffBridge(const PayoffBridge& old)
{
    p_payoff_ = old.p_payoff_->copy();
}
// copy assignment
PayoffBridge& PayoffBridge::operator=(const PayoffBridge& old)
{
    if (this!=&old)
    {
        delete p_payoff_;
        p_payoff_ = old.p_payoff_->copy();
    }
    return (*this);
}
// destructor
PayoffBridge::~PayoffBridge()
{
    delete p_payoff_;
}

// functor
double PayoffBridge::operator()(double spot) const
{
    return (*p_payoff_)(spot);
}

Payoff* PayoffBridge::getPayoffObj() const{
    return p_payoff_;
}
