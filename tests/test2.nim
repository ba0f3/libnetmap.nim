import posix, netmap, sugar

var nm = Netmap()
nm.open("netmap:eth0")

var pfd = TPollfd()
pfd.fd = nm.nm_desc.fd
pfd.events = POLLIN

type ethhdr = object
  dest: array[6, char]
  src: array[6, char]
  proto: uint16




var running = true

proc cb() {.noconv.} =
  echo "bye!"
  running = false

setControlCHook(cb)

var
  ret: cint
  buffer: cstring
  hdr: nm_pkthdr
  eh: ptr ethhdr
while running:
  ret = poll(addr pfd, 1, -1)
  if ret < 0:
    continue

  if (pfd.events and POLLIN) > 0:
    buffer = nm.nextpkt(addr hdr)
    eh = cast[ptr ethhdr](buffer)
    echo eh[]

nm.close()



