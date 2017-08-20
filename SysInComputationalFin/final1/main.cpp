#include <iostream>
#include "DeltaHedging.h"
#include "DeltaHedgingDynamic.h"
#include "GBMPathGenerator.h"
#include "CsvPathGenerator.h"

using namespace std;

int main()
{
    /******************************************************/
    /**  1. Test Delta-Hedging with Black-Scholes Model  **/
    /******************************************************/
    Real mu = 0.05;
    Volatility sigma = 0.24;
    Size nTimeStep = 100;
    Real s0 = 100;
    Time tau = 0.4;
    Real r = 0.025;
    Real strike = 105;
    Size nPath = 2;
    Real startCash = 500;

    GBMPathGenerator pg(s0, mu, sigma, tau, nTimeStep);
    DeltaHedging dh(Option::Call, strike, sigma, tau, nTimeStep, r, startCash);
    boost::shared_ptr<MyPath<Real> > stocks = pg.getPath();
    Real cumError = dh(*stocks);

    boost::shared_ptr<MyPath<Real> > options = dh.getOptionPrices();
    boost::shared_ptr<MyPath<Real> > deltas = dh.getDeltas();
    boost::shared_ptr<MyPath<Real> > errors = dh.getHedgingErrors();

    cout << "--- Problem 1 ---" << endl;
    cout << setw(12) << "time_period" << " | "
                  << setw(12) << "stock_price" << " | "
                  << setw(12) << "option_price" << " | "
                  << setw(12) << "delta" << " | "
                  << setw(12) << "daily_hedging_error"<< endl;

    for (int i = 0; i < options->length(); ++i){
        cout << setw(12) << i << " | "
                  << setw(12) << stocks->value(Size(i)) << " | "
                  << setw(12) << options->value(i) << " | "
                  << setw(12) << deltas->value(i) << " | "
                  << setw(12) << errors->value(i) << endl;
    }
    cout << "cumulative hedging error = " << cumError << endl;
    cout << endl << endl;

    /********************************************************/
    /**  2. read data from .csv and perform delta hedging  **/
    /********************************************************/
    Date startDate(5, July, 2011);
    Date endDate(29, July, 2011);
    Date expDate(17, Sep, 2011);
    strike = 500;

    std::string stockFile("data/sec_GOOG.csv");
    std::string optionFile("data/op_GOOG.csv");
    std::string rateFile("data/interest.csv");
    std::string outFile("result.csv");

    readConfig("config" , strike, expDate, startDate, endDate, stockFile, optionFile, rateFile, outFile);

    CsvPathGenerator csvpg(stockFile, startDate, endDate);

    boost::shared_ptr<MyPath<Real> > stocks_csv = csvpg.getPath();

    DeltaHedgingDynamic dhd(Option::Call, strike, expDate, startDate, endDate, startCash,
                            rateFile, optionFile, outFile);
    cumError = dhd(*stocks_csv);

    cout << "--- Problem 2 --- " << endl;
    cout << "Cumulative hedging error is " << cumError << endl;
    cout << "Result is saved in " << outFile << endl;

    return 0;
}
