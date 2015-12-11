# sendData.py
# 
# Alex Rich and Aaron Rosen
# arich@hmc.edu
# arosen@hmc.edu
# E155 Final Project
# Fall 2015
#
# This script is called with three commands: l, r, and t, 
# which it passes onto the bluetooth dongle to the 
# hardcoded address stored in bd_addr.

 from bluetooth import *
import sys
import time

def sendChars(data, bd_addr, port):
  print "setting up connection..."
  sock = BluetoothSocket( RFCOMM )
  print "connecting to " + bd_addr + "..."
  try:
    sock.connect((bd_addr, port))
  except:
    sock.close()
    print "<h3>Address in use!</h3>"
    return

  print "sending data..."
  for c in data:
    print c, '...'
    sock.send(c)

  sock.close()

  print "data sent."

  t = int('{:08b}'.format(int(ord(data[2])))[::-1], 2)

  t = 1 + t/10.0
  print "<br>seconds slept: " + str(t) + "..."
  time.sleep(t)

def printData(data):
  print 'Cleaned argument list:', str(data)
  print "<br>"
  dataToSend = ""
  for c in data:
    dataToSend += c
  print "Data to send: " + dataToSend + "<br>"

# IF we've been called with arguments
if len(sys.argv) > 1:
  print "<h5>Enter Python</h5>"
  data = []
  for l in sys.argv[1:]:
    try:
      data.append(l[0])
    except:
      data.append("\x00")
  printData(data)
  # Hardcoded address of BlueSMiRF
  bd_addr = "00:06:66:4F:DC:B1"
  port = 1
  sendChars(data, bd_addr, port)
  print "<h5>Exited Python Succesfully</h5>"

# Run a simple test command
else:
  data = ["a"]
  bd_addr = "00:06:66:4F:DC:B1"
  port = 1
  sendChars(data, bd_addr, port)
  receiveAck(bd_addr)