#include <PayoffAsian.h>
#include <iostream>


double PayoffAsianCall::operator()(std::vector<double>& spot) const
{
    double total = 0;
    for (int i = 0; i < spot.size(); ++i)
    {
        total += spot[i];
    }

    double avg = total / spot.size();

    return max(0.0, avg - strike_);
}

double PayoffAsianCall::operator()(double spot) const
{
    return max(0.0, spot - strike_);
}
