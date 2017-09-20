#!/bin/sh

# --- Create named pipe ---
PIPE='/tmp/serverpipe'
[ -p $PIPE ] || mkfifo $PIPE

serve() {
	# --- Parse request ---
	read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION
	# --- Display request ---
	echo "$REQUEST_METHOD $REQUEST_URI $REQUEST_HTTP_VERSION" 1>&2
	while read -r line ; do
		echo "$line" 1>&2
		line=$(echo "$line" | tr -d '[\r\n]')
		[ -z "$line" ] && break
	done
	# --- Serve content ---
	if [ -f ".$REQUEST_URI" ]; then
		echo "HTTP/1.0 200 OK\n"
		cat ".$REQUEST_URI"
	else
		echo "HTTP/1.1 404 Not Found\n"
		echo "404 Not Found"
	fi
}

# --- Run process ---
while : ; do
	cat "$PIPE" | nc -l 8000 | serve 1> "$PIPE"
	[ $? != 0 ] && break
done
