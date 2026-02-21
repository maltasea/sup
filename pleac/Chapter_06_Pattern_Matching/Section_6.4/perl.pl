
#-----------------------------
# ^^INCLUDE^^ include/perl/ch06/resname
#-----------------------------
s/                  # replace
  \#                #   a pound sign
  (\w+)             #   the variable name
  \#                #   another pound sign
/${$1}/xg;          # with the value of the global variable
##-----------------------------
s/                  # replace
\#                  #   a pound sign
(\w+)               #   the variable name
\#                  #   another pound sign
/'$' . $1/xeeg;     # ' with the value of *any* variable
#-----------------------------

