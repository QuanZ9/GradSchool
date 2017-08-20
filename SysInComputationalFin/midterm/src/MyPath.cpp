#include "MyPath.h"


MyPath::MyPath(Size length){
    dates_.resize(length + 1, Date());
    values_.resize(length + 1, 0);
}

MyPath::MyPath(Size length, Path path){
    dates_.resize(length + 1, Date());
    values_.resize(length + 1);
    for (int i = 0; i < length + 1; ++i){
        values_[i] = path.value(i);
    }
}

void MyPath::setDates(std::vector<Date>& dates){
    dates_ = dates;
}

Integer MyPath::getIndex(Date d) const{
    Integer p = find(dates_.begin(), dates_.end(), d) - dates_.begin();

    if (p >= dates_.size()){
        std::cout << "can't fine Date in getValue(Date)!!!" << std::endl;
    }
    return p;
}

Date MyPath::getDate(Integer i) const{
    if (i >= dates_.size()){
        std::cout << "exceed boundary in getDate(Integer)!!!" << std::endl;
    }
    return dates_[i];
}

Real MyPath::getValue(Date d) const{
    return value(getIndex(d));
}

Real MyPath::value(Size i) const{
    if (i >= values_.size()){
        std::cout << "exceed boundary in value(Integer)!!!" << std::endl;
    }
    return values_[i];
}

Real& MyPath::value(Size i){
    if (i >= values_.size()){
        std::cout << "exceed boundary in valueRef(Integer)!!!" << std::endl;
        std::cout << i << " of " << values_.size() << std::endl;
    }
    return values_[i];
}

Size MyPath::length() const{
    return dates_.size();
}
