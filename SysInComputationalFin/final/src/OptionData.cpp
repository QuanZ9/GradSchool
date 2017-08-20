#include "OptionData.h"

Real OptionData::getIVonDate(Date date, Real price, Real rate, Integer tmin, Integer tmax) const{
//    std::cout << "solving volatility on day " << date << std::endl;

    boost::shared_ptr<RawOption> call = getATM(date, Option::Call, price, tmin, tmax);
    boost::shared_ptr<RawOption> put = getATM(date, Option::Put, price, tmin, tmax);

    if (call->getExpDate() != put->getExpDate()){
        std::cout << "different expiry date for ATM call & put !!!" << std::endl;
    }

    Real callVol = getImpliedVol(call, price, rate);
//    std::cout << "call vol = " << callVol << std::endl;
    Real putVol = getImpliedVol(put, price, rate);
//    std::cout << "put vol = " << putVol << std::endl;

    return (callVol + putVol) / 2;
}


Real OptionData::getImpliedVol(boost::shared_ptr<RawOption> option, Real price, Real rate) const{
    Date today_date = option->getDate();
    Settings::instance().evaluationDate() = today_date;
    Calendar calendar = UnitedStates(UnitedStates::NYSE);     // US calendar
    DayCounter dayCounter = Business252();  //252 business days in a year

    // S0 handle
    Handle<Quote> S_handle(boost::shared_ptr<Quote>(new SimpleQuote(price)));
    // interest rate term structure handle
    Handle<YieldTermStructure> r_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,rate,dayCounter)));
    // Dividend handle
    Handle<YieldTermStructure> q_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,0,dayCounter)));
    // Volatility RelinkableHandle, because we need to change implied volatility later
    RelinkableHandle<Quote> vol_h(boost::shared_ptr<Quote>(new SimpleQuote(0.02)));    //0.02 is initial guess
    Handle<BlackVolTermStructure> vol_handle(boost::shared_ptr<BlackVolTermStructure>(new BlackConstantVol(today_date,calendar,vol_h,dayCounter)));

    //construct VanillaOption
    Date maturity = option->getExpDate();      // expiration date
    boost::shared_ptr<EuropeanExercise> exer(new EuropeanExercise(maturity));
    boost::shared_ptr<PlainVanillaPayoff> payc(new PlainVanillaPayoff(option->getType(),option->getStrike()));
    boost::shared_ptr<VanillaOption> this_option (new VanillaOption(payc,exer));

    // Black Scholes Merton Process
    boost::shared_ptr<BlackScholesMertonProcess> bsmProcess(new BlackScholesMertonProcess(S_handle,q_handle,r_handle,vol_handle));

    // Calculate implied Volatility
    Volatility iv = 0;
    try{
        iv = this_option->impliedVolatility(option->getPrice(), bsmProcess);

    } catch(Error& e){
//        std::cout << "<option IV> "<< e.what() << std::endl;
//        std::cout << price << " " << rate << " " << option->getDate() << " " << option->getType() << " " << option->getExpDate() << " " << option->getStrike() << " " << option->getPrice() << std::endl;
//        std::cout << calendar.businessDaysBetween(option->getDate(), option->getExpDate()) << std::endl;
        return 0;
    }

    // Update implied Volatility in the BS model
    vol_h.linkTo(boost::shared_ptr<Quote>(new SimpleQuote(iv)));

    // Set up Engine, here bsmProcess's volatility is changed
    this_option->setPricingEngine(boost::shared_ptr<PricingEngine>(new AnalyticEuropeanEngine(bsmProcess)));
    return iv;
}

boost::shared_ptr<RawOption> OptionData::getATM(Date d, Option::Type type, Real price, Integer tmin, Integer tmax) const{
//    std::cout << "get ATM   " << d << " " << type << " " << price << " " << tmin << " " << tmax << std::endl;
    boost::shared_ptr<RawOption> atm;
    double priceDif = 9999999999; // difference between underlying price and strike price
    Date currentExp;
    double currentT = -1;
    for (int i = 0; i < data_.size(); ++i){
//        std::cout << "check ---   " << data_[i]->getDate() << " " << data_[i]->getExpDate() << " " << data_[i]->getStrike() << std::endl;

        //check current date
        if (data_[i]->getDate() < d){
            continue;
        }
        if (data_[i]->getDate() > d){
            break;
        }

        //check expiry date
        Calendar calendar = UnitedStates(UnitedStates::NYSE);
        Integer t = calendar.businessDaysBetween(d, data_[i]->getExpDate(), true, true);
        if (t > tmin){
//            std::cout <<" t > tmin" << std::endl;
            if (currentT == -1){
                currentT = t;
            }
            if (currentT != t){
                break;
            }

            if (data_[i]->getType() != type){
//                std::cout <<" type not match" << std::endl;
                continue;
            }
            if (std::abs(data_[i]->getStrike() - price) < priceDif){
//                std::cout <<" update atm " << std::endl;
                priceDif = std::abs(data_[i]->getStrike() - price);
                currentExp = data_[i]->getExpDate();
                atm = data_[i];
            }
        }
        if (t > tmax){
            break;
        }
    }
    if (!atm){
        std::cout << "can't find atm option!!!" << std::endl;
    }
//    std::cout << "!!!get ATM   " << atm->getDate() << " " << atm->getExpDate() << " " << atm->getStrike() << std::endl;
    return atm;
}

