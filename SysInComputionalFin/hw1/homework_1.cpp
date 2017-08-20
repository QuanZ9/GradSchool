#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstring>
#include <stdlib.h>


using namespace std;

double average(vector<double> v)
{
// code for calculating average of members of v
    double total = 0;
    for (int i = 0; i < v.size(); ++i){
        total += v[i];
    }
// and returning the average
    return total / v.size();
}

double find_rate(vector<double> rate_vec, vector<string> date_vec, string date)
{
// code for finding the Baa rate for the
// given date (in yyyy-mm format)
// and returning the rate for that month
    for (int i = 0; i < date_vec.size(); ++i){
        if (!strcmp(date.c_str(), date_vec[i].c_str())){
            return rate_vec[i];
        }
    }
    return -1;
}

int main()
{
    vector<double> rate;
    vector<string> date;
    ifstream infile("./H.15_Baa_Data.csv");
    int headerSize = 6;
// code for loading rate and date vectors from the file H.15_Baa_Data.csv
// the headers should be handled properly. do not delete them manually

    if (!infile){
        cout << "error! file does not exist!"<<endl;
    }

    string temp;
    for (int i = 0; i < headerSize; ++i){
        getline(infile, temp);
    }

    while (getline(infile, temp)){
        int dot = temp.find(",");
        date.push_back(temp.substr(0, dot));
        rate.push_back(atof(temp.substr(dot + 1, temp.length() - 1).c_str()));
    }

    infile.close();

// code for prompting user for a date and returning the rate
// and the difference between the rate for that date and the
// average rate
    double avgRate = average(rate);
//
    string rDate;
    double rRate;
    while(1){
        cout << "please input a request date: " << endl;
        cin >> rDate;
        //getline(cin, rDate);
        if (rDate == "EOF" || rDate == "eof" || cin.eof()){
            cout << "program is terminated by user" << endl;
            break;
        }

        rRate = find_rate(rate, date, rDate);
        if (rRate < 0){
            cout << "can't find the input date!" << endl;
        }
        else{
            cout << "rate on requested date is " << rRate
                << ", difference between this rate and the average rate is " << rRate - avgRate << endl;
        }
    }

// This code should allow the user to continue to input dates
// until the user inputs the EOF (End-of-file), namely control-d (in linux/mac) or control-z (in windows)
// This should not crash if a bad date is entered.
    return 0; // program end
}
