//
//  Option.h
//  lab2_1
//
//  Created by Xinyu Min on 9/4/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#ifndef __lab2_1__Option__
#define __lab2_1__Option__

#include "PayoffBridge.h"

class Option {

public:

    enum Type {Put = -1, Call = 1, None = 0};

    double PayoffOnExpiry (double spot) const;

    void SetExpiry(double expiry) {expiry_=expiry;}
    double GetExpiry() const {return expiry_;}

    // --------------Below is different from lab 2_2---------------------
    Option(const PayoffBridge& payoff, double expiry);     // use PayoffBridge& rather than Payoff&

    //~Option();          // custom destructor to destruct the Payoff pointer



protected:

    // --------------Below is different from lab 2_2---------------------
    PayoffBridge payoff_;
    //Payoff * p_payoff_;


    double expiry_;
};





#endif /* defined(__lab2_1__Option__) */
