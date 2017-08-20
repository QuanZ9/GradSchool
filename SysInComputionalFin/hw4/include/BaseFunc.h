#ifndef BASEFUNC_H
#define BASEFUNC_H


class BaseFunc
{
    public:
        BaseFunc(){};
        virtual ~BaseFunc(){};
        virtual double operator()(double x) = 0;
        virtual BaseFunc* copy() const = 0;
};

#endif // BASEFUNC_H