Real OptionData::getDelta(boost::shared_ptr<RawOption> option, Real price, Real rate) const{
    Date today_date = option->getDate();
    Settings::instance().evaluationDate() = today_date;
    Calendar calendar = UnitedStates(UnitedStates::NYSE);     // US calendar
    DayCounter dayCounter = Business252();  //252 business days in a year

    // S0 handle
    Handle<Quote> S_handle(boost::shared_ptr<Quote>(new SimpleQuote(price)));
    // interest rate term structure handle
    Handle<YieldTermStructure> r_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,rate,dayCounter)));
    // Dividend handle
    Handle<YieldTermStructure> q_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,0,dayCounter)));
    // Volatility RelinkableHandle, because we need to change implied volatility later
    RelinkableHandle<Quote> vol_h(boost::shared_ptr<Quote>(new SimpleQuote(0.02)));    //0.02 is initial guess
    Handle<BlackVolTermStructure> vol_handle(boost::shared_ptr<BlackVolTermStructure>(new BlackConstantVol(today_date,calendar,vol_h,dayCounter)));

    //construct VanillaOption
    Date maturity = option->getExpDate();      // expiration date
    boost::shared_ptr<EuropeanExercise> exer(new EuropeanExercise(maturity));
    boost::shared_ptr<PlainVanillaPayoff> payc(new PlainVanillaPayoff(option->getType(),option->getStrike()));
    boost::shared_ptr<VanillaOption> this_option (new VanillaOption(payc,exer));

    // Black Scholes Merton Process
    boost::shared_ptr<BlackScholesMertonProcess> bsmProcess(new BlackScholesMertonProcess(S_handle,q_handle,r_handle,vol_handle));

    // Calculate implied Volatility
    Volatility iv = 0;
    try{
        iv = this_option->impliedVolatility(option->getPrice(), bsmProcess);
    } catch(Error& e){
//        std::cout << "<option delta> " << e.what() << std::endl;
//        std::cout << price << " " << rate << " " << option->getDate() << " " << option->getType() << " " << option->getExpDate() << " " << option->getStrike() << " " << option->getPrice() << std::endl;
//        std::cout << calendar.businessDaysBetween(option->getDate(), option->getExpDate()) << std::endl;
        return 0;
    }
    // Update implied Volatility in the BS model
    vol_h.linkTo(boost::shared_ptr<Quote>(new SimpleQuote(iv)));
    // Set up Engine, here bsmProcess's volatility is changed
    this_option->setPricingEngine(boost::shared_ptr<PricingEngine>(new AnalyticEuropeanEngine(bsmProcess)));
    return this_option->delta();
}

Real OptionData::getGamma(boost::shared_ptr<RawOption> option, Real price, Real rate) const{
    Date today_date = option->getDate();
    Settings::instance().evaluationDate() = today_date;
    Calendar calendar = UnitedStates(UnitedStates::NYSE);     // US calendar
    DayCounter dayCounter = Business252();  //252 business days in a year

    // S0 handle
    Handle<Quote> S_handle(boost::shared_ptr<Quote>(new SimpleQuote(price)));
    // interest rate term structure handle
    Handle<YieldTermStructure> r_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,rate,dayCounter)));
    // Dividend handle
    Handle<YieldTermStructure> q_handle(boost::shared_ptr<YieldTermStructure>(new FlatForward(today_date,0,dayCounter)));
    // Volatility RelinkableHandle, because we need to change implied volatility later
    RelinkableHandle<Quote> vol_h(boost::shared_ptr<Quote>(new SimpleQuote(0.02)));    //0.02 is initial guess
    Handle<BlackVolTermStructure> vol_handle(boost::shared_ptr<BlackVolTermStructure>(new BlackConstantVol(today_date,calendar,vol_h,dayCounter)));

    //construct VanillaOption
    Date maturity = option->getExpDate();      // expiration date
    boost::shared_ptr<EuropeanExercise> exer(new EuropeanExercise(maturity));
    boost::shared_ptr<PlainVanillaPayoff> payc(new PlainVanillaPayoff(option->getType(),option->getStrike()));
    boost::shared_ptr<VanillaOption> this_option (new VanillaOption(payc,exer));

    // Black Scholes Merton Process
    boost::shared_ptr<BlackScholesMertonProcess> bsmProcess(new BlackScholesMertonProcess(S_handle,q_handle,r_handle,vol_handle));

    // Calculate implied Volatility
    Volatility iv = 0;
    try{
        iv = this_option->impliedVolatility(option->getPrice(), bsmProcess);
    } catch(Error& e){
//        std::cout<< "<option gamma> " << e.what() << std::endl;
        return 0;
    }
    // Update implied Volatility in the BS model
    vol_h.linkTo(boost::shared_ptr<Quote>(new SimpleQuote(iv)));
    // Set up Engine, here bsmProcess's volatility is changed
    this_option->setPricingEngine(boost::shared_ptr<PricingEngine>(new AnalyticEuropeanEngine(bsmProcess)));
    return this_option->gamma();
}

boost::shared_ptr<RawOption> OptionData::updatePrice(boost::shared_ptr<RawOption> option, Date d) const{
    for (int i = 0; i < data_.size(); ++i){
        if (data_[i]->getDate() == d && data_[i]->equals(option)){
//            std::cout << "new price of option " << option->getExpDate() << " " << option->getStrike() << " on " << d << " is " << data_[i]->getPrice() << std::endl;
            return data_[i];
        }
    }
    std::cout << "can'f find price for option " << option->getType() << " " <<option->getDate() << " " << option->getExpDate() << " " << option->getStrike() << std::endl;
    std::cout << "on " << d << std::endl << std::endl;
    return boost::shared_ptr<RawOption>();
}

void OptionData::add(boost::shared_ptr<RawOption> option){
    data_.push_back(option);
}
