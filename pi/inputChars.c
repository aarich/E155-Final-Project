// Control the tank given the basic commands.
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <python2.7/Python.h>

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

  return byte;
}

void printBits(char byte)
{
  int i;
  for(i = 7; 0 <= i; i --)
    printf("%d", (byte >> i) & 0x01);
}

void callPython(char l, char r, char t)
{
  FILE* file;
  int argc;
  char * argv[4];

  char a[1] = {t};
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

bool sendData(char l, char r, char t)
{
  bool success = false;
  callPython(l, r, t);
  // TODO send the data over bluetooth!
  return success;
}

int main(void)
{
  char *data;
  int il, ir, it;
  char l, r, t;
  printf("%s%c%c\n", "Content-Type:text/html;charset=iso-8859-1",13,10);
  printf("<h1>Robot Under Control (Debug Page)</h1>");

  data = getenv("QUERY_STRING");

  if (data == NULL)
    printf("<p>Error! Error in passing data from form to script.</p>");
  else if (sscanf(data, "l=%d&r=%d&t=%d", &il, &ir, &it) != 3) {
    printf("<P>Error! Invalid data.</p>");
    printf("<p>Data Received: %s, Number of values located: %d</p>", 
      &data, sscanf(data, "l=%d&r=%d&t=%d", &il, &ir, &it));
    printf("l: %d, r: %d, t: %d", il, ir, it);
  }
  else if (il > 127 || il < -127 || ir > 127 || ir < -127 || it > 255)
    printf("<p>The data you entered was invalid. Please remember size 
      restrictions</p>");
  else {
    // TODO Convert these to sign magnitude!
    l = convertToChar(il);
    r = convertToChar(ir);
    t = (char) it;

    // Debug Output
    printf("<P>Raw values entered: <br>r: %d <br>l: %d <br>t: %d</p>",
     ir, il, it);
    printf("<P>Chars to be transmitted (may be invisible): 
      <br>r: %c <br>l: %c <br>t: %c</p>", r, l, t);
    printf("<p>Bit Data: <br>r: ");
    printBits(r);
    printf("<br>l: ");
    printBits(l);
    printf("<br>t: ");
    printBits(t);
    printf("</p>");

    bool success = sendData(l, r, t);

    printf("Data sent: %s.", success ? "true" : "false");
  }

  printf("<br><br> <a href=\"../final.html\">Go Back</a>");
  return 0;
}

/*
sudo chown root:www-data /usr/lib/cgi-bin/inputChars
sudo chmod 010 /usr/lib/cgi-bin/inputChars
sudo chmod u+s /usr/lib/cgi-bin/inputChars

packages installed: bluez, python-dev, python-bluez 
(maybe bluetooth is needed?)
*/