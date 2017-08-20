#include "Sqaure.h"

double Sqaure::operator()(double x){
    return x * x;
}

Sqaure* Sqaure::copy() const{
    return new Sqaure(*this);
}
