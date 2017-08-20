#include <iostream>
#include "GammaScalping.h"
#include "Evaluator.h"
#include <time.h>

using namespace std;

int main()
{
    double startTime = clock();
    int m;
    int w;
    int e;
    double low;
    double high;
    bool useHistorical;
    bool searchParams;

    Integer tmin;
    Integer tmax;
    int K;
    double delta;

    Date startDateIn;
    Date endDateIn;
    Date startDateOut;
    Date endDateOut;

    string stockFile;
    string optionFile;
    string rfFile;
    string resultFile;
    string performanceFile;

    double initCash = 1000000;
    double transCost = 0.001;

    readConfig("config", m, w, e, low, high, tmin, tmax, K, delta, startDateIn, endDateIn, startDateOut, endDateOut, initCash, transCost,
               stockFile, optionFile, rfFile, resultFile, performanceFile, searchParams, useHistorical);

    if (searchParams){
        // find best parameters using in-sample backtest
        CsvReader reader(stockFile, optionFile, rfFile);
        //LOOP useHistorical m w e low high tmin tmax delta
        double maxSR = -99;
        for (int _m = 5; _m <= 10; _m += 5){
            for (int _w = 5; _w < 10; _w += 5){
                for (int _e = 2; _e <= 20; _e += 18){
                    for (int _tmin = 40; _tmin <= 80; _tmin += 40){
                        for (int _tmax = 100; _tmax <= 140; _tmax += 40){
                            for (double _delta = 0.1; _delta <= 0.2; _delta += 0.1){
                                for (int use = 0; use <= 1; ++use){
                                    for (double _low = 0.24 + use*0.06; _low <= 0.28 + use*0.12; _low += 0.04 + use * 0.06){
                                        for (double _high = 0.32 + use * 0.18; _high <= 0.36 + use * 0.24; _high += 0.04 + use * 0.06){
                                            double loopStart = clock();
                                            GammaScalping gs(boost::shared_ptr<VolSignalGen>(new VolSignalGen(use, _low, _high, _e, _w, _m)), _tmin, _tmax, _delta);
                                            QuantLib::TimeSeries<Real> portVals = gs.run(reader, startDateIn, endDateIn, K, initCash, transCost);
                                            Evaluator evaluator(portVals);
                                            if (evaluator.getSharpeRatio() > maxSR){
                                                useHistorical = use;
                                                m = _m;
                                                w = _w;
                                                e = _e;
                                                low = _low;
                                                high = _high;
                                                tmin = _tmin;
                                                tmax = _tmax;
                                                delta = _delta;
                                                maxSR = evaluator.getSharpeRatio();
                                            }
                                            cout << "with use historical = " << use << ", "
                                                 << "m = " << _m << ", "
                                                 << "w = " << _w << ", "
                                                 << "e = " << _e << ", "
                                                 << "sigmaEntry = " << _low << ", "
                                                 << "sigmaExit = " << _high << ", "
                                                 << "Tmin = " << _tmin << ", "
                                                 << "Tmax = " << _tmax << ", "
                                                 << "delta = " << _delta << " ------- sharpe ratio is " << evaluator.getSharpeRatio() << endl;
                                            double loopEnd = clock();
                                            cout << "iteration time = " << double(loopEnd - loopStart) / CLOCKS_PER_SEC << ", max SR is " << maxSR << endl;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        cout <<" -------------out of sample ------------------ "<< endl;
       cout << "with use historical = " << useHistorical << ", "
            << "m = " << m << ", "
             << "w = " << w << ", "
             << "e = " << e << ", "
             << "sigmaEntry = " << low << ", "
             << "sigmaExit = " << high << ", "
             << "Tmin = " << tmin << ", "
             << "Tmax = " << tmax << ", "
             << "delta = " << delta << endl;

        GammaScalping gs(boost::shared_ptr<VolSignalGen>(new VolSignalGen(false, low, high, e, w, m)), tmin, tmax, delta);
        QuantLib::TimeSeries<Real> portVals = gs.run(reader, startDateOut, endDateOut, K, initCash, transCost);
        Evaluator evaluator(portVals);
        gs.write2csv(resultFile);
        evaluator.write2csv(performanceFile);
    }
    else{
        // use user specified parameters
        CsvReader reader(stockFile, optionFile, rfFile);

        GammaScalping gs(boost::shared_ptr<VolSignalGen>(new VolSignalGen(useHistorical, low, high, e, w, m)), tmin, tmax, delta);
        QuantLib::TimeSeries<Real> portVals = gs.run(reader, startDateIn, endDateIn, K, initCash, transCost);
        gs.write2csv(resultFile);

        Evaluator evaluator(portVals);
        evaluator.write2csv(performanceFile);

    }
    double endTime = clock();
    std::cout << "Time elapsed : " << double(endTime - startTime) / CLOCKS_PER_SEC << endl;
    return 0;
}
