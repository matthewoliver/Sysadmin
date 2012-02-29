#!/bin/bash
#By default the title is the name of the file to be cat'ed, the only parameter sent in. 

echo "<html>"
echo "<head><title>$1</title></head>"
echo "<body>"
echo "<pre>"
cat $1
echo "</pre>"
echo "</body>"
echo "</html>"
