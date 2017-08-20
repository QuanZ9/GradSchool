#include "CsvReader.h"

CsvReader::CsvReader(std::string stockFile, std::string optionFile, std::string rfFile) :
stockFile_(stockFile), optionFile_(optionFile), rfFile_(rfFile){
}

CsvReader::~CsvReader()
{
    //dtor
}

TimeSeries<Real> CsvReader::readStock(Date startDate, Date endDate, Integer pre){
    std::ifstream infile;
    infile.open(stockFile_.c_str());
    if (!infile){
        std::cout << "File " << stockFile_ << "does not exist!!!" << std::endl;
        return TimeSeries<Real>();
    }

    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<Real> values;
    std::vector<std::string> tempv;
    std::vector<std::string> tempdate;

    Calendar calendar = UnitedStates(UnitedStates::NYSE);

    //skip the header
    getline(infile, temp);
    int index = 0;
    while (getline(infile, temp)){
        boost::split(tempv, temp, boost::is_any_of(","));

        Date d = parseDate(tempv[0]);
        if (calendar.advance(d, pre, Days, BusinessDayConvention(Following), false) >= startDate && d <= endDate){
            //std::cout << d << "days " << calendar.advance(d, pre, Days, BusinessDayConvention(Following), false) << std::endl;
            dates.push_back(d);
            values.push_back(atof(tempv[1].c_str()));
        }

        if (d > endDate){
            break;
        }
    }
    infile.close();

    // Create a QuantLib::TimeSeries object

    QuantLib::TimeSeries<Real> series(dates.begin(), dates.end(), values.begin());

    return series;
}


TimeSeries<Real> CsvReader::readRf(Date startDate, Date endDate){
    std::ifstream infile;
    infile.open(rfFile_.c_str());
    if (!infile){
        std::cout << "File " << rfFile_ << "does not exist!!!" << std::endl;
        return TimeSeries<Real>();
    }

    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<Real> values;
    std::vector<std::string> tempv;
    std::vector<std::string> tempdate;

    //skip the header
    getline(infile, temp);
    int index = 0;
    while (getline(infile, temp)){
        boost::split(tempv, temp, boost::is_any_of(","));

        Date d = parseDate(tempv[0]);
        if (d >= startDate && d <= endDate){
            dates.push_back(d);
            values.push_back(atof(tempv[1].c_str()) / 100);
        }

        if (d > endDate){
            break;
        }
    }
    infile.close();

    // Create a QuantLib::TimeSeries object

    QuantLib::TimeSeries<Real> series(dates.begin(), dates.end(), values.begin());

    return series;
}

boost::shared_ptr<OptionData> CsvReader::readOption(Date startDate, Date endDate){
    boost::shared_ptr<OptionData> options(new OptionData());
    std::ifstream infile;
    infile.open(optionFile_.c_str());
    if (!infile){
        std::cout << "File " << optionFile_ << "does not exist!!!" << std::endl;
        return options;
    }
    // Read the file
    std::string temp;
    std::vector<Date> dates;
    std::vector<Real> impliedVols;
    std::vector<std::string> tempv;

    //skip the header
    getline(infile, temp);
    int index = 0;
    while (getline(infile, temp)){
        boost::split(tempv, temp, boost::is_any_of(","));

        Date d = parseDate(tempv[0]);
        if (d < startDate){
            continue;
        }
        if (d > endDate){
            break;
        }

        Date exp = parseDate(tempv[1]);
        Real k = atof(tempv[3].c_str());
        Real price = (atof(tempv[4].c_str()) + atof(tempv[5].c_str())) / 2.0;

        Option::Type thisType;
        if (tempv[2] == "C"){
            thisType = Option::Call;
        }
        else if (tempv[2] == "P"){
            thisType = Option::Put;
        }
        else{
            std::cout << "unknown option type in file !!!" << std::endl;
        }

        boost::shared_ptr<RawOption> newOption(new RawOption(d, exp, thisType, k, price));
//        std::cout << " push back option " << std::endl;
//        std::cout << newOption->getDate() << " " <<newOption->getExpDate() << " " << newOption->getStrike() << " " << newOption->getPrice()<< std::endl << std::endl;
        options->add(newOption);
    }
    infile.close();
    return options;
}

