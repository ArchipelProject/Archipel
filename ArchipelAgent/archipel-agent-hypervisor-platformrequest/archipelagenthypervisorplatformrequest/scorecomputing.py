# 
# scorecomputing.py
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


class TNBasicPlatformScoreComputing (object):
    """
    this class is a basic score computing. If you want to provide
    your own score computing unit, you can subclass this and implement
    your own computing system
    """
    
    ### Initialization
    
    def __init__(self):
        """
        put custom initialization here
        """
        pass
    
    
    
    ## Plugin
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Platform Request Base Score Computing Unit"
        plugin_identifier              = "basecomputingunit"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []
        
        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
    
    
    
    ## Score computing
    
    def score(self, action=None):
        """
        perform the score. The highest the score, the highest the 
        you got chance to perform the action. If you want to decline
        the performing of the action, return 0.0 or None. the max score
        you can return is 1.0 (so basically see it as a percentage)
        
        @type action: string
        @param action: the name of the action if you want to use it to compute the score (optionnal)
        
        @rtype: float
        @return: the score
        """
        
        ## awesome computing goes here
        
        import random
        return random.random() # yeah! that's a big computing!
    

