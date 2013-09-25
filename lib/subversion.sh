
update_sourcetree ( ) {
    cd ${FREEBSD_SRC}
    svn update > ${WORKDIR}/_.svnupdate.log
    cd ${TOPDIR}
}
