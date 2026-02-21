
#-----------------------------
#% psgrep '/sh\b/'
#-----------------------------
#% psgrep 'command =~ /sh$/'
#-----------------------------
#% psgrep 'uid < 10'
#-----------------------------
#% psgrep 'command =~ /^-/' 'tty ne "?"'
#-----------------------------
#% psgrep 'tty =~ /^[p-t]/'
#-----------------------------
#% psgrep 'uid && tty eq "?"'
#-----------------------------
#% psgrep 'size > 10 * 2**10' 'uid != 0'
#-----------------------------
# FLAGS   UID   PID  PPID PRI  NI   SIZE   RSS WCHAN     STA TTY TIME COMMAND
#
#     0   101  9751     1   0   0  14932  9652 do_select S   p1  0:25 netscape
#
#100000   101  9752  9751   0   0  10636   812 do_select S   p1  0:00 (dns helper)
#-----------------------------
# ^^INCLUDE^^ include/perl/ch01/psgrep
# the following was used to determine column cut points.
# sample input data follows
# 123456789012345678901234567890123456789012345678901234567890123456789012345
#          1         2         3         4         5         6         7
#  Positioning:
#        8     14    20    26  30  34     41    47          59  63  67   72
#        |     |     |     |   |   |      |     |           |   |   |    |
# __END__
#  FLAGS   UID   PID  PPID PRI  NI   SIZE   RSS WCHAN       STA TTY TIME COMMAND
# 
#    100     0     1     0   0   0    760   432 do_select   S   ?   0:02 init
# 
#    140     0   187     1   0   0    784   452 do_select   S   ?   0:02 syslogd
# 
# 100100   101   428     1   0   0   1436   944 do_exit     S    1  0:00 /bin/login
# 
# 100140    99 30217   402   0   0   1552  1008 posix_lock_ S   ?   0:00 httpd
# 
#      0   101   593   428   0   0   1780  1260 copy_thread S    1  0:00 -tcsh
# 
# 100000   101 30639  9562  17   0    924   496             R   p1  0:00 ps axl
# 
#      0   101 25145  9563   0   0   2964  2360 idetape_rea S   p2  0:06 trn
# 
# 100100     0 10116  9564   0   0   1412   928 setup_frame T   p3  0:00 ssh -C www
# 
# 100100     0 26560 26554   0   0   1076   572 setup_frame T   p2  0:00 less
# 
# 100000   101 19058  9562   0   0   1396   900 setup_frame T   p1  0:02 nvi /tmp/a
#-----------------------------
eval "sub is_desirable { uid < 10 } " . 1;
#-----------------------------
#% psgrep 'no strict "vars";
#          BEGIN { $id = getpwnam("nobody") }
#          uid == $id '
#-----------------------------
sub id()         { $_->{ID}   }
sub title()      { $_->{TITLE} }
sub executive()  { title =~ /(?:vice-)?president/i }

# user search criteria go in the grep clause
@slowburners = grep { id < 10 && !executive } @employees;
#-----------------------------

