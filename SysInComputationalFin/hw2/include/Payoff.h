#include <vector>
#include <math.h>
using namespace std;

#ifndef PAYOFF_H
#define PAYOFF_H

class Payoff
{
public:
    Payoff() {};
    virtual ~Payoff() {};
    virtual double operator()(double spot) const=0;
};

#endif // PAYOFF_H
