mkdir -p $out

cd $src

tmp="$(mktemp -d)"
for f in {**/*,*}.md
do
  f=$(echo $f | sed -e 's/\.md$//')
  title=$(rg '^#{1,6} (.+)$' $f.md -or '$1' | head -n 1)
  if [ ! -d "$out/$(dirname $f)" ]; then
    mkdir -p "$out/$(dirname $f)"
  fi
  if [ ! -d "$tmp/$(dirname $f)" ]; then
    mkdir -p "$tmp/$(dirname $f)"
  fi
  rg '<!-- style /?(.*) -->' $f.md -or '<link rel="stylesheet" href="/.nginx/$1" />' > $tmp/$f
  sed -e $'s/^<!-- style .* -->$//' $f.md | pandoc --from gfm --to html -o - > $out/$f.html
  sed \
    -e "s/@TITLE@/$title/" \
    -e "/@BODY@/r $out/$f.html" \
    -e "/@BODY@/d" \
    -e "/@STYLE@/r $tmp/$f" \
    -e "/@STYLE@/d" \
    $template | sponge $out/$f.html
done
rm -r $tmp

cd $static

for f in *
do
  cp -r $f $out/$f
done