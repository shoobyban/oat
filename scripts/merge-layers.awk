#!/usr/bin/awk -f
# Merge repeated @layer blocks into single blocks per layer name.
# Input: concatenated CSS (pre-minification).
# Output: CSS with one @layer block per layer name.
#
# Works with BSD awk (macOS) and gawk.

BEGIN {
  layerCount = 0
  currentLayer = ""
  depth = 0
}

# Track the @layer order declaration (e.g. @layer theme, base, components;)
/^@layer [a-z, ]+;/ {
  orderDecl = $0
  next
}

# Match opening @layer <name> {
/^@layer [a-z]+ \{/ {
  # Extract layer name: second word
  currentLayer = $2
  depth = 1

  # Track order of first appearance
  if (!(currentLayer in layerContent)) {
    layerOrder[layerCount++] = currentLayer
    layerContent[currentLayer] = ""
  }

  next
}

# When inside a layer block, track brace depth
currentLayer != "" {
  line = $0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (c == "{") depth++
    else if (c == "}") depth--
  }

  if (depth <= 0) {
    currentLayer = ""
    depth = 0
  } else {
    layerContent[currentLayer] = layerContent[currentLayer] $0 "\n"
  }
  next
}

# Lines outside any @layer block - pass through
{
  outside = outside $0 "\n"
}

END {
  if (orderDecl != "") print orderDecl
  if (outside != "") printf "%s", outside

  for (i = 0; i < layerCount; i++) {
    name = layerOrder[i]
    print ""
    print "@layer " name " {"
    printf "%s", layerContent[name]
    print "}"
  }
}
