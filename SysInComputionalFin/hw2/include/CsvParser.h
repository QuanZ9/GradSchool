#include <StockData.h>
#include <vector>

#ifndef CSVPARSER_H
#define CSVPARSER_H


class CsvParser
{
public:
    CsvParser();
    virtual ~CsvParser();
    void parse(string filename, int headerSize, vector<StockData>& data);

protected:
private:
};


#endif // CSVPARSER_H
