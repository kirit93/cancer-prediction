cd sources
for filename in *.py; do
    zip ../zipfiles/"${filename%%.*}"_function.zip "$filename"
done

