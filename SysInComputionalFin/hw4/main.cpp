#include <iostream>

#include "Multiply.h"
#include "Sqaure.h"
#include "SumOfFunctions.h"
#include "FuncDiff.h"

using namespace std;

int main()
{
    double a = 1.1;
    Multiply fx(a);
    Sqaure gx;
    double x = 1.5;
    cout << "-- 1 --" << endl;
    cout << "a = " << a << ", x = " << x << endl;
    cout << "y1 = a*x = " << fx(x) << endl;
    cout << "y2 = x*x = " << gx(x) << endl;
    cout << endl;


    Multiply* fxp = new Multiply(a);
    Sqaure* gxp = new Sqaure();
    SumOfFunctions sums;
    sums.add(fxp);
    sums.add(gxp);

    cout << "-- 2 --" << endl;
    cout << "sum of functions is " << sums(x) << endl;
    cout << endl;


    cout << "-- 3 --" << endl;
    cout << "ax - sum(x) = " << getSub(fx, sums, x) << endl;

    delete fxp;
    delete gxp;
    return 0;
}
