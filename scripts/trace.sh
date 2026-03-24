#!/bin/bash

TRACE=trace
tr "[A-Z]" "[a-z]" <$TRACE.out >$TRACE

awk '
#!/bin/nawk -f
#
# Converts PACE output to DOT output (directed graph)
#    tr "[A-Z]" "[a-z]" <trace.out, to change case

BEGIN {
  title = "tracegraph"
  landscape = "landscape"
  if (ARGC > 1) title = ARGV[1]
  if (ARGC > 2) landscape = ARGV[2]
  
  print "digraph PN {"
  if (landscape == "landscape=1") {
     print "orientation=landscape;"
     print "size=\"10.2,7.7\";"
  } else {
     print "orientation=portrait;"
     print "size=\"7.7,10.2\";"
  }
#  print "rankdir=LR;"
  print "center = true;"
  print "ratio = fill;"
  print title " [shape=plaintext, fontsize=14];"
  print "asynchronous [shape=plaintext, fontcolor=red];"
  print "simple [shape=plaintext, fontcolor=blue];"
  print "synchronized [shape=plaintext, fontcolor=black];"
  print "blocking [shape=plaintext, fontcolor=green];"
  print "asynchronous -> asynchronous [color=red, style=\"setlinewidth(1)\"]"
  print "simple -> simple [color=blue, style=\"setlinewidth(2)\"]"
  print "synchronized -> synchronized [color=black, style=\"setlinewidth(3)\"]"
  print "blocking -> blocking [color=green, style=\"setlinewidth(4)\"]"
  print title " -> asynchronous -> simple -> synchronized -> blocking [color=white]"
  print "edge [fontname=\"Helvetica\"];"
  print "node [fontname=\"Helvetica\"];"
  edges = 0
  counter = 0
}

# pretty prints to nice output
function obj(s) {
  sub("[.]", ":", s)    
  gsub("[_]", "\\n", s)
  return(s);
}

# creates a transition arc (edge) according to notation
function dot(from, to, color, weight) {
  nf_to = split (obj(to), dest, ".")
  if (nf_to == 2)
     edge [edges++] = "\"" obj(from) "\" -> \"" dest[1] "\" [label=\"" counter ":" dest[2] "\", color=" color ", style=\"setlinewidth(" weight ")\"]"
  else
     edge [edges++] = "\"" obj(from) "\" -> \"" dest[1] "." dest[2] "\" [label=\"" counter ":" dest[3] "\", color=" color ", style=\"setlinewidth(" weight ")\"]"
}

$4 == ">>" { dot($3, $5, "black", 3) }
$4 == "->" { dot($3, $5, "red",   1) }
$4 == "=>" { dot($3, $5, "blue",  2) }
$4 == "<>" { dot($3, $5, "green", 4) }

# Make sure every active object is registered
{ 
  task[$3] = obj($3)
  counter++
}

END {
  for (i in task) {
    print "node [shape=parallelogram]; \"" task[i] "\";"
  }
  print "node [shape=ellipse];"
  for (i=0; i<edges; i++) {
    print edge[i]
  }
  print "}"
}
'  $TRACE  >${TRACE}.dot

dot -Tps -Grankdir=LR ${TRACE}.dot -o ${TRACE}.ps
ps2pdf ${TRACE}.ps
evince ${TRACE}.pdf


