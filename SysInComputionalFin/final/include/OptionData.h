#ifndef OPTIONDATA_H
#define OPTIONDATA_H

#include <ql/quantlib.hpp>

using namespace QuantLib;

struct RawOption{
    public:
        RawOption(Date date, Date exp, Option::Type type, Real strike, Real price)
            : date_(date), expDate_(exp), type_(type), strike_(strike), price_(price){};
        Date getDate() const{
            return date_;
        }
        Date getExpDate() const{
            return expDate_;
        }
        Real getStrike() const{
            return strike_;
        }
        Real getPrice() const{
            return price_;
        }
        Option::Type getType() const{
            return type_;
        }

        bool equals(boost::shared_ptr<RawOption> other){
            if (expDate_ == other->getExpDate() &&
                    type_ == other->getType() &&
                    strike_ == other->getStrike()){
                return true;
            }
            return false;
        }
    private:
        Option::Type type_;
        Date date_;
        Date expDate_;
        Real strike_;
        Real price_;
};

class OptionData
{
    public:
        OptionData(){};
        virtual ~OptionData(){};
        Real getIVonDate(Date date, Real price, Real rate, Integer tmin, Integer tmax) const; //get average IV of 2 ATM options on a given date
        Real getImpliedVol(boost::shared_ptr<RawOption> option, Real price, Real rate) const; //get IV of an option
        Real getDelta(boost::shared_ptr<RawOption> option, Real price, Real rate) const;      //get delta
        Real getGamma(boost::shared_ptr<RawOption> option, Real price, Real rate) const;      //get gamma
        boost::shared_ptr<RawOption> getATM(Date d, Option::Type type, Real price, Integer tmin, Integer tmax) const;  //get ATM option on a given date
        boost::shared_ptr<RawOption> updatePrice(boost::shared_ptr<RawOption> option, Date d) const;
        void add(boost::shared_ptr<RawOption> option);
    private:
        std::vector<boost::shared_ptr<RawOption> > data_;
};


#endif // OPTIONDATA_H
