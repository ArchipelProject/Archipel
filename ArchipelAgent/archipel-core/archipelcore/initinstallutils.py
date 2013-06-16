#!/usr/bin/python -W ignore::DeprecationWarning
# -*- coding: utf-8 -*-
#
# initinstallutils.py
#
# Copyright (C) 2013 Nicolas Ochem <nicolas.ochem@free.fr>
# Copyright (C) 2013 Antoine Mercadal <antoine.mercadal@archipelproject.org>
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

"""
this file contains methods common to all init-install files
"""

import sqlite3
import sys

def success(msg):
    """
    Print a standardized success message
    @type msg: String
    @param msg: the message to print
    """
    print "\033[32mSUCCESS: %s\033[0m" % msg

def warn(msg):
    """
    Print a standardized warning message
    @type msg: String
    @param msg: the message to print
    """
    print "\033[33mWARNING: %s\033[0m" % msg

def error(msg, exit=True):
    """
    Print a standardized success message
    @type msg: String
    @param msg: the message to print
    @type exit: Boolean
    @param exit: if True, exit after print
    """
    print "\033[31mERROR: %s\033[0m" % msg
    if exit:
        sys.exit(1)

def msg(msg, exit=True):
    """
    Print a standardized neutral message
    @type msg: String
    @param msg: the message to print
    @type exit: Boolean
    @param exit: if True, exit after print
    """
    print "\033[35mMESSAGE: %s\033[0m" % msg

def ask(message, answers=None, default=None):
    question = " * " + message
    if answers and default:
        question += " ["
        for a in answers:
            a = a
            if default and a in (default): a = "\033[32m" + a + "\033[0m"
            question += a + "/"
        question = question[:-1]
        question += "]"
    if not answers and default:
        question += " [\033[32m" + default + "\033[0m]"
    question += " : "
    resp = raw_input(question)
    if default:
        if resp == "": resp = default;
    if answers and default:
        if not resp in answers and len(answers) > 0:
            resp = ask("\033[33mYou must select of the following answer\033[0m", answers, default);
    return resp


def ask_bool(message, default="y"):
    if ask(message, ["y", "n"], default) == "y":
        return True
    return False
