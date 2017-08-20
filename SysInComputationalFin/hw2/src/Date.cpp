#include "Date.h"
#include <string>
#include <stdlib.h>
#include <iostream>

using namespace std;

Date::Date(string s)
{
    int p1 = s.find_first_of("-/");
    //yyyy-mm-dd or yyyy/mm/dd
    if (p1 == 4)
    {
        type = YYYYMMDD;
        year = atoi(s.substr(0, 4).c_str());
        month = atoi(s.substr(p1+1, 2).c_str());
        int p2 = s.find_last_of("-/");
        day = atoi(s.substr(p2+1, 2).c_str());
    }
    //mm-dd=yyyy or mm/dd/yyyy
    else if (p1 == 2)
    {
        type = MMDDYYYY;
        month = atoi(s.substr(0, 2).c_str());
        day = atoi(s.substr(p1+1, 2).c_str());
        int p2 = s.find_last_of("-/");
        year = atoi(s.substr(p2+1, 4).c_str());
    }
    else
    {
        cout << "UNKNOWN DATE TYPE!" << endl;
    }
}

bool Date::operator<(Date date2)
{
    if (year < date2.year)
    {
        return true;
    }
    else
    {
        if (month < date2.month)
        {
            return true;
        }
        else
        {
            if (day < date2.day)
            {
                return true;
            }
        }
    }
    return false;
}


bool Date::operator>(Date date2)
{
    if (year < date2.year)
    {
        return false;
    }
    else
    {
        if (month < date2.month)
        {
            return false;
        }
        else
        {
            if (day < date2.day)
            {
                return false;
            }
        }
    }
    return true;
}
