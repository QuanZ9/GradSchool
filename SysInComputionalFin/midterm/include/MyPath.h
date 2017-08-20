#ifndef MYPATH_H
#define MYPATH_H

#include <ql/quantlib.hpp>
using namespace QuantLib;

class MyPath
{
    public:
        MyPath(Size length);
        MyPath(Size length, Path path);
        virtual ~MyPath(){};

        Integer getIndex(Date d) const;
        Date getDate(Integer i) const;
        Real getValue(Date d) const;
        void setDates(std::vector<Date>& dates);
        Real value(Size i) const;
        Real& value(Size i);
        Size length() const;

    private:
        std::vector<Date> dates_;
        std::vector<Real> values_;

};

#endif // MYPATH_H
