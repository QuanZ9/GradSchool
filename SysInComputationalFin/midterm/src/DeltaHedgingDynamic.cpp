#include "DeltaHedgingDynamic.h"
#include <boost/algorithm/string.hpp>
#include <fstream>

DeltaHedgingDynamic::DeltaHedgingDynamic(Option::Type type,
                         Real strike,
                         Date expDate,
                         Date startDate,
                         Date endDate,
                         Real startCash,
                         std::string rateFile,
                         std::string volFile,
                         std::string outFile = "")
        : DeltaHedging(type, strike, 0.24, getTime(startDate, expDate), getNTimeStep(startDate, endDate), 0.025, startCash, outFile),
          expDate_(expDate),
          startDate_(startDate),
          endDate_(endDate),
          rates_(new MyPath(getNTimeStep(startDate, endDate))),
          vols_(new MyPath(getNTimeStep(startDate, endDate))){
    timePeriod_ = getTime(startDate, endDate);
    readRateFile(rateFile);
    readOptionFile(volFile);
    std::vector<Date> initDates;
    Calendar calendar = UnitedStates();
    for (Date d = startDate; d <= endDate; d++){
        if (calendar.isBusinessDay(d)){
            initDates.push_back(d);
        }
    }
    optionPrices_->setDates(initDates);
    deltas_->setDates(initDates);
    hedgingErrors_->setDates(initDates);
}

Size DeltaHedgingDynamic::getNTimeStep(Date startDate, Date endDate) const{
    Calendar calendar = UnitedStates();
    return calendar.businessDaysBetween(startDate, endDate, true, true);
}

Time DeltaHedgingDynamic::getTime(Date startDate, Date endDate) const{
    Calendar calendar = UnitedStates();
    return calendar.businessDaysBetween(startDate, endDate)*1.0 / BUSINESS_DAY_PER_YEAR;
}

void DeltaHedgingDynamic::readRateFile(std::string filename){
    std::ifstream infile;
    infile.open(filename.c_str());
    if (!infile){
        std::cout << "File " << filename << "does not exist!!!" << std::endl;
        return;
    }

    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<std::string> tempv;

    Calendar calendar = UnitedStates();
    Integer nStep = calendar.businessDaysBetween(startDate_, endDate_, true, true);
    boost::shared_ptr<MyPath> path(new MyPath(nStep));

    //skip the header
    getline(infile, temp);
    int index = 0;
    while (getline(infile, temp)){
        boost::split(tempv, temp, boost::is_any_of(","));

        Date d = parseDate(tempv[0]);
        if (d >= startDate_ && d <= endDate_){
            dates.push_back(d);
            path->value(index++) = atof(tempv[1].c_str()) / 100.0;
        }
        if (d > endDate_){
            break;
        }
    }
    infile.close();

    path->setDates(dates);

    rates_ = path;
}

void DeltaHedgingDynamic::readOptionFile(std::string filename){
    std::ifstream infile;
    infile.open(filename.c_str());
    if (!infile){
        std::cout << "File " << filename << "does not exist!!!" << std::endl;
        return;
    }
    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<Real> impliedVols;
    std::vector<std::string> tempv;

    Calendar calendar = UnitedStates();
    Integer nStep = calendar.businessDaysBetween(startDate_, endDate_, true, true);
    boost::shared_ptr<MyPath> vols(new MyPath(nStep));
    boost::shared_ptr<MyPath> options(new MyPath(nStep));

    //skip the header
    getline(infile, temp);
    int index = 0;
    while (getline(infile, temp)){
        boost::split(tempv, temp, boost::is_any_of(","));

        Date d = parseDate(tempv[0]);
        if (d < startDate_){
            continue;
        }
        if (d > endDate_){
            break;
        }

        Date exp = parseDate(tempv[1]);
        Real k = atof(tempv[3].c_str());
        Real price = (atof(tempv[4].c_str()) + atof(tempv[5].c_str())) / 2.0;

        Option::Type thisType;
        if (tempv[2] == "C"){
            thisType = Option::Call;
        }
        else if (tempv[2] == "P"){
            thisType = Option::Put;
        }
        else{
            std::cout << "unknown option type in file !!!" << std::endl;
        }

        if (thisType == type_ && exp == expDate_ && abs(k - strike_) < 0.001){
            dates.push_back(d);
            options->value(index++) = price;

            Date maturity = expDate_;      // expiration date
            boost::shared_ptr<EuropeanExercise> exer(new EuropeanExercise(maturity));
            boost::shared_ptr<PlainVanillaPayoff> payc(new PlainVanillaPayoff(type_,strike_));
            boost::shared_ptr<VanillaOption> call_option (new VanillaOption(payc,exer));

            options_.push_back(call_option);
        }
    }
    infile.close();

    vols->setDates(dates);
    vols_ = vols;

    options->setDates(dates);
    optionPrices_ = options;
}


