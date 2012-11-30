#!/usr/bin/python
import subprocess

msg = "Amt:$100.To:Bob.From:Alice.Seq:PQ123.Comment:Here's the money I owe you."
password = "Password"
newMsg = "Eve"
newMsgLoc = 12


sslout,sslerror = subprocess.Popen(
    ['openssl', 'enc', '-aes-256-cbc', '-nosalt', '-p', '-k', password],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE
    ).communicate(msg)

keyline, ivline, cipher = sslout.split("\n", 2)

keyHex = keyline.split("=")[1]
IVHex = ivline.split("=")[1]

IV = bytearray(IVHex.decode("hex"))

newIV = IV
for index in range(newMsgLoc, newMsgLoc + len(newMsg)):
	newIV[index] = IV[index] ^ ord(msg[index]) ^ ord(newMsg[index - newMsgLoc])

newIVHex = ''.join('%02X' % byte for byte in newIV)

newMsg,sslerror = subprocess.Popen(
    ['openssl', 'enc', '-d', '-aes-256-cbc', '-nosalt', '-K', keyHex, '-iv', newIVHex],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE
    ).communicate(cipher)

print "    IV=" + IVHex
print "   NIV=" + newIVHex
print " cipher" + ''.join('%02X' % ord(byte) for byte in cipher[0:16])
print "   msg=" + ''.join('%02X' % ord(byte) for byte in msg[0:16])
print "newMsg=" + ''.join('%02X' % ord(byte) for byte in newMsg[0:16])
print newMsg
print sslerror