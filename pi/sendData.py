from bluetooth import *
import sys

def main(data):
	target_name = "FPGA"
	bd_addr = findAddress(target_name) #"01:23:45:67:89:AB"
	port = 1
	# sendChars(data, bd_addr, port)

def sendChars(data, bd_addr, port):
	sock = BluetoothSocket( RFCOMM )
	sock.connect((bd_addr, port))

	# PIN is 3332858 (maybe)

	dataToSend = ""
	for c in data:
		dataToSend += c
	sock.send(dataToSend)

	sock.close()

def findAddress(target_name):
	target_address = None
	print "Blah"
	nearby_devices = discover_devices(duration=2, lookup_names=True)

	print "Found %d device(s) <br>" % len(nearby_devices)
	for bdaddr, name in nearby_devices:
		print "--> %s holds \"%s\"<br>" % (bdaddr, name)
		if target_name == name:
			target_address = bdaddr
			break

	if target_address is not None:
		print "Found target bluetooth device with address ", target_address
	else:
		print "Couldn't find target device (%s)" % target_name
	return target_address

def printData(data):
	print 'Cleaned argument list:', str(data)
	print "<br>"
	dataToSend = ""
	for c in data:
		dataToSend += c
	print "Data to send: " + dataToSend + "<br>"

def server():
	server_sock = BluetoothSocket( RFCOMM )
	server_sock.bind(("", PORT_ANY))
	server_sock.listen(1)

	port = server_sock.getsockname()[1]

	uuid = "94f39d29-7d6d-437d-973b-fba39e49d4ee"

	advertise_service( server_sock, "SampleServer",
	                   service_id = uuid,
	                   service_classes = [ uuid, SERIAL_PORT_CLASS ],
	                   profiles = [ SERIAL_PORT_PROFILE ], 
	#                   protocols = [ OBEX_UUID ] 
	                    )
	                   
	print("Waiting for connection on RFCOMM channel %d" % port)

	client_sock, client_info = server_sock.accept()
	print("Accepted connection from ", client_info)

	try:
	    while True:
	        data = client_sock.recv(1024)
	        if len(data) == 0: break
	        print("received [%s]" % data)
	except IOError:
	    pass

	print("disconnected")

	client_sock.close()
	server_sock.close()
	print("all done")

if len(sys.argv) > 1:
	print "<h4>ENTER PYTHON</h4>"
	data = [l[0] for l in sys.argv[1:]]
	printData(data)
	main(data)
	print "<h4>EXITED PYTHON SUCCESSFULLY</h4>"

else:
	data = "a"
	bd_addr = "D8:D1:CB:65:E5:56"
	port = 1
	sendChars(data, bd_addr, port)