Rate DeltaHedgingDynamic::getRate(Date d) const{
    return rates_->getValue(d);
}

Volatility DeltaHedgingDynamic::getVol(Date d, Real stockPrice) const{
    Date today_date = d;
    Settings::instance().evaluationDate() = today_date;
    Calendar calendar = UnitedStates();     // US calendar
    DayCounter dayCounter = Business252();  //252 business days in a year

    // S0 handle
    Handle<Quote> S_handle(boost::shared_ptr<Quote>(new SimpleQuote(stockPrice)));
    // interest rate term structure handle
    Handle<YieldTermStructure> r_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,getRate(d),dayCounter)));
    // Dividend handle
    Handle<YieldTermStructure> q_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,0,dayCounter)));
    // Volatility RelinkableHandle, because we need to change implied volatility later
    RelinkableHandle<Quote> vol_h(boost::shared_ptr<Quote>(new SimpleQuote(0.02)));    //0.02 is initial guess
    Handle<BlackVolTermStructure> vol_handle(boost::shared_ptr<BlackVolTermStructure>(new BlackConstantVol(today_date,calendar,vol_h,dayCounter)));

    // Black Scholes Merton Process
    boost::shared_ptr<BlackScholesMertonProcess> bsmProcess(new BlackScholesMertonProcess(S_handle,q_handle,r_handle,vol_handle));
    boost::shared_ptr<VanillaOption> call_option = options_[optionPrices_->getIndex(d)];
    // Calculate implied Volatility

    Volatility iv = call_option->impliedVolatility(optionPrices_->getValue(d), bsmProcess);
    // Update implied Volatility in the BS model
    vol_h.linkTo(boost::shared_ptr<Quote>(new SimpleQuote(iv)));
    // Set up Engine, here bsmProcess's volatility is changed
    call_option->setPricingEngine(boost::shared_ptr<PricingEngine>(new AnalyticEuropeanEngine(bsmProcess)));
    vols_->value(optionPrices_->getIndex(d)) = iv;
    return iv;
}

Time DeltaHedgingDynamic::getTimeToExp(Integer i, Time dt) const{
    Calendar calendar = UnitedStates();
    Date d = optionPrices_->getDate(i);
    return getTime(d, expDate_);
}

Real DeltaHedgingDynamic::getOptionPrice(const BlackCalculator& bs, Date d) const{
    return optionPrices_->getValue(d);
}

void DeltaHedgingDynamic::writeToCsv(const MyPath& path) const{
    std::ofstream outFile(outFile_.c_str());
    Real cumError = 0;
    Real wealth = 0;
    Real wealthNH = startCash_;
    outFile << "date,S,V,ImpliedVolatility,Delta,HedgingError,CumulativeHedgingError,Wealth,WealthNoHedge" << std::endl;
    for (int i = 0; i < optionPrices_->length(); ++i){
        cumError += hedgingErrors_->value(i);
        wealth = cash_->value(i) + deltas_->value(i) * path.value(i) - optionPrices_->value(i);
        outFile << optionPrices_->getDate(i).year() <<"/"
                    << optionPrices_->getDate(i).month() << "/"
                    << optionPrices_->getDate(i).dayOfMonth()<< ","
                << path.value(i) << ","
                << optionPrices_->value(i) << ","
                << vols_->value(i) << ","
                << deltas_->value(i) << ","
                << hedgingErrors_->value(i) << ","
                << cumError << ","
                << wealth << ","
                << wealthNH + optionPrices_->value(0) - optionPrices_->value(i)<< std::endl;
        wealthNH = wealthNH * std::exp(rates_->value(0));
    }
    outFile.close();
}
