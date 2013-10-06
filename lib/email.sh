
email_status ( ) {

    if [ -n "$EMAIL" ]; then
        echo "$1" | mail -s "$2" $EMAIL
    fi
}
