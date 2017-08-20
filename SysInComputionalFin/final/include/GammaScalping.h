#ifndef GAMMASCALPING_H
#define GAMMASCALPING_H

#include <ql/quantlib.hpp>
#include <fstream>
#include "SignalGen.h"
#include "Portfolio.h"
#include <stdlib.h>

using namespace QuantLib;

class InfoData{
    public:
        Real& operator[](int i){
            return data[i];
        }
        Real operator[](int i) const{
            return data[i];
        }
    private:
        Real data[24];
};

class GammaScalping
{
    public:
        GammaScalping(boost::shared_ptr<SignalGen> gen, Integer tmin, Integer tmax, Real deltaT);
        virtual ~GammaScalping(){};
        TimeSeries<Real> run(CsvReader& reader, Date startDate, Date endDate, Integer K, Real initialCash, Real tc);
        void write2csv(std::string filename) const;


    private:
        boost::shared_ptr<SignalGen> gen_;
        boost::shared_ptr<Portfolio> portfolio_;
        TimeSeries<Real> price_;
        TimeSeries<Real> rates_;
        boost::shared_ptr<OptionData> options_;

        Integer tmin_;
        Integer tmax_;
        Real deltaT_;

        TimeSeries<std::vector<Real> > info_; //information
//        0-underlying stock price
//        1-sigma_t
//        2-Moving average sigma
//        3-signal
//        4-strike price
//        5-time to expiration
//        6-call price
//        7-put price
//        8-call IV
//        9-put IV
//        10-call delta
//        11-put delta
//        12-call delta + put delta
//        13-call gamma
//        14-put gamma
//        15-stock shares
//        16-position delta
//        17-action
//        18-realized profit
//        19-position total value
//        20-return
//        21-total wealth
//        *22-ATM call price
//        *23-ATM put price
};



#endif // GAMMASCALPING_H
