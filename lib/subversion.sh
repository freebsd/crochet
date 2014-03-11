
svn_update_sourcetree ( ) {
    echo "Updating source tree ${FREEBSD_SRC}"
    cd ${FREEBSD_SRC}
    svn update > ${WORKDIR}/_.svnupdate.log
    cd ${TOPDIR}
}

svn_get_revision ( ) {
    _PWD=`pwd`
    cd ${FREEBSD_SRC}
    SOURCE_VERSION=`svn info |grep Revision: |cut -c11-`
    cd $_PWD
    echo "Source version is: ${SOURCE_VERSION:-unknown}";
}


