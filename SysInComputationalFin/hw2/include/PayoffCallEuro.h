#include <Payoff.h>

#ifndef PAYOFFCALLEURO_H
#define PAYOFFCALLEURO_H

class PayoffCallEuro: public Payoff
{
public:
    PayoffCallEuro(double strikePrice, int param_i)
        :strikePrice_(strikePrice), param_i_(param_i)
    {
    };
    virtual ~PayoffCallEuro() {};
    virtual double operator()(double spot) const;

private:
    double strikePrice_;
    int param_i_;
};

#endif // PAYOFFEURO_H
