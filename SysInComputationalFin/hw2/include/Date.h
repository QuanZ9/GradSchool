#include<string>
using namespace std;

#ifndef DATE_H
#define DATE_H

enum DateType
{
    YYYYMMDD = 1,
    MMDDYYYY = 2,
    OTHER = 3
};


class Date
{
public:
    Date(string s);
    virtual ~Date() {};
    virtual bool operator < (Date date2);
    virtual bool operator > (Date date2);

public:
    int year;
    int month;
    int day;
    DateType type;

};

#endif // DATE_H
