#include "../include/DeltaHedging.h"

DeltaHedging::DeltaHedging(Option::Type type,
                         Real strike,
                         Volatility vol,
                         Time T,
                         Size nTimeSteps,
                         Rate r,
                         Real startCash,
                         std::string outFile)
        : type_(type),
          strike_(strike),
          vol_(vol),
          T_(T),
          r_(r),
          timePeriod_(T),
          startCash_(startCash),
          outFile_(outFile),
          optionPrices_(new MyPath<Real>(nTimeSteps)),
          deltas_(new MyPath<Real> (nTimeSteps)),
          hedgingErrors_(new MyPath<Real>(nTimeSteps)),
          cash_(new MyPath<Real>(nTimeSteps)){
}

DeltaHedging::~DeltaHedging()
{
    //dtor
}

Real DeltaHedging::operator()(const MyPath<Real>& path) const {
    Size n = path.length() - 1;
    QL_REQUIRE(n>0, "the path cannot be empty");
    // discrete hedging interval
    Time dt = timePeriod_/n;
    Rate stockDividendYield = 0.0;

    Time t = 0;
    // stock value at t=0
    Real stock = path.value(0);
    // money account at t=0
    Real money_account = startCash_;
    Real hedgingError = 0.0;
    /************************/
    /*** the initial deal ***/
    /************************/
    // option fair price (Black-Scholes) at t=0
    DiscountFactor rDiscount = std::exp(-getRate(path.getDate(0)) * getTimeToExp(0, dt));
    DiscountFactor qDiscount = std::exp(-stockDividendYield*T_);
    Real forward = stock*qDiscount/rDiscount;
    Real vol = getVol(path.getDate(0), stock);
    Real stdDev = std::sqrt(vol * vol * getTimeToExp(0, dt));
    Real spotError = 0.0;
    boost::shared_ptr<StrikedTypePayoff> payoff(
                                       new PlainVanillaPayoff(type_,strike_));
    BlackCalculator black(payoff,forward,stdDev,rDiscount);
    // sell the option, cash in its premium
    money_account += getOptionPrice(black, path.getDate(0));
    // compute delta
    Real delta = black.delta(stock);
    deltas_->value(0) = delta;
    hedgingErrors_->value(0) = spotError;
    // delta-hedge the option buying stock
    Real stockAmount = delta;
    money_account -= stockAmount*stock;
    cash_->value(0) = money_account;

    //bs model option price
    Real optionPrice = getOptionPrice(black, path.getDate(0));
    optionPrices_->value(0) = optionPrice;
    bool endAtExp = false;
    /**********************************/
    /*** hedging during option life ***/
    /**********************************/
    for (Size step = 0; step < n; step++){
        if (step < n - 1 && getTimeToExp(step + 2, dt) == 0){
            endAtExp = true;
            break;
        }
        // time flows
        t += dt;
        // accruing on the money account
        money_account *= std::exp( getRate(path.getDate(step))* dt );
        // stock growth:
        stock = path.value(step+1);

        spotError = delta * stock +
                    std::exp(getRate(path.getDate(step)) * dt) *
                    (optionPrice - delta * path.value(step));

        // recalculate option value at the current stock value,
        // and the current time to maturity

        rDiscount = std::exp(-getRate(path.getDate(step+1))*getTimeToExp(step + 1, dt));
        qDiscount = std::exp(-stockDividendYield*getTimeToExp(step + 1, dt));
        forward = stock*qDiscount/rDiscount;
        vol = getVol(path.getDate(step+1), stock);
        stdDev = std::sqrt(vol * vol *getTimeToExp(step + 1, dt));
        BlackCalculator black(payoff,forward,stdDev,rDiscount);
        // recalculate delta
        delta = black.delta(stock);
        deltas_->value(step + 1) = delta;

        optionPrice = getOptionPrice(black, path.getDate(step + 1));
        optionPrices_->value(step + 1) = optionPrice;

        spotError -= optionPrice;
        hedgingErrors_->value(step + 1) = spotError;
        hedgingError += spotError;

        //std::cout << "cumulative hedging error = " << hedgingError << std::endl;
        // re-hedging
        money_account -= (delta - stockAmount)*stock;
        cash_->value(step + 1) = money_account;
        //std::cout << "money : " << money_account << std::endl;
        stockAmount = delta;
    }
    /**************************/
    /*** end day of hedging ***/
    /**************************/
    if (endAtExp){
        std::cout << "Hedging ends at Expiry Date!!!" << std::endl;
        // last accrual on my money account
        money_account *= std::exp(getRate(path.getDate(n-1))*dt);
        // last stock growth
        stock = path.value(n);
        // the hedger delivers the option payoff to the option holder
        Real optionPayoff = PlainVanillaPayoff(type_, strike_)(stock);
        optionPrices_->value(n) = optionPayoff;
        money_account -= optionPayoff;
        hedgingError += delta * path.value(n) +
                        std::exp(getRate(path.getDate(n-1)) * dt) *
                        (optionPrice - delta * path.value(n-1))
                        - optionPayoff;
        // and unwinds the hedge selling his stock position
        money_account += stockAmount*stock;
        cash_->value(n) = money_account;
    }

    if (outFile_ != ""){
        writeToCsv(path);
    }
    return hedgingError;
}

boost::shared_ptr<MyPath<Real> > DeltaHedging::getOptionPrices(){
    return optionPrices_;
}

boost::shared_ptr<MyPath<Real> > DeltaHedging::getDeltas(){
    return deltas_;
}

boost::shared_ptr<MyPath<Real> > DeltaHedging::getHedgingErrors(){
    return hedgingErrors_;
}

boost::shared_ptr<MyPath<Real> > DeltaHedging::getCash(){
    return cash_;
}


Rate DeltaHedging::getRate(Date date) const{
    return r_;

}

Volatility DeltaHedging::getVol(Date date, Real stockPrice) const{
    return vol_;

}

Time DeltaHedging::getTimeToExp(Integer i, Time dt) const{
    return T_ - dt * i;
}

Real DeltaHedging::getOptionPrice(const BlackCalculator& bs, Date d) const{
    return bs.value();
}

void DeltaHedging::writeToCsv(const MyPath<Real> & path) const{
    return;
}

