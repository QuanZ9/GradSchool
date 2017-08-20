#ifndef MULTIPLY_H
#define MULTIPLY_H

#include "BaseFunc.h"

class Multiply : public BaseFunc
{
    public:
        Multiply(double a);
        virtual ~Multiply(){};
        virtual double operator()(double x);
        virtual Multiply* copy() const;
        void setA(double d);
    private:
        double a_;
};

#endif // MULTIPLY_H
