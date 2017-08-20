#ifndef SQAURE_H
#define SQAURE_H

#include "BaseFunc.h"

class Sqaure : public BaseFunc
{
    public:
        Sqaure(){};
        virtual ~Sqaure(){};
        virtual double operator()(double x);
        virtual Sqaure* copy() const;
};

#endif // SQAURE_H
