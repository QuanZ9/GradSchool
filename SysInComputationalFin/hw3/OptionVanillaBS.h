#ifndef BSCALCULATOR_H
#define BSCALCULATOR_H

#include "Option.h"

class OptionVanillaBS
{
    public:
        OptionVanillaBS(const PayoffBridge& payoff, double s0, double vol, double r, double q, double tau_);
        ~OptionVanillaBS();
        double getBsPayoff();

    private:
        double r_;
        double q_;
        double s0_;
        double vol_;
        double tau_;
        PayoffBridge payoff_;
};

#endif // BSCALCULATOR_H
