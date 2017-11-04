#!/bin/bash
total_ret=0
total=0
_start=$(date +%s)
VERBOSE="0"
if [ "x$1" = "x-v" ]; then
	VERBOSE=true
fi
check=0

rm -r output/
gaffel()
{
	mkdir -p output/$1
	cd output/$1
	shift
	$* > stdout 2>stderr
	echo $? > ret
}

forget()
{
	stdout[$1]="$(cat output/$1/stdout)"
	stderr[$1]="$(cat output/$1/stderr)"
	ret[$1]="$(cat output/$1/ret)"
}

fire()
{
	gaffel $check $* &
	check=$(( $check + 1 ))
}
print_green() {
	if [ "x$COLOR" != "xNO"  ]; then
		echo -en "\033[32m$*\033[0m";
	else
		echo -en "$*"
	fi
}
print_red() {
	if [ "x$COLOR" != "xNO"  ]; then
		echo -en "\033[31m$*\033[0m";
	else
		echo -en "$*"
	fi
}

eat_it() {
	http -ph GET "$1" | awk -v arg1="$2" -v arg2="$3" -v url="$1" -v verbose=$VERBOSE '
/^HTTP\/1.1/ {
	status=$2
}
/^Location: / {
	location=$2
}
/^X-Varnish: / {
	varnish=1
}

END {
	if (status != arg1) {
		if (verbose)
			print "\tWrong status. Got " status " expected " arg1;
		ret++;
	}
	gsub("\r$","",location);
	if (location != arg2) {
		if (verbose)
			print "\tMismatch between expected Location-header and real.\n\tExpected: \"" arg2 "\"\n\tGot:      \"" location "\"."
		ret++;
	}
	if (varnish != 1 && match(url, "www.gathering.org")) {
		if (verbose)
			print "\tNO VARNISH"
		ret++;
	}
	if (!verbose)
		print status":"arg1
	if (ret == 0)
		exit 0;
	else
		exit 1;
}
'
	return $?
}

check_url() {
	OUT=$(eat_it "$@")
	ret=$?
	if [  "x$ret" = "x0" ]; then
		print_green "OK     "
		echo "| $1"
	else
		print_red "FAILED "
		if [ "x$VERBOSE" != "xtrue" ]; then
			echo -n "| $OUT "
		fi
		echo "| $1"
		if [ "x$VERBOSE" = "xtrue" ]; then
			echo -e "$OUT"
		fi
	fi
	total_ret=$(( ${total_ret} + ${ret} ))
	total=$(( ${total} + 1 ))
	return $?
}

check_ssl() {
	_in=$(openssl s_client -connect $1 -port 443 -attime $(date +%s --date='now + 14 days') -verify_hostname $1 <<<"" 2>&1 | grep 'Verify return' | sed 's/^\s*//g')
	_ok="Verify return code: 0 (ok)"
	ret=0
	if [ "x$_in" != "x$_ok" ]; then
		print_red "FAILED "
		echo -e "| SSL verification failed for $1: $_in"
		ret=1
	else
		print_green "OK     "
		echo "| SSL on $1"
		ret=0
	fi
	total_ret=$(( ${total_ret} + ${ret} ))
	total=$(( ${total} + 1 ))
	return $?
}

check_mixed() {
	_out=$(! wget -p $1 --delete-after 2>&1| grep http://)
	ret=$?
	if [  "x$ret" = "x0" ]; then
		print_green "OK     "
		echo "| no mixed content: $1"
	else
		print_red "FAILED "
		echo "| mixed content at: $1"
	fi
	total_ret=$(( ${total_ret} + ${ret} ))
	total=$(( ${total} + 1 ))
	return $?
}	
fire check_ssl www.gathering.org
fire check_ssl gathering.org
fire check_ssl wannabe.gathering.org
fire check_ssl archive.gathering.org
fire check_ssl countdown.gathering.org
fire check_ssl teaser.gathering.org

fire check_mixed https://www.gathering.org/
fire check_mixed https://archive.gathering.org/
fire check_mixed https://wannabe.gathering.org/

# Wannabe
fire check_url http://wannabe.gathering.org 302 https://wannabe.gathering.org/
fire check_url https://wannabe.gathering.org 302 https://wannabe.gathering.org/tg18/

# g.o front
fire check_url http://www.gathering.org/ 302 https://www.gathering.org/tg17/

# TG17
fire check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
fire check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
fire check_url https://www.gathering.org/tg17 302 https://www.gathering.org/tg17/
fire check_url https://www.gathering.org/tg17/ 200
fire check_url https://www.gathering.org/tg17/admin/ 302 https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/
fire check_url https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/ 200

# Archive
fire check_url http://archive.gathering.org/ 302 https://archive.gathering.org/
fire check_url https://archive.gathering.org/ 200
for year in 96 97 98 99 0{0..9} 10 15 16; do
	fire check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	fire check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	fire check_url https://archive.gathering.org/tg${year}/ 200
	fire check_mixed https://archive.gathering.org/tg${year}/
done
for year in {11..12}; do
	fire check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	fire check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	fire check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/en/
	fire check_url https://archive.gathering.org/tg${year}/en/ 200
	fire check_mixed https://archive.gathering.org/tg${year}/en/
done
for year in {13..14}; do
	fire check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	fire check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	fire check_url http://archive.gathering.org/tg${year} 302 https://archive.gathering.org/tg${year}
	fire check_url https://archive.gathering.org/tg${year} 301 https://archive.gathering.org/tg${year}/
	fire check_url https://archive.gathering.org/tg${year}/ 302 https://archive.gathering.org/tg${year}/no/
	fire check_url https://archive.gathering.org/tg${year}/no/ 200
	fire check_mixed https://archive.gathering.org/tg${year}/no/
done
echo
wait

a=0
while [ $a -lt $check ]; do
	forget $a
	a=$(( $a + 1 ))
done
a=0
while [ $a -lt $check ]; do
	echo -e "${stdout[$a]}"
	total_ret=$(( ${total_ret} + ${ret[$a]} ))
	total=$(( ${total} + 1 ))
	a=$(( $a + 1 ))
done
_duration=$(( $(date +%s) - ${_start} ))
echo "Summary: "
if [ "x$total_ret" != "x0" ]; then
	print_red "HALP! It failed!\n"
else
	print_green "All ok!\n"
fi
echo "$total_ret of $total tests failed. Run-time: $_duration seconds."
exit $total_ret
