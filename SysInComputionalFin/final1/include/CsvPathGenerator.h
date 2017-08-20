#ifndef CSVPATHGENERATOR_H
#define CSVPATHGENERATOR_H

#include "MyPathGenerator.h"
#include "MyPath.h"
#include "Util.h"

class CsvPathGenerator : public MyPathGenerator{
    public:
        CsvPathGenerator(std::string filename, Date startDate, Date endDate) : filename_(filename), startDate_(startDate), endDate_(endDate){};
        virtual ~CsvPathGenerator(){};
        virtual boost::shared_ptr<MyPath<Real> > getPath();

    private:
        std::string filename_;
        Date startDate_;
        Date endDate_;
};

#endif // CSVPATHGENERATOR_H
