from bluetooth import *
import sys
import time

def sendChars(data, bd_addr, port):
  sock = BluetoothSocket( RFCOMM )
  sock.connect((bd_addr, port))

  for c in data:
    sock.send(c)
    time.sleep(3)
  sock.close()

def printData(data):
  print 'Cleaned argument list:', str(data)
  print "<br>"
  dataToSend = ""
  for c in data:
    dataToSend += c
  print "Data to send: " + dataToSend + "<br>"

if len(sys.argv) > 1:
  print "<h4>ENTER PYTHON</h4>"
  data = [l[0] for l in sys.argv[1:]]
  printData(data)
  bd_addr = "00:06:66:4F:DC:B1"
  port = 1
  sendChars(data, bd_addr, port)
  print "<h4>EXITED PYTHON SUCCESSFULLY</h4>"

else:
  data = ["a"]
  bd_addr = "00:06:66:4F:DC:B1"
  port = 1
  sendChars(data, bd_addr, port)
