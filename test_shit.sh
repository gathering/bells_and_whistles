#!/bin/bash
total_ret=0
total=0
nqueue=0
pjobs=10
_start=$(date +%s)
VERBOSE="0"
YEAR=20
PAST=$(/bin/bash -c "echo $(echo {15..$(( ${YEAR} - 1))})")


cd $(dirname $0)
. util.sh

if [ -d output ]; then rm -r output; fi
mkdir -p output
queue() {
	mkdir -p output/${nqueue}
	cat > output/${nqueue}/script <<_EOF_
#!/bin/bash
_start=\$(date +%s)
VERBOSE=${VERBOSE}
cd \$(dirname \$0)
. ../../util.sh
{
	$*
echo \$? > ret
} | sponge
echo \$(( \$(date +%s) - \${_start} )) > runtime
_EOF_
	chmod +x output/${nqueue}/script
	nqueue=$(( ${nqueue} + 1 ))
}

usage() {
	cat <<_EOF_
$0 [-j jobs] [-v] [-h]

-j jobs		Number of jobs to run in parallell. Default: $pjobs
-v		Verbose mode
-h		Show help and exit
_EOF_
}

while getopts "j:vh" opts; do
	case $opts in
		v)
			VERBOSE=true
			;;
		j)
			pjobs=$OPTARG
			;;
		h)
			usage
			exit 0;
			;;
		*)
			usage 1>&2
			exit 1;
			;;
	esac
done

queue check_ssl www.gathering.org
queue check_ssl gathering.org
queue check_ssl wannabe.gathering.org
queue check_ssl archive.gathering.org
queue check_ssl countdown.gathering.org
queue check_ssl teaser.gathering.org
queue check_ssl rt.gathering.org
queue check_ssl lists.gathering.org

queue check_mixed https://www.gathering.org/
queue check_mixed https://archive.gathering.org/
queue check_mixed https://wannabe.gathering.org/
queue check_mixed https://rt.gathering.org/
queue check_mixed https://lists.gathering.org/

# Lists / Mailman Web
queue check_url http://lists.gathering.org 302 https://lists.gathering.org/
queue check_url https://lists.gathering.org/ 200

# RT
queue check_url http://rt.gathering.org 302 https://rt.gathering.org/
queue check_url https://rt.gathering.org/rt/ 200

# Wannabe
queue check_url http://wannabe.gathering.org 301 https://wannabe.gathering.org/
queue check_url https://wannabe.gathering.org 302 https://wannabe.gathering.org/tg${YEAR}/
queue check_url https://wannabe.gathering.org/tg${YEAR}/Crew/Description 200
queue check_url https://wannabe.gathering.org/tg${YEAR}/Crew 302 https://wannabe.gathering.org/tg${YEAR}/Login
queue check_url https://wannabe.gathering.org/tg${YEAR}/ 302 https://wannabe.gathering.org/tg${YEAR}/Login
queue check_url https://wannabe.gathering.org/tg${YEAR}/Login 200

# g.o front
queue check_url http://www.gathering.org/ 302 https://www.gathering.org/
queue check_url https://www.gathering.org/ 302 https://www.gathering.org/tg${YEAR}
queue check_url http://gathering.org 302 https://www.gathering.org/
queue check_url http://gathering.org/ 302 https://www.gathering.org/
queue check_url http://gathering.org/tg${YEAR} 302 https://www.gathering.org/tg${YEAR}
queue check_url https://gathering.org 302 https://www.gathering.org/tg${YEAR}
queue check_url https://gathering.org/ 302 https://www.gathering.org/tg${YEAR}
queue check_url https://gathering.org/tg${YEAR} 302 https://www.gathering.org
queue check_url https://www.gathering.org/tg${YEAR} 301 /tg${YEAR}/
queue check_url https://www.gathering.org/tg${YEAR}/ 200
queue check_url https://www.gathering.org/api/wp-login.php 200
queue check_url https://www.gathering.org/api/?rest_route=/gathering/v1/menu 200
queue check_mixed https://www.gathering.org/tg${YEAR}
queue find_string https://www.gathering.org/tg${YEAR}/ "The Gathering 20${YEAR}"
queue find_string https://www.gathering.org/tg${YEAR}/page/informasjon "Informasjon"
queue find_string https://www.gathering.org/api/?rest_route=/gathering/v1/menu "/tg${YEAR}"

# Archive
queue check_url http://archive.gathering.org/ 302 https://archive.gathering.org/
queue check_url https://archive.gathering.org/ 200
for year in 96 97 98 99 0{0..9} 10 ${PAST}; do
	queue check_url http://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url https://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 200
	queue check_mixed https://archive.gathering.org/tg${year}/
done
for year in {11..12}; do
	queue check_url http://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url https://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/en/
	queue check_url https://archive.gathering.org/tg${year}/en/ 200
	queue check_mixed https://archive.gathering.org/tg${year}/en/
done
for year in {13..14}; do
	queue check_url http://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url https://gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 301 https://archive.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}
	queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/no/
	queue check_url https://archive.gathering.org/tg${year}/no/ 200
	queue check_mixed https://archive.gathering.org/tg${year}/no/
done

make -j${pjobs} $(echo output/*/script | sed s/script/ret/g)
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
