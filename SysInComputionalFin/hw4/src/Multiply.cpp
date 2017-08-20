#include "Multiply.h"

Multiply::Multiply(double a) : a_(a){}

double Multiply::operator()(double x){
    return a_ * x;
}

Multiply* Multiply::copy() const{
    return new Multiply(*this);
}

void Multiply::setA(double d){
    a_ = d;
}
