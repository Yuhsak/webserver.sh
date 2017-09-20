#!/bin/sh

# --- Create named pipe ---
PIPE='/tmp/serverpipe'
[ -p $PIPE ] || mkfifo $PIPE

IFS_BACKUP=$IFS

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
	IFS=$'\n'
	# --- Decode URIComponent ---
	FILE_PATH=".`echo $REQUEST_URI | nkf --url-input`"
	# --- Serve file ---
	if [ -f "$FILE_PATH" ]; then
		echo "HTTP/1.0 200 OK\n"
		cat $FILE_PATH
	# --- Display directory listing ---
	elif [[ $REQUEST_URI =~ /$ ]]; then
		echo "HTTP/1.0 200 OK\n"
		echo "<html><head><meta charset='utf-8' /></head><body>"
		echo $(directoryIndex $FILE_PATH)
		echo "</body></html>"
	# --- When the file doesn't exist ---
	else
		echo "HTTP/1.1 404 Not Found\n"
		echo "404 Not Found"
	fi
	IFS=$IFS_BACKUP
}

directoryIndex() {
	echo "<ul>"
	for file in `ls -p $1`; do
		echo "<li><a href='${file}'>${file}</a></li>"
	done
	echo "</ul>"
}

# --- Run process ---
while : ; do
	cat "$PIPE" | nc -l 8000 | serve 1> "$PIPE"
	[ $? != 0 ] && break
done
