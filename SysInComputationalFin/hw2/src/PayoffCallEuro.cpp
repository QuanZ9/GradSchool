#include "PayoffCallEuro.h"

double PayoffCallEuro::operator()(double spot) const
{
    return max(0.0, pow(spot, param_i_) - strikePrice_);
}
