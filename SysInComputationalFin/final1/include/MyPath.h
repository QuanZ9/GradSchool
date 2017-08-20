#ifndef MYPATH_H
#define MYPATH_H

#include <ql/quantlib.hpp>
using namespace QuantLib;

template <class T>

class MyPath
{
    public:
        MyPath(Size length){
            dates_.resize(length + 1, Date());
            values_.resize(length + 1, 0);
        }

        MyPath(Size length, Path path){
            dates_.resize(length + 1, Date());
            values_.resize(length + 1);
            for (int i = 0; i < length + 1; ++i){
                values_[i] = path.value(i);
            }
        }

        void setDates(std::vector<Date>& dates){
            dates_ = dates;
        }

        Integer getIndex(Date d) const{
            Integer p = find(dates_.begin(), dates_.end(), d) - dates_.begin();

            if (p >= dates_.size()){
                std::cout << "can't fine Date in getValue(Date)!!!" << std::endl;
            }
            return p;
        }

        Date getDate(Integer i) const{
            if (i >= dates_.size()){
                std::cout << "exceed boundary in getDate(Integer)!!!" << std::endl;
            }
            return dates_[i];
        }

        T getValue(Date d) const{
            return value(getIndex(d));
        }

        T value(Size i) const{
            if (i >= values_.size()){
                std::cout << "exceed boundary in value(Integer)!!!" << std::endl;
            }
            return values_[i];
        }

        T& value(Size i){
            if (i >= values_.size()){
                std::cout << "exceed boundary in valueRef(Integer)!!!" << std::endl;
                std::cout << i << " of " << values_.size() << std::endl;
            }
            return values_[i];
        }

        Size length() const{
            return dates_.size();
        }
        virtual ~MyPath(){};

    private:
        std::vector<Date> dates_;
        std::vector<T> values_;

};

#endif // MYPATH_H
