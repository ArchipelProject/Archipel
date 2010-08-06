# set up the search path
$:.unshift( File.join(File.dirname(__FILE__), 'lib') )

# load the code
require 'application'

# clean up the search path
$:.shift
