#ifndef UTIL_H
#define UTIL_H

#include <fstream>
#include <ql/quantlib.hpp>
#include <boost/algorithm/string.hpp>

using namespace QuantLib;

const Integer BUSINESS_DAY_PER_YEAR = 252;

Date parseDate(std::string date);
void readConfig(std::string filename, int& m, int& w, int& e, double& low, double& high, int& tmin, int& tmax,
                   int& k, double& deltaT, Date& startDateIn, Date& endDateIn, Date& startDateOut, Date& endDateOut, double& initCash, double& transCost,
                   std::string& stockFile, std::string& optionFile, std::string& rfFile, std::string& resultFile, std::string& pfmFile,
                   bool& searchParams, bool& useHistorical);

#endif // UTIL_H
