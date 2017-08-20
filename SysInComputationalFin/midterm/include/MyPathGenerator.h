#ifndef MYPATHGENERATOR_H
#define MYPATHGENERATOR_H

#include <ql/quantlib.hpp>
#include "MyPath.h"

using namespace QuantLib;

class MyPathGenerator
{
    public:
        MyPathGenerator(){};
        virtual ~MyPathGenerator(){};
        virtual boost::shared_ptr<MyPath> getPath() = 0;
};

#endif // MYPATHGENERATOR_H
