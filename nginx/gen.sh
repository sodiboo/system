old="$PWD/old"
result="$PWD/result"
export out="$PWD/out"
export src="$PWD/generate"
export static="$PWD/static"
export template="$PWD/template.html"
bash ./impl.sh
mv $result $old
mv $out $result
rm -r $old