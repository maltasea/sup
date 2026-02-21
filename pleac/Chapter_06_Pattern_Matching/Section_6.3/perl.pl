
#-----------------------------
#/\S+/               # as many non-whitespace bytes as possible
#/[A-Za-z'-]+/       # as many letters, apostrophes, and hyphens
#-----------------------------
#/\b([A-Za-z]+)\b/            # usually best
#/\s([A-Za-z]+)\s/            # fails at ends or w/ punctuation
#-----------------------------

