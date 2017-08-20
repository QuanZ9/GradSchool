#ifndef PAYOFFPUTEURO_H
#define PAYOFFPUTEURO_H

#include <Payoff.h>


class PayoffPutEuro : public Payoff
{
public:
    PayoffPutEuro(double strikePrice, int param_i) : strikePrice_(strikePrice), param_i_(param_i) {};
    virtual ~PayoffPutEuro() {};
    virtual double operator()(double spot) const;

private:
    double strikePrice_;
    int param_i_;
};

#endif // PAYOFFPUTEURO_H
