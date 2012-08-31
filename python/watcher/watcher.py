#/usr/bin/env python

import sys
import threading

class Proc(threading.Thread):
        TIME = 10
        TRIGGER = 30
        timer = None
        counter = 0
        ip = ""
        pq = None
        triggered = False

        def __init__(self):
                super(Proc, self).__init__()
                self.timer = threading.Timer(self.TIME, self.timeEvent)
                self.event = threading.Event()
                self.cond = threading.Condition()


        def run(self):
                #self.event.set()
                self.timer.start()
                #self.event.wait()


        def setIP(self, ip, process_queue):
                self.ip = ip
                self.counter+=1
                self.pq = process_queue

        def hit(self):
                #print "hit! " + self.ip
                self.cond.acquire()
                self.counter+=1
                if self.counter > self.TRIGGER:
                        print self.ip + " [" + str(self.counter) + "]"

                self.timer.cancel()
                self.timer = threading.Timer(self.TIME, self.timeEvent)
                self.timer.start()
                self.cond.release()

        def timeEvent(self):
                #print "Killing Thread"
                #self.event.set()
                self.pq.pop(self.ip)
                #print "num Threads: " + str(len(self.pq))
                #self.Exit()

process_queue = {}
whitelist = ("")
for line in sys.stdin:
        line = line.strip()
        if line in whitelist:
                continue
        if process_queue.has_key(line):
                process_queue[line].hit()
        else:
                p = Proc()
                p.start()
                p.setIP(line, process_queue)
                process_queue[line] = p


