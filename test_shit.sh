#!/bin/bash
total_ret=0
total=0

VERBOSE="0"
if [ "x$1" = "x-v" ]; then
	VERBOSE=true
fi
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

# Wannabe
check_url http://wannabe.gathering.org 302 https://wannabe.gathering.org/
check_url https://wannabe.gathering.org 302 https://wannabe.gathering.org/tg18/

# g.o front
check_url http://www.gathering.org/ 302 https://www.gathering.org/tg17/

# TG17
check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
check_url http://www.gathering.org/tg17/ 302 https://www.gathering.org/tg17/
check_url https://www.gathering.org/tg17 302 https://www.gathering.org/tg17/
check_url https://www.gathering.org/tg17/ 200
check_url https://www.gathering.org/tg17/admin/ 302 https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/
check_url https://www.gathering.org/tg17/admin/login/?next=/tg17/admin/ 200

# Archive
check_url http://archive.gathering.org/ 200
for year in 96 97 98 99 0{0..9} 10 15 16; do
	check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://archive.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}/
	check_url http://archive.gathering.org/tg${year}/ 200
done
for year in {11..12}; do
	check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://archive.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}/
	check_url http://archive.gathering.org/tg${year}/ 302 http://archive.gathering.org/tg${year}/en/
	check_url http://archive.gathering.org/tg${year}/en/ 200
done
for year in {13..14}; do
	check_url https://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url https://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://www.gathering.org/tg${year}/ 301 http://archive.gathering.org/tg${year}/
	check_url http://www.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}
	check_url http://archive.gathering.org/tg${year} 301 http://archive.gathering.org/tg${year}/
	check_url http://archive.gathering.org/tg${year}/ 302 http://archive.gathering.org/tg${year}/no/
	check_url http://archive.gathering.org/tg${year}/no/ 200
done
echo
echo "Summary: "
if [ "x$total_ret" != "x0" ]; then
	print_red "HALP! It failed!\n"
else
	print_green "All ok!\n"
fi
echo "$total_ret of $total tests failed."
exit $total_ret
