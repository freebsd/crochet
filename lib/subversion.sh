
update_sourcetree ( ) {
    echo "Updating source tree ${FREEBSD_SRC}"
    cd ${FREEBSD_SRC}
    svn update > ${WORKDIR}/_.svnupdate.log
    cd ${TOPDIR}
}
