#ifndef GBMPATHGENERATOR_H
#define GBMPATHGENERATOR_H

#include "MyPathGenerator.h"

class GBMPathGenerator : public MyPathGenerator{
    public:
        GBMPathGenerator(Real s0, Real mu, Volatility sigma, Time T, Size nTimeStep);
        virtual ~GBMPathGenerator(){};
        virtual boost::shared_ptr<MyPath> getPath();

    private:
        Real s0_;
        Real mu_;
        Volatility sigma_;
        Time T_;
        Size nTimeStep_;

};

#endif // GBMPATHGENERATOR_H
