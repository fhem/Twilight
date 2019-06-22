#!/usr/bin/env bash

test -z "$APT_BIN" && APT_BIN="apt"

function install_fhem {
    echo
    echo
    echo Installing FHEM
    
    sources="/etc/apt/sources.list.d/fhem.list"

    # add fhem sources and install
    wget -qO - http://debian.fhem.de/archive.key | apt-key add -
    echo "deb http://debian.fhem.de/nightly/ /" >> "${sources}"
    ${APT_BIN} update
    ${APT_BIN} install -y fhem

    # restore original
    rm "${sources}"
    ${APT_BIN} update
}

function install_cfg {
    rm -rf /opt/fhem/fhem.cfg
    ln -s /vagrant/deployment/fhem.cfg /opt/fhem/fhem.cfg
}

function install_twilight {
    rm -rf /opt/fhem/FHEM/59_Twilight.pm
    ln -s /vagrant/FHEM/59_Twilight.pm /opt/fhem/FHEM/59_Twilight.pm
}

function update_commandref {
    cwd=$(pwd)
    cd /opt/fhem
    perl contrib/commandref_join.pl
    cd $cwd
}

function add_script {
    ln -s /vagrant/deployment/reload_fhem.sh /usr/bin/reload-fhem
    chmod +x /usr/bin/reload-fhem
}

install_fhem
install_cfg
install_twilight
update_commandref
add_script

service fhem restart