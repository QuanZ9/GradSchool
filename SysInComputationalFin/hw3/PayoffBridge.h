//
//  PayoffBridge.h
//  lab2_3
//
//  Created by Xinyu Min on 9/4/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#ifndef __lab2_3__PayoffBridge__
#define __lab2_3__PayoffBridge__

class Payoff;


// The Bridge Pattern
class PayoffBridge
{

public:
    // constructor
    PayoffBridge(Payoff& payoff);
    // copy constructor
    PayoffBridge(const PayoffBridge& old);
    // copy assignment
    PayoffBridge& operator=(const PayoffBridge& old);
    // destructor
    ~PayoffBridge();

    // functor
    double operator()(double spot) const;

    Payoff* getPayoffObj() const;

private:
    Payoff* p_payoff_;

};

#endif /* defined(__lab2_3__PayoffBridge__) */
