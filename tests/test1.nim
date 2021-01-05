import unittest, netmap

var nm = Netmap()
test "open netmap device":
  nm.open("netmap:eth0")

test "close netmap device":
  nm.close()



