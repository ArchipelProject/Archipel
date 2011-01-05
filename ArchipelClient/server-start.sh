#!/bin/bash
#
# server-start.sh
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


if [[ `which jackup` == "" ]]; then
    echo You need jack server. please run 'sudo tusk install jack'
    exit -1
fi

if [ -f /tmp/archipel-dev-server-pid ]; then
    echo Server already start with PID `cat /tmp/archipel-dev-server-pid`
    exit -2
fi

jackup -e "require('jack/file').File('.')" -E deployment  > /dev/null 2>&1 &
PID=$!
echo $PID > /tmp/archipel-dev-server-pid

if [[ $? == 0 ]]; then
    echo "server started at 127.0.0.1:8080 (PID $PID)"
else
    echo "Error, cannot start server."
fi

exit 0