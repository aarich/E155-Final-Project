/**
 * inputChars.c
 * Alex Rich and Aaron Rosen
 * E155 Final Project
 * Fall 2015
 *
 * This program is called with an HTTP Request with three parameters: l, r, and t.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <python2.7/Python.h>

// Convert an integer into a sign-magnitude 8 bit number,
// then reverse the bits.
char convertToChar(int value)
{
  char byte;
  if (value < 0) {
    value = value * -1;
    byte = (char) value;
    byte = byte | 0x80;
  } else {
    byte = (char) value;
  }
  int i;
  char a;
  char newBite = 0x00;
  for (i = 0; i < 8; i++) {
    a = byte % 2;
    newBite = newBite | (a << (7 - i));
    byte = byte >> 1;
  }
  return newBite;
}

// Print the bits in a byte.
void printBits(char byte)
{
  int i;
  for(i = 7; 0 <= i; i --)
    printf("%d", (byte >> i) & 0x01);
}

// calls Python script sendData.py with the given input parameters
void callPython(char l, char r, char t)
{
  FILE* file;
  int argc;
  char * argv[4];

  char a[1] = {l};
  char b[1] = {r};
  char c[1] = {t};

  argc = 4;
  argv[0] = "sendData.py";
  argv[1] = a;
  argv[2] = b;
  argv[3] = c;

  Py_SetProgramName(argv[0]);
  Py_Initialize();
  PySys_SetArgv(argc, argv);
  file = fopen("sendData.py","r");
  PyRun_SimpleFile(file, "sendData.py");
  Py_Finalize();

  return;
}

// Sends the commands to the vehicle.
bool sendData(char l, char r, char t)
{
  bool success = false;
  callPython(l, r, t);
  return success;
}

// This is executed each time that a GET request is made.
int main(void)
{
  char *data;
  int il, ir, it;
  char l, r, t;

  // Grab the data
  printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1",13,10);
  data = getenv("QUERY_STRING");

  if (data == NULL)
    printf("<p>Error! Error in passing data from form to script.</p>");
  else if (sscanf(data, "l=%d&r=%d&t=%d", &il, &ir, &it) != 3) {
    printf("<P>Error! Invalid data.</p>");
    printf("<p>Data Received: %s, Number of values located: %d</p>", &data, sscanf(data, "l=%d&r=%d&t=%d", &il, &ir, &it));
    printf("l: %d, r: %d, t: %d", il, ir, it);
  }
  else if (il > 127 || il < -127 || ir > 127 || ir < -127 || it > 255)
    printf("<p>The data you entered was invalid. Please remember size restrictions</p>");
  else {
    // Format data correctly and send it
    l = convertToChar(il);
    r = convertToChar(ir);
    t = convertToChar(it);

    // Debug Output
    printf("<P>Raw values entered: <br>r: %d <br>l: %d <br>t: %d</p>", ir, il, it);
    printf("<p>Bit Data: <br>r: ");
    printBits(r);
    printf("<br>l: ");
    printBits(l);
    printf("<br>t: ");
    printBits(t);
    printf("</p>");

    bool success = sendData(l, r, t);

    // printf("Successful Ack? %s.", success ? "true" : "false");
    printf("Successful? unknown (server is not listening for ack)");
  }

  printf("<br><br> <a href=\"../final.html\">Go Back</a>\n");
  return 0;
}

/*
Commands to make this an exebutable with correct permissions:

cd /usr/lib/cgi-bin/
sudo gcc -o inputChars inputChars.c -lpython2.7

sudo chown root:www-data /usr/lib/cgi-bin/inputChars
sudo chmod 010 /usr/lib/cgi-bin/inputChars
sudo chmod u+s /usr/lib/cgi-bin/inputChars

Packages installed with sudo apt-get (may not need bluetooth package)
bluez, python-dev, python-bluez, bluetooth
*/