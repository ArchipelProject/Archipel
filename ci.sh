#!/bin/bash
# 
# ci.sh
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

ARCHIPEL_CLIENT_BUILD_DIR="ArchipelClient/Build/release/Archipel"
ARCHIPEL_CLIENT_BUILD_COMMAND="ArchipelClient/build.py Release"
PUBLICATION_DIR="/var/www/html/"
PUBLICATION_OWNER="apache:apache"
PUBLICATION_RIGHTS="755"

${ARCHIPEL_CLIENT_BUILD_COMMAND};
RESULT=$?


echo result of build is ${RESULT}

if [[ $RESULT == 0 ]]; then
    cp -a ${ARCHIPEL_CLIENT_BUILD_DIR} ${PUBLICATION_DIR}
    chown -R ${PUBLICATION_OWNER} ${PUBLICATION_DIR}
    chmod -R ${PUBLICATION_RIGHTS} ${PUBLICATION_DIR}
else
    echo build failed.
fi

exit $RESULT