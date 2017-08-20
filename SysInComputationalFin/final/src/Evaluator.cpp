#include "Evaluator.h"

Evaluator::Evaluator(TimeSeries<Real>& values)
{
    computeStats(values);
}

Evaluator::~Evaluator()
{
    //dtor
}

void Evaluator::computeStats(TimeSeries<Real>& values){
    Real cumRet = 0;
    Real dailyRet;
    Real maxPoint = -999;
    Real maxDD = 0;
    //standard deviation
    boost::accumulators::accumulator_set<double, boost::accumulators::features<boost::accumulators::tag::mean, boost::accumulators::tag::variance> >  stdDev;
    for (int i = 1; i < values.size(); ++i){
//        std::cout << "value on " << values.dates()[i] << " is " << values.values()[i] << std::endl;
        dailyRet = values.values()[i] / values.values()[i - 1] - 1;
        cumRet += dailyRet;
        stdDev(dailyRet);
        maxPoint = std::max(maxPoint, values.values()[i]);
        maxDD = std::max(maxDD, maxPoint - values.values()[i]);
    }

    avgRet_ = cumRet / values.size() * 252;
    cumRet_ = cumRet;

    Real var = boost::accumulators::variance(stdDev);
//    std::cout << avgRet_ << " " << var << std::endl;
    sharpeRatio_ = avgRet_ / std::sqrt(var) / std::sqrt(252);

    MDD_ = -maxDD / maxPoint;
}


void Evaluator::write2csv(std::string filename){
    std::ofstream fout;
    fout.open(filename.c_str());

    fout << "Total profit/loss = " << cumRet_ << std::endl;
    fout << "Average daily return(annualized) = " << avgRet_ << std::endl;
    fout << "Sharpe Ratio = " << sharpeRatio_ << std::endl;
    fout << "Maximum drawdowns = " << MDD_ << std::endl;

    fout.close();

}
