#include "PayoffPutEuro.h"
#include <iostream>


double PayoffPutEuro::operator()(double spot) const
{
    return max(0.0, strikePrice_ - pow(spot, param_i_));
}
