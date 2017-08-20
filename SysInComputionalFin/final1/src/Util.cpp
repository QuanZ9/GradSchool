#include "Util.h"

Date parseDate(std::string date){
    std::vector<std::string> tempdate;

    boost::split(tempdate, date, boost::is_any_of("-"));
    Year year = (Year) std::atoi(tempdate[0].c_str());
    Month month = (Month) std::atoi(tempdate[1].c_str());
    Day day = (Day) std::atoi(tempdate[2].c_str());
    return Date(day, month, year);
}

void readConfig(std::string filename, Real& strike, Date& expiry, Date& startDate, Date& endDate,
                std::string& stockFile, std::string& optionFile, std::string& rateFile, std::string& outFile){
    std::ifstream infile(filename.c_str());

    if (!infile){
        std::cout << "[Warning] Can't find configuration file " << filename <<"! Use default settings." << std::endl;
        return;
    }

    std::string temp;
    while (infile >> temp){
        if (temp == "StartDate"){
            infile >> temp >> temp;
            startDate = parseDate(temp);
        }
        else if (temp == "EndDate"){
            infile >> temp >> temp;
            endDate = parseDate(temp);
        }
        else if (temp == "ExpiryDate"){
            infile >> temp >> temp;
            expiry = parseDate(temp);
        }
        else if (temp == "StrikePrice"){
            infile >> temp >> temp;
            strike = std::atof(temp.c_str());
        }
        else if (temp == "StockFile"){
            infile >> temp >> temp;
            stockFile = temp;
        }
        else if (temp == "OptionFile"){
            infile >> temp >> temp;
            optionFile = temp;
        }
        else if (temp == "RateFile"){
            infile >> temp >> temp;
            rateFile = temp;
        }
        else if (temp == "OutFile"){
            infile >> temp >> temp;
            outFile = temp;
        }
    }
    infile.close();
}
