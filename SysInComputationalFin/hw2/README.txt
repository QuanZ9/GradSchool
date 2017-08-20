*****************************
****ISYE/MATH-6767-A*********
****Assignment 2*************
****Quan Zhou, 09/11/2015****
*****************************

code structure:
/hw2/
  /include/
    CsvParser.h		Read .csv file and save data in StockData format. 
    Date.h		Date format. Currently only support "yyyy/mm/dd", "yyyy-mm-dd", "mm/dd/yyyy" and "mm-dd-yyyy".
    Payoff.h		Base class for option payoffs.
    PayoffAsian.h	Dirived class of Payoff. Compute the payoff of European-style asian call options.
    PayoffCallEuro.h	Derived class of Payoff. Compute the payoff of European power call options. 
    PayoffPutEuro.h	Derived class of Payoff. Compute the payoff of European power put options.
    StockData.h		Stock data format. Currently includes a date and a price. 
  
  /src/
    CsvParser.cpp	Implementation of CsvParser.h
    Date.cpp		Implementation of Date.h
    Payoff.cpp		Implementation of Payoff.h
    PayoffAsian.cpp	Implementation of PayoffAsian.h
    PayoffCallEuro.cpp	Implementation of PayoffCallEuro.h
    PayoffPutEuro.cpp	Implementation of PayoffPutEuro.h
    main.cpp		Main function of this program. User needs to specify data file, type and strike price of the option, buy and sell date of option. The program will calculate the option's return using the corresponding option model. 
