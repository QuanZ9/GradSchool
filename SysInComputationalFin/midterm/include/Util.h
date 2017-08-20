#ifndef UTIL_H
#define UTIL_H

#include <fstream>
#include <ql/quantlib.hpp>
#include <boost/algorithm/string.hpp>

using namespace QuantLib;

const Integer BUSINESS_DAY_PER_YEAR = 252;

Date parseDate(std::string date);
void readConfig(std::string filename, Real& strike, Date& expiry, Date& startDate, Date& endDate,
                    std::string& stockFile, std::string& optionFile, std::string& rateFile, std::string& outFile);

#endif // UTIL_H
