#!/bin/bash
total_ret=0
total=0
nqueue=0
pjobs=10
_start=$(date +%s)
VERBOSE="0"
RETRY_DELAY=5
MAX_RETRIES=2
TIMEOUT=2
PUB_YEAR=23
ACTIVE_CREW_YEAR=24
PAST=$(/bin/bash -c "echo $(echo {10..$(( ${PUB_YEAR} - 1))})")


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
TIMEOUT=${TIMEOUT}
cd \$(dirname \$0)
. ../../util.sh
{
	flaky=0
	ret=0
	try=0
	output=""

	output=\$($*)
	ret=\$?

	# Retry as needed
	while [ \$ret -ne 0 ] && [ \$try -lt ${MAX_RETRIES} ]; do
		sleep ${RETRY_DELAY};
		output=\$($*)
		ret=\$?

		try=\$(( \$try + 1 ))
	done

	# Mark as flaky if passed after retries
	if [ \$ret -eq 0 ] && [ \$try -ne 0 ]; then
		flaky=1
	fi

	echo \$ret > ret
	echo \$flaky > flaky
	echo "\$output (\$try retries)"
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
queue check_ssl tech.gathering.org
queue check_ssl technical.gathering.org
queue check_ssl atlassian.gathering.org
queue check_ssl jira.gathering.org
queue check_ssl confluence.gathering.org

queue check_mixed https://www.gathering.org/
queue check_mixed https://archive.gathering.org/
queue check_mixed https://wannabe.gathering.org/
queue check_mixed https://tech.gathering.org/

# Atlassian
queue check_url http://atlassian.gathering.org 302 https://atlassian.gathering.org/
queue check_url https://atlassian.gathering.org/ 302 https://atlassian.gathering.org/confluence
queue check_url https://atlassian.gathering.org/jira 302 https://atlassian.gathering.org/jira/
queue check_url jira.gathering.org 302 https://jira.gathering.org/
queue check_url confluence.gathering.org 302 https://confluence.gathering.org/
queue check_url https://atlassian.gathering.org/confluence 302 https://atlassian.gathering.org/confluence/

# Wannabe
queue check_url http://wannabe.gathering.org 302 https://wannabe.gathering.org/
queue check_url https://wannabe.gathering.org/tg20 302 https://wannabe4.gathering.org/tg20
queue check_url https://wannabe.gathering.org/tg${ACTIVE_CREW_YEAR}/crew 200
queue check_url https://wannabe.gathering.org/liveness 200
queue check_url https://wannabe.gathering.org/api/auth/liveness 200
queue check_url https://wannabe.gathering.org/api/crew/liveness 200

# tech.g.o
queue check_url http://tech.gathering.org/ 302 https://tech.gathering.org/
queue check_url https://tech.gathering.org/ 200
queue find_string https://tech.gathering.org/ "TG - Technical Blog"
# queue check_url https://tech.gathering.org/wp-login.php 200  ## disablet da denne går til keycloak som er random url hver gang.

# g.o front
queue check_url http://www.gathering.org/ 302 https://www.gathering.org/
queue check_url https://www.gathering.org/ 302 https://www.gathering.org/tg${PUB_YEAR}/
queue check_url http://gathering.org 302 https://gathering.org/
queue check_url http://gathering.org/ 302 https://gathering.org/
queue check_url http://gathering.org/tg${PUB_YEAR} 302 https://gathering.org/tg${PUB_YEAR}
queue check_url https://gathering.org 302 https://www.gathering.org/tg${PUB_YEAR}/
queue check_url https://gathering.org/ 302 https://www.gathering.org/tg${PUB_YEAR}/
queue check_url https://gathering.org/tg${PUB_YEAR} 301 /tg${PUB_YEAR}/
queue check_url https://www.gathering.org/tg${PUB_YEAR} 301 /tg${PUB_YEAR}/
queue check_url https://www.gathering.org/tg${PUB_YEAR}/ 200
# queue check_url https://www.gathering.org/api/wp-login.php 200  ## disablet da denne går til keycloak som er random url hver gang.
queue check_url https://www.gathering.org/api/?rest_route=/gathering/v1/menu 200
queue check_mixed https://www.gathering.org/tg${PUB_YEAR}
queue find_string https://www.gathering.org/tg${PUB_YEAR}/ "The Gathering 20${PUB_YEAR}"
queue find_string https://www.gathering.org/tg${PUB_YEAR}/page/informasjon "Informasjon"
queue find_string https://www.gathering.org/api/?rest_route=/gathering/v1/menu "/tg${PUB_YEAR}"

# Archive - general
queue check_url http://archive.gathering.org/ 302 https://archive.gathering.org/
queue check_url https://archive.gathering.org/ 200

# Archive - years
for year in 96 97 98 99 0{0..9} ${PAST}; do
	queue check_url http://gathering.org/tg${year} 302 https://gathering.org/tg${year}
	queue check_url https://gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url http://gathering.org/tg${year}/ 302 https://gathering.org/tg${year}/
	queue check_url https://gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/
	queue check_url https://www.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	queue check_url http://www.gathering.org/tg${year}/ 302 https://www.gathering.org/tg${year}/
	queue check_url http://www.gathering.org/tg${year} 302 https://www.gathering.org/tg${year}

	if ((10#$year >= 11 && 10#$year <= 14)); then
		queue check_url https://archive.gathering.org/tg${year}/no/ 200
		queue check_url https://archive.gathering.org/tg${year}/en/ 200
		queue check_mixed https://archive.gathering.org/tg${year}/no/
		queue check_mixed https://archive.gathering.org/tg${year}/en/
	else
		queue check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
		queue check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
		queue check_url https://archive.gathering.org/tg${year}/ 200
		queue check_mixed https://archive.gathering.org/tg${year}/
	fi

	if ((10#$year >= 11 && 10#$year <= 12)); then
		queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/en/
	fi

	if ((10#$year >= 13 && 10#$year <= 14)); then
		queue check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/no/
	fi

done

make -j${pjobs} $(echo output/*/script | sed s/script/ret/g)
item=0
while [ $item -lt $nqueue ]; do
	ret=$(cat output/${item}/ret)
	total_ret=$(( ${total_ret} + ${ret} ))

	flaky=$(cat output/${item}/flaky)
	total_flaky=$(( ${total_flaky} + ${flaky} ))

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
echo "$total_ret of $total tests failed. Run-time: $_duration seconds. $total_flaky flaky, but passing tests."
exit $total_ret
