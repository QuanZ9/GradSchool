#include "GammaScalping.h"

GammaScalping::GammaScalping(boost::shared_ptr<SignalGen> gen, Integer tmin, Integer tmax, Real deltaT)
    : gen_(gen), tmin_(tmin), tmax_(tmax), deltaT_(deltaT)
{
}

TimeSeries<Real> GammaScalping::run(CsvReader& reader, Date startDate0, Date endDate0, Integer K, Real initialCash, Real tc){
    //adjust date
    Calendar calendar = UnitedStates(UnitedStates::NYSE);
    Date startDate = calendar.adjust(startDate0);
    Date endDate = calendar.adjust(endDate0, Preceding);

    //setup data
    portfolio_ = boost::shared_ptr<Portfolio>(new Portfolio(initialCash, tc, startDate));
    price_ = reader.readStock(startDate, endDate);
    rates_ = reader.readRf(startDate, endDate);
    options_ = reader.readOption(startDate, endDate);

    boost::shared_ptr<VolSignalGen> volGen = boost::static_pointer_cast<VolSignalGen>(gen_);
    volGen->setData(reader, price_, options_, rates_, tmin_, tmax_);

    Real enterWealth = 0;
    std::vector<std::vector<Real> > info;
    std::vector<Date> dates;
    //from t0 to tn, run gamma scalping
    for (Date date = startDate; date < endDate; date++){
        if (!calendar.isBusinessDay(date)){
            continue;
        }
        std::vector<Real> infoToday;
        infoToday.resize(24);
        Signal signal = (*gen_)(date);

        infoToday[0] = price_[date];
        infoToday[1] = volGen->getVol(date);
        infoToday[2] = volGen->getMAvol(date);
        infoToday[3] = signal;
        infoToday[17] = signal;
//        std::cout << "signal on " << date << " is " << signal << std::endl;
        switch (signal){
            case enterP:{
                //enter position
                //buy K shares of ATM call&put option
                boost::shared_ptr<RawOption> ATMcall = options_->getATM(date, Option::Call, price_[date], tmin_, tmax_);
                boost::shared_ptr<RawOption> ATMput = options_->getATM(date, Option::Put, price_[date], tmin_, tmax_);
                portfolio_->tradeOption(ATMcall, K, ATMcall->getPrice());
                portfolio_->tradeOption(ATMput, K, ATMput->getPrice());
                //set expiry
                volGen->setExpiry(ATMcall->getExpDate());

                //buy delta shares of stocks to make the position delta-neutral
                Real callDelta = options_->getDelta(ATMcall, price_[date], rates_[date]);
                Real putDelta = options_->getDelta(ATMput, price_[date], rates_[date]);

//                std::cout << "call delta = " << callDelta << std::endl;
//                std::cout << "put delta = " << putDelta << std::endl;

                Real numShares = 0;

                if (std::abs(callDelta + putDelta) <= deltaT_ || callDelta == 0 || putDelta == 0){
                    //do nothing
                }
                else{
                    //trade some stocks
                    numShares = -1.0 * (callDelta + putDelta) * 100 * K;
                    portfolio_->tradeStock(numShares, price_[date]);
//                    std::cout << "number shares = " << numShares << std::endl;
                }
                //update portfolio
                std::vector<Real> todayPrice;
                todayPrice.push_back(ATMcall->getPrice());
                todayPrice.push_back(ATMput->getPrice());
                portfolio_->updateValue(date, price_[date], todayPrice);
                enterWealth = portfolio_->getTotalWealth(date);

                infoToday[4] = ATMput->getStrike();
                infoToday[5] = calendar.businessDaysBetween(date, ATMput->getExpDate(), true, true);
                infoToday[6] = ATMcall->getPrice();
                infoToday[7] = ATMput->getPrice();
                infoToday[8] = options_->getImpliedVol(ATMcall, price_[date], rates_[date]);
                infoToday[9] = options_->getImpliedVol(ATMput, price_[date], rates_[date]);
                infoToday[10] = callDelta;
                infoToday[11] = putDelta;
                infoToday[12] = callDelta + putDelta;
                infoToday[13] = options_->getGamma(ATMcall, price_[date], rates_[date]);
                infoToday[14] = options_->getGamma(ATMput, price_[date], rates_[date]);
                infoToday[15] = portfolio_->getStockShares();
                infoToday[16] = callDelta + putDelta + portfolio_->getStockShares() / K / 100;
                infoToday[18] = 0;
                infoToday[19] = portfolio_->getPositionValue(date);
                infoToday[20] = portfolio_->getReturn(date);
                infoToday[21] = portfolio_->getTotalWealth(date);
                if (volGen->isHistorical()){
                    infoToday[22] = ATMcall->getPrice();
                    infoToday[23] = ATMput->getPrice();
                }
                break;
            }
            case holdP: {
                //re-balance
                Real rret = 0;
                //update option
                std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> > portOptions = portfolio_->getOptions();
                boost::shared_ptr<RawOption> callToday = options_->updatePrice(portOptions[0].first, date);
                boost::shared_ptr<RawOption> putToday = options_->updatePrice(portOptions[1].first, date);

                Real callDelta = options_->getDelta(callToday, price_[date], rates_[date]);
                Real putDelta = options_->getDelta(putToday, price_[date], rates_[date]);

                Real preDelta = 1.0 * portfolio_->getStockShares() / K / 100;
                Real numShares = 0;
//                std::cout << "total delta = " << std::abs(callDelta + putDelta + preDelta) << " " << deltaT_ << std::endl;
                if (std::abs(callDelta + putDelta + preDelta) <= deltaT_ || callDelta == 0 || putDelta == 0){
                    //do nothing
                }
                else{
                    //trade some stocks
                    numShares = -1.0 * (callDelta + putDelta + preDelta) * 100 * K;
                    rret += portfolio_->tradeStock(numShares, price_[date]);
                }
                //update portfolio
                std::vector<Real> todayPrice;
                todayPrice.push_back(callToday->getPrice());
                todayPrice.push_back(putToday->getPrice());
                portfolio_->updateValue(date, price_[date], todayPrice);

                infoToday[4] = callToday->getStrike();
                infoToday[5] = calendar.businessDaysBetween(date, callToday->getExpDate(), true, true);
                infoToday[6] = callToday->getPrice();
                infoToday[7] = putToday->getPrice();
                infoToday[8] = options_->getImpliedVol(callToday, price_[date], rates_[date]);
                infoToday[9] = options_->getImpliedVol(putToday, price_[date], rates_[date]);
                infoToday[10] = callDelta;
                infoToday[11] = putDelta;
                infoToday[12] = callDelta + putDelta;
                infoToday[13] = options_->getGamma(callToday, price_[date], rates_[date]);
                infoToday[14] = options_->getGamma(putToday, price_[date], rates_[date]);
                infoToday[15] = portfolio_->getStockShares();
                infoToday[16] = callDelta + putDelta + portfolio_->getStockShares() / K / 100.0;
                infoToday[18] = rret;
                infoToday[19] = portfolio_->getPositionValue(date);
                infoToday[20] = portfolio_->getReturn(date);
                infoToday[21] = portfolio_->getTotalWealth(date);
                if (volGen->isHistorical()){
                    infoToday[22] = options_->getATM(date, Option::Call, price_[date], tmin_, tmax_)->getPrice();
                    infoToday[23] = options_->getATM(date, Option::Put, price_[date], tmin_, tmax_)->getPrice();
                }

                break;
            }
            case closeP:{
                //close position
                Real rret = 0;
                //update option data
                std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> > portOptions = portfolio_->getOptions();
                boost::shared_ptr<RawOption> callToday = options_->updatePrice(portOptions[0].first, date);
                boost::shared_ptr<RawOption> putToday = options_->updatePrice(portOptions[1].first, date);

                //sell options
                rret += portfolio_->tradeOption(callToday, -K, callToday->getPrice());
                rret += portfolio_->tradeOption(putToday, -K, putToday->getPrice());
                //sell stocks
                rret += portfolio_->tradeStock(-portfolio_->getStockShares(), price_[date]);
                //update portfolio
                std::vector<Real> todayPrice;
                todayPrice.push_back(callToday->getPrice());
                todayPrice.push_back(putToday->getPrice());
                portfolio_->updateValue(date, price_[date], todayPrice);

                infoToday[4] = callToday->getStrike();
                infoToday[5] = calendar.businessDaysBetween(date, callToday->getExpDate(), true, true);
                infoToday[6] = callToday->getPrice();
                infoToday[7] = putToday->getPrice();
                infoToday[8] = options_->getImpliedVol(callToday, price_[date], rates_[date]);
                infoToday[9] = options_->getImpliedVol(putToday, price_[date], rates_[date]);
                infoToday[10] = 0;
                infoToday[11] = 0;
                infoToday[12] = 0;
                infoToday[13] = options_->getGamma(callToday, price_[date], rates_[date]);
                infoToday[14] = options_->getGamma(putToday, price_[date], rates_[date]);
                infoToday[15] = 0;
                infoToday[16] = 0;
                infoToday[18] = rret;
                infoToday[19] = portfolio_->getPositionValue(date);
                infoToday[20] = portfolio_->getReturn(date);
                infoToday[21] = portfolio_->getTotalWealth(date);
                if (volGen->isHistorical()){
                    infoToday[22] = options_->getATM(date, Option::Call, price_[date], tmin_, tmax_)->getPrice();
                    infoToday[23] = options_->getATM(date, Option::Put, price_[date], tmin_, tmax_)->getPrice();
                }

                break;
            }
            default:{
                //do nothing
                portfolio_->updateValue(date);
                infoToday[21] = portfolio_->getTotalWealth(date);
                if (volGen->isHistorical()){
                    infoToday[22] = options_->getATM(date, Option::Call, price_[date], tmin_, tmax_)->getPrice();
                    infoToday[23] = options_->getATM(date, Option::Put, price_[date], tmin_, tmax_)->getPrice();
                }
                break;
            }
        }
        info.push_back(infoToday);
        dates.push_back(date);
    }

    //last day
    Signal signal = (*gen_)(endDate);
    std::vector<Real> infoToday;
    infoToday.resize(24);
    infoToday[0] = price_[endDate];
    infoToday[1] = volGen->getVol(endDate);
    infoToday[2] = volGen->getMAvol(endDate);
    infoToday[3] = signal;
    infoToday[17] = signal;

    if (signal == holdP){
        //close position
        Real rret = 0;
        //update option data
        std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> > portOptions = portfolio_->getOptions();
        boost::shared_ptr<RawOption> callToday = options_->updatePrice(portOptions[0].first, endDate);
        boost::shared_ptr<RawOption> putToday = options_->updatePrice(portOptions[1].first, endDate);
        //sell options
        rret += portfolio_->tradeOption(callToday, -K, callToday->getPrice());
        rret += portfolio_->tradeOption(putToday, -K, putToday->getPrice());
        //sell stocks
        rret += portfolio_->tradeStock(-portfolio_->getStockShares(), price_[endDate]);

        //update portfolio
        std::vector<Real> todayPrice;
        todayPrice.push_back(callToday->getPrice());
        todayPrice.push_back(putToday->getPrice());
        portfolio_->updateValue(endDate, price_[endDate], todayPrice);

        infoToday[4] = callToday->getStrike();
        infoToday[5] = calendar.businessDaysBetween(endDate, callToday->getExpDate(), true, true);
        infoToday[6] = callToday->getPrice();
        infoToday[7] = putToday->getPrice();
        infoToday[8] = options_->getImpliedVol(callToday, price_[endDate], rates_[endDate]);
        infoToday[9] = options_->getImpliedVol(putToday, price_[endDate], rates_[endDate]);
        infoToday[10] = 0;
        infoToday[11] = 0;
        infoToday[12] = 0;
        infoToday[13] = options_->getGamma(callToday, price_[endDate], rates_[endDate]);
        infoToday[14] = options_->getGamma(putToday, price_[endDate], rates_[endDate]);
        infoToday[15] = 0;
        infoToday[16] = 0;
        infoToday[18] = rret;
        infoToday[19] = portfolio_->getPositionValue(endDate);
        infoToday[20] = portfolio_->getReturn(endDate);
        infoToday[21] = portfolio_->getTotalWealth(endDate);
        if (volGen->isHistorical()){
            infoToday[22] = options_->getATM(endDate, Option::Call, price_[endDate], tmin_, tmax_)->getPrice();
            infoToday[23] = options_->getATM(endDate, Option::Put, price_[endDate], tmin_, tmax_)->getPrice();
        }
    }
    else{
        //do nothing
        portfolio_->updateValue(endDate);
    }
    info.push_back(infoToday);
    dates.push_back(endDate);

    info_ = TimeSeries<std::vector<Real> >(dates.begin(), dates.end(), info.begin());

    return portfolio_->getTsValue();
}

void GammaScalping::write2csv(std::string filename) const{
    std::ofstream fout;
    fout.open(filename.c_str());

    fout << "date,underlying price,sigma_t,MV_sigma,signal,strike price,time to expiration,";
    fout << "call price,put price,call IV,putIV,call delta,put delta,call delta + put delta,";
    fout << "call gamma,put gamma,stock shares,position delta,action,realized return,position total value,return,total wealth,";
    fout << "ATM call price,ATM put price" << std::endl;

    for (TimeSeries<std::vector<Real> >::const_iterator k = info_.begin(); k != info_.end(); ++k){
        fout << k->first.year() << "/" << k->first.month() << "/" << k->first.dayOfMonth() << ",";
        for (int i = 0; i < k->second.size(); ++i){
            fout<< k->second[i] <<",";
        }
        fout << std::endl;
    }
    fout.close();
}
