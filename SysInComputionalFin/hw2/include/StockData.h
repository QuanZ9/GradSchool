#ifndef STOCKDATA_H
#define STOCKDATA_H
#include <Date.h>
#include <iostream>


class StockData
{
public:
    StockData(string date, double price) : date_(Date(date)), price_(price) {};
    virtual ~StockData() {};

    Date getDate()
    {
        return date_;
    }

    double getPrice()
    {
        return price_;
    }


private:
    Date date_;
    double price_;
};

#endif // STOCKDATA_H
