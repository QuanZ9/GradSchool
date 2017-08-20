#include <PayoffCallEuro.h>
#include <PayoffPutEuro.h>
#include <PayoffAsian.h>
#include <StockData.h>
#include <CsvParser.h>

#include <iostream>
#include <vector>
using namespace std;

int main()
{
    vector<StockData> prices;
    prices.clear();

    //read csv file and set strike price
    string inputFile = "AAPL_close_2015.csv";
    CsvParser parser;
    parser.parse(inputFile, 1, prices);
    double strikePrice = 105;

    //get stock prices between the day of purchasing the option and the last day of August
    vector<double> spots;
    spots.clear();
    Date buyDay("2015-08-3");
    Date lastDay("2015-08-31");

    for (int i = 0; i < prices.size(); ++i)
    {
        if (!(prices[i].getDate() < buyDay) && !(lastDay < prices[i].getDate()))
        {
            spots.push_back(prices[i].getPrice());
        }
    }

    //compute payoff of the call option
    PayoffAsianCall callAsia(strikePrice);

    cout << "strike price is: " << strikePrice << endl;

    cout << "Payoff of Asian CALL option is " << callAsia(spots) << endl;

    return 0;
}
