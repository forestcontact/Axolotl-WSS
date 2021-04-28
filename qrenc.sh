python3 -c 'import sys,pyqrcode; qr =pyqrcode.QRCode(sys.stdin.read(), error="H").eps("output.eps", quiet_zone=10, background="fff", module_color="000")'
