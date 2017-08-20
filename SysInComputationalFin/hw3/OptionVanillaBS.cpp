#include "OptionVanillaBS.h"
#include "Payoff.h"
#include "StdNormalCDF.h"
#include <stdlib.h>
#include <math.h>
#include <iostream>
using namespace std;


OptionVanillaBS::OptionVanillaBS(const PayoffBridge& payoff, double s0, double vol, double r, double q, double tau)
    :payoff_(payoff), s0_(s0), vol_(vol), r_(r), q_(q), tau_(tau)
{
}

OptionVanillaBS::~OptionVanillaBS()
{

}

double OptionVanillaBS::getBsPayoff(){
    PayoffVanilla* p = (PayoffVanilla *)payoff_.getPayoffObj();
    double k = p->GetStrike();
    StdNormalCDF cdf;
    double volTau = vol_ * sqrt(tau_);
    double d1 = (log(s0_ / k) + (r_ - q_ + 0.5 * vol_ * vol_) * tau_) / volTau;
    double d2 = d1 - volTau;

    double part1 = s0_ * exp(-1 * q_ * tau_);
    double part2 = k * exp(-1 * r_ * tau_);

    //call payoff
    if (p->GetType() == Option::Call){
        return part1 * cdf(d1) - part2 * cdf(d2);
    }
    //put payoff
    else if (p->GetType() == Option::Put){
        return -1 * part1 * cdf(-1 * d1) + part2 * cdf(-1 * d2);
    }
    else{
        cout << "wrong option type!" << endl;
    }
    return 0.0;
}

