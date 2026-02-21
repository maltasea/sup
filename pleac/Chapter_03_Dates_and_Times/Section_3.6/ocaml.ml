
#load "unix.cma";;

let {Unix.tm_mday=monthday; tm_wday=weekday; tm_yday=yearday} =
  Unix.localtime date
let weeknum = yearday / 7 + 1

