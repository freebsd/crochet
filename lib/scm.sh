
scm_update_sourcetree ( ) {
    echo "Updating source tree ${FREEBSD_SRC}"
    cd ${FREEBSD_SRC}
    if [ -d .git ]; then
	    git pull > ${WORKDIR}/_.gitpull.log
    elif [ -d .hg ]; then
	    hg pull -u > ${WORKDIR}/_.hgpull.log
    else
	    svn update > ${WORKDIR}/_.svnupdate.log
    fi
    cd ${TOPDIR}
}

scm_get_revision ( ) {
    _PWD=`pwd`
    cd ${FREEBSD_SRC}
    if [ -d .git ]; then
	    SOURCE_VERSION=`git rev-parse --verify --short HEAD`
    elif [ -d .hg ]; then
	    SOURCE_VERSION=`hg id`
    else
	    SOURCE_VERSION="r`svn info |grep Revision: |cut -c11-`"
    fi
    cd $_PWD
    echo "Source version is: ${SOURCE_VERSION:-unknown}";
}


