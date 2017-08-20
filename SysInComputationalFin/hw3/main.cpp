//
//  main.cpp
//  lab2_1
//
//  Created by Xinyu Min on 9/4/15.
//  Copyright (c) 2015 Georgia Institute of Technology. All rights reserved.
//

#include <iostream>
#include <fstream>
#include "DoubleDigital.h"
#include "Payoff.h"
#include "PayoffBridge.h"
#include "Option.h"
#include "MonteCarlo.h"
#include "StdNormalCDF.h"
#include "OptionVanillaBS.h"
#include <vector>
using namespace std;


int main(int argc, const char * argv[])
{
    //---------------------------------
    //------------problem 1------------
    //---------------------------------
    StdNormalCDF cdf;
    cout << "-----Problem 1-----" << endl;
    cout << "N(3) = " << cdf(3) << endl;
    cout << "N(-3) = " << cdf(-3) << endl;
    cout << "N(3) + N(-3) = " << cdf(3) + cdf(-3) << endl << endl;;


    //------------------------------
    //----------problem 2-----------
    //------------------------------
    double expiry = 0.5;
    double spot = 100;
    double strike = 100;
    double vol = 0.2;
    double r = 0.01;
    double q = 0;

    PayoffVanilla payoff_call(Option::Call, strike);
    PayoffVanilla payoff_put(Option::Put, strike);
    OptionVanillaBS bs_call(payoff_call, spot, vol, r, q, expiry);
    OptionVanillaBS bs_put(payoff_put, spot, vol, r, q, expiry);

    double callPrice = bs_call.getBsPayoff();
    double putPrice = bs_put.getBsPayoff();

    cout << "-----Problem 2-----" << endl;
    cout << "price for Black-Scholes CALL option = " << callPrice << endl;
    cout << "price for Black-Scholes PUT option = " << putPrice << endl;
    cout << "put-call parity is " << callPrice - putPrice << endl << endl;


    //------------------------------
    //---------problem 3------------
    //------------------------------

    ofstream outfile("problem3.csv");
    strike = 100;
    expiry = 0.5;
    r = 0.01;
    q = 0;

    double vol_begin = 0.1;
    double vol_end = 0.6;
    double vol_step = 0.05;
    double s0_begin = 85;
    double s0_end = 115;
    double s0_step = 5;

    //output header
    outfile << "S/sigma, ";
    for (vol = vol_begin; vol <= vol_end; vol += vol_step){
        outfile << vol << ", ";
    }
    outfile << endl;

    //output data
    for (spot = s0_begin; spot <= s0_end; spot += s0_step){
        outfile << spot << ", ";
        for (vol = vol_begin; vol <= vol_end; vol += vol_step){
            PayoffVanilla payoff_call(Option::Call, strike);
            OptionVanillaBS bs_call(payoff_call, spot, vol, r, q, expiry);
            outfile << bs_call.getBsPayoff() << ", ";
        }
        outfile << endl;
    }
    outfile.close();
    cout << "-----Problem 3-----" << endl;
    cout << "Please check the results in \"./problem3.csv\" " << endl << endl;



    //------------------------------
    //----------problem 4-----------
    //------------------------------
    double expiry1 = 0.4;
    outfile.open("problem4.csv");

    //output header
    outfile << "S/sigma, ";
    for (vol = vol_begin; vol <= vol_end; vol += vol_step){
        outfile << vol << ", ";
    }
    outfile << endl;

    //output data
    for (spot = s0_begin; spot <= s0_end; spot += s0_step){
        outfile << spot << ", ";
        for (vol = vol_begin; vol <= vol_end; vol += vol_step){
            PayoffVanilla payoff(Option::Call, strike);
            OptionVanillaBS bs_call(payoff_call, spot, vol, r, q, expiry);
            OptionVanillaBS bs_call1(payoff_call, spot, vol, r, q, expiry1);

            outfile << bs_call.getBsPayoff() + (-1) * bs_call1.getBsPayoff() << ", ";
        }
        outfile << endl;
    }
    outfile.close();
    cout << "-----Problem 4-----" << endl;
    cout << "Please check the results in \"./problem4.csv\" " << endl;

    return 0;
}













