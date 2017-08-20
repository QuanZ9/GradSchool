#include "CsvPathGenerator.h"
#include <fstream>
#include <stdlib.h>
#include <boost/algorithm/string.hpp>

boost::shared_ptr<MyPath> CsvPathGenerator::getPath(){
    std::ifstream infile;
    infile.open(filename_.c_str());
    if (!infile){
        std::cout << "File " << filename_ << "does not exist!!!" << std::endl;
        return boost::shared_ptr<MyPath>();
    }

    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<std::string> tempv;
    std::vector<std::string> tempdate;

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
            path->value(index++) = atof(tempv[1].c_str());
        }

        if (d > endDate_){
            break;
        }
    }
    infile.close();
    path->setDates(dates);
    return path;
}
