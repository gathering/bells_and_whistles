#!/bin/bash
total_ret=0
total=0
nqueue=0
_start=$(date +%s)
VERBOSE="0"
if [ "x$1" = "x-v" ]; then
	VERBOSE=true
fi

. util.sh

if [ -d output ]; then rm -r output; fi
mkdir -p output
queue() {
	mkdir -p output/${nqueue}
	cat > output/${nqueue}/script <<_EOF_
#!/bin/bash
_start=\$(date +%s)
cd \$(dirname \$0)
. ../../util.sh
$* | sponge
echo \$? > ret
echo \$(( \$(date +%s) - \${_start} )) > runtime
_EOF_
	chmod +x output/${nqueue}/script
	nqueue=$(( ${nqueue} + 1 ))
}
queue check_ssl www.gathering.org
queue check_ssl gathering.org
queue check_ssl wannabe.gathering.org
queue check_ssl archive.gathering.org
queue check_ssl countdown.gathering.org
queue check_ssl teaser.gathering.org

queue check_mixed https://www.gathering.org/
queue check_mixed https://archive.gathering.org/
queue check_mixed https://wannabe.gathering.org/

# Wannabe
queue check_url http://wannabe.gathering.org 302 https://wannabe.gathering.org/
queue check_url https://wannabe.gathering.org 302 https://wannabe.gathering.org/tg18/

# g.o front
queue check_url http://www.gathering.org/ 302 https://www.gathering.org/tg17/

# TG17
queue check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
queue check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
queue check_url https://www.gathering.org/tg17 302 https://www.gathering.org/tg17/
queue check_url https://www.gathering.org/tg17/ 200
queue check_url https://www.gathering.org/tg17/admin/ 302 https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/
queue check_url https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/ 200

# Archive
queue check_url http://archive.gathering.org/ 302 https://archive.gathering.org/
queue check_url https://archive.gathering.org/ 200
for year in 96 97 98 99 0{0..9} 10 15 16; do
	queue check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 200
	queue check_mixed https://archive.gathering.org/tg${year}/
done
for year in {11..12}; do
	queue check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/en/
	queue check_url https://archive.gathering.org/tg${year}/en/ 200
done
queue check_mixed https://archive.gathering.org/tg11/en/
for year in {13..14}; do
	queue check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/no/
	queue check_url https://archive.gathering.org/tg${year}/no/ 200
	queue check_mixed https://archive.gathering.org/tg${year}/no/
done

make -j10 $(echo output/*/script | sed s/script/ret/g)
item=0
while [ $item -lt $nqueue ]; do
	ret=$(cat output/${item}/ret)
	total_ret=$(( ${total_ret} + ${ret} ))
	total=$(( ${total} + 1 ))
	item=$(( $item + 1 ))
done
#if [ -d output ]; then rm -r output; fi

echo
_duration=$(( $(date +%s) - ${_start} ))
echo "Summary: "
if [ "x$total_ret" != "x0" ]; then
	print_red "HALP! It failed!\n"
else
	print_green "All ok!\n"
fi
echo "$total_ret of $total tests failed. Run-time: $_duration seconds."
exit $total_ret
