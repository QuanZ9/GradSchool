#include "CsvParser.h"
#include <iostream>
#include <StockData.h>
#include <stdlib.h>
#include <fstream>

CsvParser::CsvParser()
{
    //ctor
}

CsvParser::~CsvParser()
{
    //dtor
}

void CsvParser::parse(string filename, int headerSize, vector<StockData>& data)
{
    ifstream infile;
    infile.open(filename.c_str());
    if (!infile)
    {
        cout << "error! file does not exist!"<<endl;
    }

    string temp;
    //get header
    for (int i = 0; i < headerSize; ++i)
    {
        getline(infile, temp);
    }

    string date;
    double value;
    while (getline(infile, temp))
    {
        int dot = temp.find(",");
        date = temp.substr(0, dot);
        value = atof(temp.substr(dot + 1, temp.length() - 1).c_str());
        data.push_back(StockData(date, value));
    }

    infile.close();

}
