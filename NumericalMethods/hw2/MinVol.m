% minimize
K = [95,100,105];
M = [3.8715, 6.1210, 8.9830];
r = 0.05;
q = 0.02;
T = 0.3;
vol = 0.2;
vol_ = 0;
while norm(vol - vol_) > 10^-6
    vol_ = vol;
    d1 = (log(S ./ K) + (r - q + vol.^2 ./ 2) * T) ./ (vol * sqrt(T));
    d2 = d1 - vol * sqrt(T);
    put = normcdf(-d2) .* K * exp(-r * T) - normcdf(-d1) .* S * exp(-q * T);
    put1 = 2 * S * exp(-q*T) .* (1 / sqrt(2 * pi) * exp(-d1.^2 / 2)) * (sqrt(T) / 2);
    put2 = 2 * S * (sqrt(T) / 2) * exp(-q*T) .* (exp(-d1.^2 / 2) / sqrt(2 * pi)) .* d1 .* d2 ./ vol;
    fx = sum(2 * (M - put) .* put1);
    fxp = sum(2 * M .* put2 - 2 * put1.^2 - 2 * put .* put2);
    vol = vol - fx ./ fxp;
end;
vol