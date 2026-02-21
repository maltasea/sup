
#-----------------------------
#% cat > expn
#!/usr/bin/perl -w
#...
#^D
#% ln expn vrfy
#-----------------------------
#% expn gnat@frii.com
#Expanding gnat at frii.com (gnat@frii.com):
#
#calisto.frii.com Hello coprolith.frii.com [207.46.130.14],
#
#    pleased to meet you
#
#<gnat@mail.frii.com>
#-----------------------------
#% expn gnat@frii.com
#Expanding gnat at mail.frii.net (gnat@frii.com):
#
#deimos.frii.com Hello coprolith.frii.com [207.46.130.14],
#
#    pleased to meet you
#
#Nathan Torkington <gnat@deimos.frii.com>
#
#
#Expanding gnat at mx1.frii.net (gnat@frii.com):
#
#phobos.frii.com Hello coprolith.frii.com [207.46.130.14],
#
#    pleased to meet you
#
#<gnat@mail.frii.com>
#
#
#E
#xpanding gnat at mx2.frii.net (gnat@frii.com):
#
#europa.frii.com Hello coprolith.frii.com [207.46.130.14],
#
#    pleased to meet you
#
#<gnat@mail.frii.com>
#
#
#Expanding gnat at mx3.frii.net (gnat@frii.com):
#
#ns2.winterlan.com Hello coprolith.frii.com [207.46.130.14],
#
#    pleased to meet you
#
#550 gnat... User unknown
#-----------------------------
# ^^INCLUDE^^ include/perl/ch18/expn
#-----------------------------

