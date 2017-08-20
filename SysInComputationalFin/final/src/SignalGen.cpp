#include "SignalGen.h"

VolSignalGen::VolSignalGen(bool type, Real low, Real high, Integer e, Integer w, Integer m = 0)
: useHistorical_(type), position_(false), low_(low), high_(high), e_(e), w_(w), m_(m){
}

void VolSignalGen::setData(CsvReader& reader, TimeSeries<Real>& price,
                            boost::shared_ptr<OptionData> options, TimeSeries<Real>& rates, Real tmin, Real tmax){
    if (useHistorical_){
        historicalSMV_Vol(reader.readStock(rates.firstDate(), rates.lastDate(), w_ + m_ - 2));
    }
    else{
        impliedSMV_Vol(price, options, rates, tmin, tmax);
    }
}

void VolSignalGen::historicalSMV_Vol(TimeSeries<Real> price){
    std::vector<Date> dates;
    std::vector<Real> smvVols;
    std::vector<Real> vols;

    double v = 0;

    //rolling standard deviation
    boost::accumulators::accumulator_set<double, boost::accumulators::stats<boost::accumulators::tag::rolling_variance> >
        stdDev(boost::accumulators::tag::rolling_window::window_size = m_);
    //rolling mean of rolling standard deviation
    boost::accumulators::accumulator_set<double, boost::accumulators::stats<boost::accumulators::tag::rolling_mean> >
        meanStdDev(boost::accumulators::tag::rolling_window::window_size = w_);

    dates.push_back(price.dates()[0]);
    vols.push_back(0);
    smvVols.push_back(0);
    for (int i = 1; i < price.dates().size(); ++i){
        //add price to std acc
        dates.push_back(price.dates()[i]);
        stdDev(log(price.values()[i] / price.values()[i-1]));
//        std::cout << price.dates()[i] << " " << price.values()[i] << " " << price.values()[i-1] << " " << log(price.values()[i] / price.values()[i-1]) << std::endl;
        if (i < m_ - 1){
            vols.push_back(0);
            smvVols.push_back(0);
            continue;
        }
        //add std to smv acc
        v = sqrt(boost::accumulators::rolling_variance(stdDev)) * std::sqrt(252);
        vols.push_back(v);
        meanStdDev(v);
        if (i < m_ + w_ - 2){
            smvVols.push_back(0);
            continue;
        }
        smvVols.push_back(boost::accumulators::rolling_mean(meanStdDev));
//        std::cout << "on " << price.dates()[i] << " historical smv_std = " << smvVols.back() << std::endl;
    }

    smvVol_ = TimeSeries<Real>(dates.begin(), dates.end(), smvVols.begin());
    vols_ = TimeSeries<Real>(dates.begin(), dates.end(), vols.begin());
}

void VolSignalGen::impliedSMV_Vol(TimeSeries<Real>& price, boost::shared_ptr<OptionData> options, TimeSeries<Real>& rates, Real tmin, Real tmax){
    std::vector<Date> dates;
    std::vector<Real> stocks = price.values();
    std::vector<Real> rf = rates.values();
    std::vector<Real> smvVols;
    std::vector<Real> vols;

    //rolling mean of IV
    boost::accumulators::accumulator_set<double, boost::accumulators::stats<boost::accumulators::tag::rolling_mean> >
    meanIV(boost::accumulators::tag::rolling_window::window_size = w_);

    for (int i = 0; i < price.dates().size(); ++i){
        //get ATM call and put option
        Real vol = options->getIVonDate(price.dates()[i], stocks[i], rf[i], tmin, tmax);
        vols.push_back(vol);
        dates.push_back(price.dates()[i]);
        meanIV(vol);
        if (i < w_ - 1){
            smvVols.push_back(0);
            continue;
        }
        smvVols.push_back(boost::accumulators::rolling_mean(meanIV));
//        std::cout<<"on " << price.dates()[i] << " implied vol is " << smvVols.back() << std::endl;
    }
    smvVol_ = TimeSeries<Real>(dates.begin(), dates.end(), smvVols.begin());
    vols_ = TimeSeries<Real>(dates.begin(), dates.end(), vols.begin());
}


Signal VolSignalGen::operator()(Date d){
    if (position_ == false){
        if (smvVol_[d] < low_ && smvVol_[d] > 0.000001){
            position_ = true;
            return enterP;
        }
        else{
            return nothing;
        }
    }
    else{
        Calendar calendar = UnitedStates(UnitedStates::NYSE);
        Integer daysToExp = calendar.businessDaysBetween(d, expiry_, true, true);
        if (smvVol_[d] >= high_ || daysToExp < e_){
            position_ = false;
            return closeP;
        }
        else{
            return holdP;
        }
    }
    return nothing;
}

void VolSignalGen::setExpiry(Date d){
    expiry_ = d;
}
