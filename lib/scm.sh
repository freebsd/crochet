
scm_update_sourcetree ( ) {
    echo "Updating source tree ${FREEBSD_SRC}"
    cd ${FREEBSD_SRC}
    if [ -d .git ]; then
	    git pull > ${WORKDIR}/_.gitpull.log
    elif [ -d .hg ]; then
	    hg pull -u > ${WORKDIR}/_.hgpull.log
    elif svn --version > /dev/null; then
	    svn update > ${WORKDIR}/_.svnupdate.log
    else
	    svnlite update > ${WORKDIR}/_.svnupdate.log
    fi
    cd ${TOPDIR}
}

scm_get_revision ( ) {
    _PWD=`pwd`
    cd ${FREEBSD_SRC}
    if [ -d .git ]; then
	if git rev-parse > /dev/null 2>&1; then
	    SOURCE_VERSION=`git rev-parse --verify --short HEAD`
	else
	    SOURCE_VERSION="git-rev-error"
	fi
    elif [ -d .hg ]; then
	if hg id -i > /dev/null 2>&1; then
	    SOURCE_VERSION=`hg id -i`
	else
	    SOURCE_VERSION="hg-rev-error"
	fi
    elif [ -d .svn ]; then
	if svn info > /dev/null 2>&1; then
	    SOURCE_VERSION=`svnversion ${FREEBSD_SRC}`
	elif svnlite info > /dev/null 2>&1; then
	    SOURCE_VERSION=`svnliteversion ${FREEBSD_SRC}`
	else
	    SOURCE_VERSION="svn-rev-error"
	fi
    fi
    cd $_PWD
    echo "Source version is: ${SOURCE_VERSION:-unknown}";
}


