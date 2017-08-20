#ifndef EVALUATOR_H
#define EVALUATOR_H

#include "Portfolio.h"
#include <fstream>
#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics.hpp>

using namespace QuantLib;

class Evaluator
{
    public:
        Evaluator(TimeSeries<Real>& values);
        virtual ~Evaluator();
        void write2csv(std::string filename);
        Real getSharpeRatio(){
            return sharpeRatio_;
        }
    private:
        void computeStats(TimeSeries<Real>& values);

        TimeSeries<Real> dailyRet_;
        Real avgRet_;
        Real cumRet_;
        Real sharpeRatio_;
        Real MDD_;

};

#endif // EVALUATOR_H
