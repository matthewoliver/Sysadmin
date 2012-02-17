# NAGIOS SHED TOOLS SETTINGS FILE
# ===============================

# Set the location of nagios configuration file. 
NAGIOS_CONFIG="/etc/nagios/nagios.cfg"

# Set the the nagios user who will be sheduling the downtime.
# NOTE: This is a nagios user _NOT_ a posix user.  
USER="nagiosadmin"

# Set the path to the nagios cmd.cgi stored under nagios' cgi-bin directory. 
# 32 BIT
NAGIOS_CMD="/usr/lib/nagios/cgi/cmd.cgi"
# 64 BIT
#NAGIOS_CMD="/usr/lib64/nagios/cgi-bin/cmd.cgi" 
