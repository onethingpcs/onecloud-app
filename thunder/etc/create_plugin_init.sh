#!/bin/sh
PACKAGE=$1
START=50
STOP=50
INIT_SCRIPT="/misc/etc/init.d/$PACKAGE"
EXPORT_PATH="/bin /sbin /usr/bin /usr/sbin"
EXPORT_LIB="/lib /usr/lib /usr/share/lib"

create_init_file() {
    echo "#!/bin/sh" > $INIT_SCRIPT
    echo "#This script file is auto generated,do not modified it " > $INIT_SCRIPT
    echo "START=$START" >> $INIT_SCRIPT
    echo "STOP=$STOP" >> $INIT_SCRIPT
    echo "EXPORT_PATH=\"$EXPORT_PATH\"" >> $INIT_SCRIPT
    echo "EXPORT_LIB=\"$EXPORT_LIB\"" >> $INIT_SCRIPT
    echo "PACKAGE=$PACKAGE" >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
    echo "export_env () {" >> $INIT_SCRIPT
    echo 'for dir in $EXPORT_PATH' >> $INIT_SCRIPT
    echo 'do' >> $INIT_SCRIPT
    echo 'export PATH=$PATH:/app/miner.$PACKAGE.plugin/$dir' >> $INIT_SCRIPT
    echo 'done' >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
    echo 'for dir in $EXPORT_LIB' >> $INIT_SCRIPT
    echo 'do' >> $INIT_SCRIPT
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/app/miner.$PACKAGE.plugin/$dir' >> $INIT_SCRIPT
    echo 'done' >> $INIT_SCRIPT
    echo "}" >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
    echo "start () {" >> $INIT_SCRIPT
    echo "export_env" >> $INIT_SCRIPT
    echo "export PLUGIN_ROOT=/app/miner.$PACKAGE.plugin" >> $INIT_SCRIPT
    echo "ulimit -s 1024" >> $INIT_SCRIPT
    echo "sh /app/miner.$PACKAGE.plugin/start.sh " >> $INIT_SCRIPT
    echo "}" >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
    echo "stop () {" >> $INIT_SCRIPT
    echo "export PLUGIN_ROOT=/app/miner.$PACKAGE.plugin" >> $INIT_SCRIPT
    echo "sh /app/miner.$PACKAGE.plugin/stop.sh " >> $INIT_SCRIPT
    echo "}" >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
    echo "restart () {" >> $INIT_SCRIPT
    echo "stop " >> $INIT_SCRIPT
    echo "sleep 1 " >> $INIT_SCRIPT
    echo "start " >> $INIT_SCRIPT
    echo "}" >> $INIT_SCRIPT
    echo "" >> $INIT_SCRIPT
}

create_init_file
chmod a+x $INIT_SCRIPT
chown $PACKAGE $INIT_SCRIPT
chgrp $PACKAGE $INIT_SCRIPT
