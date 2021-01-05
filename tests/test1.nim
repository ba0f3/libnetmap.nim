import unittest, netmap

test "open netmap device":
  var nm = Netmap()
  nm.open("netmap:eth0")

  echo nm.nm_desc[]

  nm.close()



