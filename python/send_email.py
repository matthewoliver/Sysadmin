#!/usr/bin/env python

import sys
import smtplib
import os
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.Utils import COMMASPACE, formatdate
from email import Encoders
mailserver="172.16.101.68"

def send_email(send_from, send_to, subject, text, files=[], server="localhost"):
  assert type(send_to)==list
  assert type(files)==list

  msg = MIMEMultipart()
  msg['From'] = send_from
  msg['To'] = COMMASPACE.join(send_to)
  msg['Date'] = formatdate(localtime=True)
  msg['Subject'] = subject

  msg.attach( MIMEText(text) )

  for f in files:
    part = MIMEBase('application', "octet-stream")
    part.set_payload( open(f,"rb").read() )
    Encoders.encode_base64(part)
    part.add_header('Content-Disposition', 'attachment; filename="%s"' % os.path.basename(f))
    msg.attach(part)

  smtp = smtplib.SMTP(server)
  smtp.sendmail(send_from, send_to, msg.as_string())
  smtp.close()

if __name__ == "__main__":
	args = sys.argv[1:]
	if len(args) < 4:
		print sys.argv[0] + " send_from send_to[,send_to] \"subject\" \"message\""
		sys.exit(0)
	
	send_from = args[0]
	send_to = [address for address in args[1].split(',')]
	subject = args[2]
	msg = args[3]
	
	send_email(send_from, send_to, subject, msg, server=mailserver)
