using Bloomie
using Base.Test

# check blpapi version is higher than 3.8.0.0
@test (x->Int(1e6*x[1]+1e4*x[2]+1e2*x[3]+x[4]))(Bloomie.get_version())>=3080000
