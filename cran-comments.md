## Non-standard version number
The version (0.1.0.1.0) does not have three components. Since the package is 
an interface to the C++ library vinecopulib, we decided to adopt the convention 
of e.g. RcppEigen, where the first three components are related to 
vinecopulib's version.

## Test environments
* local OS X install, R 3.4.1
* ubuntu 12.04 (on travis-ci), R 3.4.1
* Windows Server 2012 R2 x64 and x86 (on appveyor), R 3.4.1

## R CMD check results
There were no ERROR or WARNINGs. 

There was a NOTE related to sub-directories of 1Mb or more (only for the 
ubuntu builts). It was reproduced on a local ubuntu 12.04 install but 
everything appears to be in order.

## Reverse dependencies
There are no reverse dependencies.