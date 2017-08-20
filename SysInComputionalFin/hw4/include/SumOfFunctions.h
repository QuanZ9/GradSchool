#ifndef SUMOFFUNCTIONS_H
#define SUMOFFUNCTIONS_H

#include "BaseFunc.h"
#include <vector>

class SumOfFunctions
{
    public:
        SumOfFunctions();
        virtual ~SumOfFunctions();
        void add(BaseFunc* newFunc);
        double operator()(double x);
    private:
        std::vector<BaseFunc*> funcs;
};

#endif // SUMOFFUNCTIONS_H
