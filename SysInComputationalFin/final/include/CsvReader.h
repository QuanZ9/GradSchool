#ifndef CSVREADER_H
#define CSVREADER_H

#include <ql/quantlib.hpp>
#include <stdio.h>
#include <fstream>
#include "OptionData.h"
#include "Util.h"

using namespace QuantLib;

class CsvReader
{
    public:
        CsvReader(std::string stockFile, std::string optionFile, std::string rfFile);
        virtual ~CsvReader();
        TimeSeries<Real> readStock(Date startDate, Date endDate, Integer pre = 0);
        TimeSeries<Real> readRf(Date startDate, Date endDate);
        boost::shared_ptr<OptionData> readOption(Date startDate, Date endDate);

    private:
        std::string stockFile_;
        std::string optionFile_;
        std::string rfFile_;
};

#endif // CSVREADER_H
