
#-----------------------------
# greedy pattern
s/<.*>//gs;                     # try to remove tags, very badly

# non-greedy pattern
s/<.*?>//gs;                    # try to remove tags, still rather badly
#-----------------------------
#<b><i>this</i> and <i>that</i> are important</b> Oh, <b><i>me too!</i></b>
#-----------------------------
m{ <b><i>(.*?)</i></b> }sx
#-----------------------------
/BEGIN((?:(?!BEGIN).)*)END/
#-----------------------------
m{ <b><i>(  (?: (?!</b>|</i>). )*  ) </i></b> }sx
#-----------------------------
m{ <b><i>(  (?: (?!</[ib]>). )*  ) </i></b> }sx
#-----------------------------
m{
    <b><i> 
    [^<]*  # stuff not possibly bad, and not possibly the end.
    (?:
 # at this point, we can have '<' if not part of something bad
     (?!  </?[ib]>  )   # what we can't have
     <                  # okay, so match the '<'
     [^<]*              # and continue with more safe stuff
    ) *
    </i></b>
 }sx
#-----------------------------

