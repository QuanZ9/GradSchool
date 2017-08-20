#ifndef FUNCDIFF_H
#define FUNCDIFF_H

template<class F, class G>

double getSub(F& f, G& g, double x){
    return (f(x) - g(x));
}

#endif // FUNCDIFF_H
