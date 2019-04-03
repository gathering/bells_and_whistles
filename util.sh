#!/bin/bash
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
/^[Ll]ocation: / {
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
	if (varnish != 1 && match(url, "www.gathering.org") && santaclause != real) {
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
	return $ret
}

check_ssl() {
	_in=$(openssl s_client -host $1 -port 443 -servername $1 -attime $(date +%s --date='now + 14 days') -verify_hostname $1 <<<"" 2>&1 | grep 'Verify return' | sed 's/^\s*//g')
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
	return $ret
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
	return $ret
}

find_string() {
	total=$(( ${total} + 1 ))
	if curl -s "$1" | grep $2 > /dev/null
	then
		print_green "OK     "
		echo "| found string $2 in $1"
	else
		print_red "FAILED "
		echo "| failed to find $2 in $1"
		total_ret=$(( ${total_ret} + 1 ))
		return 1;
	fi
}
