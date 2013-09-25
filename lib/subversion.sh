
update_sourcetree ( ) {
    cd ${FREEBSD_SRC}
    svn update > ${WORKDIR}/_.svnupdate.${CONF}.sh
    cd ${TOPDIR}
}
