#include "Util.h"

Date parseDate(std::string date){
    std::vector<std::string> tempdate;

    boost::split(tempdate, date, boost::is_any_of("-"));
    Year year = (Year) std::atoi(tempdate[0].c_str());
    Month month = (Month) std::atoi(tempdate[1].c_str());
    Day day = (Day) std::atoi(tempdate[2].c_str());

    return Date(day, month, year);
}

void readConfig(std::string filename, int& m, int& w, int& e, double& low, double& high, int& tmin, int& tmax
                   , int& k, double& deltaT, Date& startDateIn, Date& endDateIn, Date& startDateOut, Date& endDateOut, double& initCash, double& transCost,
                   std::string& stockFile, std::string& optionFile, std::string& rfFile, std::string& resultFile, std::string& pfmFile,
                   bool& searchParams, bool& useHistorical){

    std::ifstream infile(filename.c_str());
    if (!infile){
        std::cout << "[Warning] Can't find configuration file " << filename <<"! Use default settings." << std::endl;
        return;
    }
    std::string basePath;
    std::string temp;
    while (infile >> temp){
        if (temp == "Datapath"){
            infile >> temp >> temp;
            basePath = temp;
            rfFile = basePath + "interest.csv";
        }
        else if (temp == "ResultFile"){
            infile >> temp >> temp;
            resultFile = temp;
        }
        else if (temp == "PerformanceFile"){
            infile >> temp >> temp;
            pfmFile = temp;
        }
        else if (temp == "Stock"){
            infile >> temp >> temp;
            stockFile = basePath + "sec_" + temp + ".csv";
            optionFile = basePath + "op_" + temp + ".csv";
        }
        else if (temp == "K"){
            infile >> temp >> temp;
            k = atoi(temp.c_str());
        }
        else if (temp == "SearchParams"){
            infile >> temp >> temp;
            if (temp == "0"){
                searchParams = false;
            }
            else{
                searchParams = true;
            }
        }
        else if (temp == "StartDateIn"){
            infile >> temp >> temp;
            startDateIn = parseDate(temp);
        }
        else if (temp == "EndDateIn"){
            infile >> temp >> temp;
            endDateIn = parseDate(temp);
        }
        else if (temp == "StartDateOut"){
            infile >> temp >> temp;
            startDateOut = parseDate(temp);
        }
        else if (temp == "EndDateOut"){
            infile >> temp >> temp;
            endDateOut = parseDate(temp);
        }
        else if (temp == "SigmaEntry"){
            infile >> temp >> temp;
            low = atof(temp.c_str());
        }
        else if (temp == "SigmaExit"){
            infile >> temp >> temp;
            high = atof(temp.c_str());
        }
        else if (temp == "w"){
            infile >> temp >> temp;
            w = atoi(temp.c_str());
        }
        else if (temp == "m"){
            infile >> temp >> temp;
            m = atoi(temp.c_str());
        }
        else if (temp == "E"){
            infile >> temp >> temp;
            e = atoi(temp.c_str());
        }
        else if (temp == "VolCalculation"){
            infile >> temp >> temp;
            if (temp == "0"){
                useHistorical = true;
            }
            else{
                useHistorical = false;
            }
        }
        else if (temp == "deltaT"){
            infile >> temp >> temp;
            deltaT = atof(temp.c_str());
        }
        else if (temp == "Tmin"){
            infile >> temp >> temp;
            tmin = atoi(temp.c_str());
        }
        else if (temp == "Tmax"){
            infile >> temp >> temp;
            tmax = atoi(temp.c_str());
        }
    }
    infile.close();
}
