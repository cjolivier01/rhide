# Copyright (C) 1996,1997 Robert H�hne, see COPYING.RH for details 
# This file is part of RHIDE. 
s/comment --- transform a list of nodenames followed by chapter ---/&/
s/comment --- or section name, into a Sed script which changes  ---/&/
s/comment --- node names into chapter numbers in cross-references. ---/&/

/^@node[ 	]/ {
  N
  s/\n/!!=!!/
  /^@node  *Top[^a-z]/d
  s/^@node  *\([^,][^,]*\),.*!!=!!@\([a-z][a-z]*\)[ 	][ 	]*\([0-9]\(\.*[0-9]\)*\).*/s|xref{\1|xref{\2 \3|/
  s/chapter \([0-9][0-9.]*\)/Chapter \1/p
  s/subsubsection \([0-9][0-9.]*\)/Section \1/p
  s/subsection \([0-9][0-9.]*\)/Section \1/p
  s/section \([0-9][0-9.]*\)/Section \1/p
}
