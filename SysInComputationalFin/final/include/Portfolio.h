#ifndef PORTFOLIO_H
#define PORTFOLIO_H

#include <ql/quantlib.hpp>
#include <ql/timeseries.hpp>
#include "OptionData.h"

using namespace QuantLib;

class Portfolio
{
    public:
        Portfolio(Real initialCash, Real tc, Date startDate);
        virtual ~Portfolio(){};
        Real tradeStock(Real n, Real price);  //return realized return
        Real tradeOption(boost::shared_ptr<RawOption>, Integer n, Real price);   //return realized return
        void updateValue(Date d, Real stockPrice, std::vector<Real> optionPrice);  //compute portfolio value on day d
        void updateValue(Date d);  //do nothing, set value the same as previous day

        void write2Csv(std::string filename) const;

        std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> > getOptions() const{
            return options_;
        }
        Real getStockShares() const{
            return stockShares_;
        }
        Real getCash(Date d) const{
            return cash_[d];
        }
        Real getPositionValue(Date d) const{
            return portValue_[d] - cash_[d];
        }
        Real getTotalWealth(Date d) const{
            return portValue_[d];
        }
        Real getReturn(Date d){
            if (d == startDate_){
                return 0;
            }
            else{
                TimeSeries<Real>::const_iterator k = portValue_.find(d);
                k--;
                return ((portValue_[d] - k->second) / k->second);
            }
        }
        TimeSeries<Real> getTsValue() const{
            return portValue_;
        }

    private:
        TimeSeries<Real> portValue_;
        TimeSeries<Real> cash_;
        std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> > options_;   //pair <option, number of shares>. (<Call, K> <Put, K>) in this example
        Real stockShares_; // shares of the underlying stock
        Real currentCash_;
        Real transCost_;
        Date startDate_;

        Real origCallPrice_;
        Real origPutPrice_;
        Real avgStockPrice_;
};


#endif // PORTFOLIO_H
