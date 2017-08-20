#include "SumOfFunctions.h"
using namespace std;

SumOfFunctions::SumOfFunctions()
{
    //ctor
}

SumOfFunctions::~SumOfFunctions()
{
    for (int i = 0; i < funcs.size(); ++i){
        delete funcs[i];
    }
    funcs.clear();
}

void SumOfFunctions::add(BaseFunc* newFunc){
    funcs.push_back(newFunc->copy());
}

double SumOfFunctions::operator()(double x){
    double total = 0;
    for (int i = 0; i < funcs.size(); ++i){
        total += (*funcs[i])(x);
    }
    return total;
}
