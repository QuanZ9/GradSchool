#include "Portfolio.h"

Portfolio::Portfolio(Real initialCash, Real tc, Date startDate) : currentCash_(initialCash), transCost_(tc), startDate_(startDate){
    cash_[startDate] = initialCash;
    portValue_[startDate] = initialCash;
    stockShares_ = 0;
    origCallPrice_ = -1;
    origPutPrice_ = -1;
    avgStockPrice_ = -1;
}

Real Portfolio::tradeStock(Real n, Real price){
    Real ret = 0;
    if (std::abs(stockShares_) > 0.01){
        if (n * stockShares_ > 0){
            avgStockPrice_ = (avgStockPrice_ * stockShares_ + n * price) / (n + stockShares_);
            ret = 0;
        }
        else{
            ret = price / avgStockPrice_ - 1;
        }
    }
    else{
        avgStockPrice_ = price;
        ret = 0;
    }

    stockShares_ += n;
    currentCash_ -= n * price;
    //transaction cost
    currentCash_ -= std::abs(n) * price * transCost_;
//    std::cout<<"stock " << n << " " << price << " " << currentCash_ << std::endl;
    return ret;

}

Real Portfolio::tradeOption(boost::shared_ptr<RawOption> option, Integer n, Real price){
    Real ret = 0;
    std::vector<std::pair<boost::shared_ptr<RawOption>, Integer> >::iterator k;
    //if already hold this option, change its number of shares
    for (k = options_.begin(); k != options_.end(); ++k){
        if ((*k).first->equals(option)){
            (*k).second += n;
            if ((*k).second == 0){
                options_.erase(k);
                k--;
            }
            break;
        }
    }
    //otherwise open a position
    if (k == options_.end()){
        options_.push_back(std::pair<boost::shared_ptr<RawOption>, Integer>(option, n));
        if (option->getType() == Option::Call){
            origCallPrice_ = price;
        }
        else{
            origPutPrice_ = price;
        }
        ret = 0;
    }
    currentCash_ -= n * price;
    //transaction cost
    currentCash_ -= 100 * std::abs(n) * price * transCost_;

//    std::cout << "option " << option->getType() << " " << n << " " << price << " " << currentCash_ << std::endl;

    if (currentCash_ < 0){
        std::cout << "[WARNING]: cash is negative!!!" << std::endl;
    }

    if (option->getType() == Option::Call){
        ret = price / origCallPrice_ - 1;
    }
    else{
        ret =  price / origPutPrice_ - 1;
    }

    return ret;
}

void Portfolio::updateValue(Date d, Real stockPrice, std::vector<Real> optionPrice){
    Real value = currentCash_;
    //stock value;
    value += stockShares_ * stockPrice;
    //option value;
    for (int i = 0; i < options_.size(); ++i){
        value += options_[i].second * optionPrice[i];
    }
    portValue_[d] = value;
    cash_[d] = currentCash_;
}

void Portfolio::updateValue(Date d){
    Date last = portValue_.lastDate();
    portValue_[d] = portValue_[last];
    cash_[d] = cash_[last];
}


