#include "GBMPathGenerator.h"

GBMPathGenerator::GBMPathGenerator(Real s0,
                 Real mu,
                 Volatility sigma,
                 Time T,
                 Size nTimeStep)
            : s0_(s0),
              mu_(mu),
              sigma_(sigma),
              T_(T),
              nTimeStep_(nTimeStep){}

boost::shared_ptr<MyPath> GBMPathGenerator::getPath(){
    boost::shared_ptr<StochasticProcess1D> diffusion(
                   new GeometricBrownianMotionProcess(s0_, mu_, sigma_));
    PseudoRandom::rsg_type rsg =
        PseudoRandom::make_sequence_generator(nTimeStep_, 0);

    bool brownianBridge = false;

    typedef SingleVariate<PseudoRandom>::path_generator_type generator_type;
    boost::shared_ptr<generator_type> pathGen(new
        generator_type(diffusion, T_, nTimeStep_,
                       rsg, brownianBridge));

    boost::shared_ptr<MyPath> path(new MyPath(nTimeStep_, pathGen->next().value));
    //boost::shared_ptr<MyPath> myPath = boost::static_pointer_cast<MyPath>(path);

//    std::vector<Date> dates;
//    for (int i = 0; i < nTimeStep_; ++i){
//        dates.push_back(Date(1,Jan,2011));
//    }
//    myPath->setDates(dates);
    return path;
}
