#
# set the email address for notifications
#
# $EMAIL is set by 'option Email <address>'
#

EMAIL=

email_status ( ) {
    if [ -n "$EMAIL" ]; then
        echo "$1" | mail -s "$2" $EMAIL
    fi
}
