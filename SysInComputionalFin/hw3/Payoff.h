//
//  Payoff.h
//  lab1_3
//
//  Created by Xinyu Min on 8/31/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#ifndef __lab1_3__Payoff__
#define __lab1_3__Payoff__

#include "Option.h"

class Payoff
{
public:

    Payoff() {};
    virtual double operator()(double spot) const=0;
    virtual ~Payoff() {}

    virtual Payoff* copy() const=0;                   // virtual copy constructor

};

class PayoffWithType : public Payoff
{
public:
    PayoffWithType(Option::Type type):type_(type) {};

    void SetType(Option::Type type)
    {
        type_ = type;
    }
    Option::Type GetType() const
    {
        return type_;
    }

protected:
    Option::Type type_;
};

class PayoffVanilla : public PayoffWithType
{
public:
    PayoffVanilla(Option::Type type,double strike);

    void SetStrike(double strike)
    {
        strike_ = strike;
    }
    double GetStrike() const
    {
        return strike_;
    }

    virtual double operator()(double spot) const;

    virtual Payoff* copy() const;

protected:

    double strike_;
};

#endif /* defined(__lab1_3__Payoff__) */
