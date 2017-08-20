#ifndef SIGNALGEN_H
#define SIGNALGEN_H

#include <ql/quantlib.hpp>
#include <boost/accumulators/statistics/rolling_variance.hpp>
#include <boost/accumulators/statistics/rolling_mean.hpp>
#include <vector>
#include "CsvReader.h"

using namespace QuantLib;

//define trading signals
enum Signal{
    nothing = 0,
    enterP = 1,
    closeP = 2,
    holdP = 3
};

//different ways to compute volatility
enum VolType{
    historical = 0,
    implied = 1
};

//base class for signal generator
class SignalGen
{
    public:
        SignalGen(){};
        virtual ~SignalGen(){};
        virtual Signal operator()(Date date) = 0;
};


//generate signals based on volatility
class VolSignalGen : public SignalGen{
    public:
        VolSignalGen(bool type, Real low, Real high, Integer e, Integer w, Integer m);
        virtual ~VolSignalGen(){};
        virtual Signal operator()(Date date);
        void setExpiry(Date d);
        void setData(CsvReader& reader, TimeSeries<Real>& price,
                        boost::shared_ptr<OptionData> options, TimeSeries<Real>& rates, Real tmin, Real tmax);
        Real getMAvol(Date d){
            return smvVol_[d];
        }
        Real getVol(Date d){
            return vols_[d];
        }
        bool isHistorical(){
            return useHistorical_;
        }

    private:
        void historicalSMV_Vol(TimeSeries<Real> prices);
        void impliedSMV_Vol(TimeSeries<Real>& price, boost::shared_ptr<OptionData> options, TimeSeries<Real>& rates, Real tmin, Real tmax);
        void getImpliedVol(boost::shared_ptr<OptionData> option, Real pricem, Real rate);

        TimeSeries<Real> smvVol_;   //simple moving average of volatility
        TimeSeries<Real> vols_;      //annualized volatility
        Date expiry_;      //option in portfolio
        Integer e_;            //threshold
        Real low_;         //entry volatility
        Real high_;        //exit volatility
        bool useHistorical_;     //use historical or implied volatility
        bool position_;    //current position. false->close
        Integer w_;         // w-day simple moving average
        Integer m_;         // m-day historical standard deviation
};


#endif // SIGNALGEN_H
