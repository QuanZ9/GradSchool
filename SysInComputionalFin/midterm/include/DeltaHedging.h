#ifndef DELTAHEDGING_H
#define DELTAHEDGING_H

#include <ql/quantlib.hpp>
#include "MyPath.h"
#include <vector>

using namespace QuantLib;

class DeltaHedging : public PathPricer<MyPath>
{
    public:
        DeltaHedging(Option::Type type,
                     Real strike,
                     Volatility vol,
                     Time T,
                     Size nTimeSteps,
                     Rate r,
                     Real startCash,
                     std::string outFile = "");
        virtual ~DeltaHedging();

        //void simulation(Size nPath);
        boost::shared_ptr<MyPath> getOptionPrices();
        boost::shared_ptr<MyPath> getDeltas();
        boost::shared_ptr<MyPath> getHedgingErrors();
        boost::shared_ptr<MyPath> getCash();

        virtual Real operator()(const MyPath& path) const; //return total hedging error

    protected:
        boost::shared_ptr<MyPath> cash_;         //sequence of cash positions
        boost::shared_ptr<MyPath> optionPrices_; // sequence of options
        boost::shared_ptr<MyPath> deltas_;       //sequence of delta
        boost::shared_ptr<MyPath> hedgingErrors_;  //hedging error
        std::string outFile_;

        Option::Type type_;   //option type
        Real strike_;
        Volatility vol_;    //volatility
        Time T_;              //maturity time
        Rate r_;              //risk free rate
        Time timePeriod_;      //hedging time period
        Real startCash_;

        virtual Volatility getVol(Date d, Real stockPrice) const;
        virtual Rate getRate(Date d) const;
        virtual Time getTimeToExp(Integer i, Time dt) const;
        virtual Real getOptionPrice(const BlackCalculator& bs, Date d) const;
        virtual void writeToCsv(const MyPath& path) const;
};

#endif // DELTAHEDGING_H
