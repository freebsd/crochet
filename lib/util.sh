#
# Various useful fucntions for configuring a system:
#

# $1 - full line to add to master.passwd
# For example, to set the root password, you might use:
#  util_add_passwd 'root:<passwd>:0:0::0:0:Charlie &:/root:/bin/csh'
# You can add a new user with:
#  util_add_passwd 'me:<passwd>:0:0::0:0:My name:/usr/home/me:/bin/csh'
util_add_passwd ( ) {
    echo "$1" > etc/master.passwd.new
    grep -v "^${1%%:*}:" < etc/master.passwd >> etc/master.passwd.new
    mv -f etc/master.passwd.new etc/master.passwd
    pwd_mkdb -p -d `pwd`/etc etc/master.passwd
}

# Add a group entry for the specified user.  To add 'me' to group 'wheel':
#  util_add_user_group me wheel
util_add_user_group ( ) {
    sed -i -e '/^'"$2"':/ {s/[^:]$/&,/;s/$/'"$1"'/;}' etc/group
}


