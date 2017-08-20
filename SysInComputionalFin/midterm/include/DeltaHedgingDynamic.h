#ifndef DELTAHEDGINGDYNAMIC_H
#define DELTAHEDGINGDYNAMIC_H

#include "DeltaHedging.h"
#include <ql/quantlib.hpp>
#include "Util.h"

using namespace QuantLib;

class DeltaHedgingDynamic : public DeltaHedging
{
    public:
        DeltaHedgingDynamic(Option::Type type,
                     Real strike,
                     Date expDate,
                     Date startDate,
                     Date endDate,
                     Real startCash,
                     std::string rateFile,
                     std::string volFile,
                     std::string outFile);
        virtual ~DeltaHedgingDynamic(){};

        boost::shared_ptr<MyPath> getRates(){
            return rates_;
        };
        boost::shared_ptr<MyPath> getVols(){
            return vols_;
        };



    protected:
        virtual Rate getRate(Date d) const;
        virtual Volatility getVol(Date d, Real stockPrice) const;
        virtual Real getOptionPrice(const BlackCalculator& bs, Date d) const;
        virtual void writeToCsv(const MyPath& path) const;
    private:
        boost::shared_ptr<MyPath> rates_;
        boost::shared_ptr<MyPath> vols_;
        std::vector<boost::shared_ptr<VanillaOption> > options_;
        Date startDate_;
        Date endDate_;
        Date expDate_;

        void readRateFile(std::string filename);
        void readOptionFile(std::string filename);


        Size getNTimeStep(Date startDate, Date endDate) const;
        Time getTime(Date startDate, Date endDate) const;

        virtual Time getTimeToExp(Integer i, Time dt) const;
};

#endif // DELTAHEDGINGDYNAMIC_H
