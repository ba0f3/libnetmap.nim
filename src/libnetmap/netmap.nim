import netmap/user
type
  NetmapError = object of IOError

type Netmap* = object
  nm_desc*: ptr nm_desc


proc open*(nm: var Netmap, ifname: string) =
  ## Open the netmap device
  nm.nm_desc = nm_open(ifname.cstring, nil, NM_OPEN_NONE, nil)
  if nm.nm_desc == nil:
    raise newException(NetmapError, "Cannot open netmap device")

proc close*(nm: var Netmap) =
  ## Close he netmap device
  discard nm_close(nm.nm_desc)
  nm.nm_desc = nil

proc mmap*(nm: var Netmap, parent: Netmap): bool =
  ## Do mmap or inherit from parent
  result = nm_mmap(nm.nm_desc, parent.nm_desc) == 0

proc inject*(nm: var Netmap, buf: string): int =
  result = nm_inject(nm.nm_desc, buf.cstring, buf.len.csize_t)

proc dispatch*(nm: var Netmap, cnt: int32, cb: nm_cb_t, arg: cstring): int =
  result = nm_dispatch(nm.nm_desc, cnt, cb, arg)

proc nextpkt*(nm: var Netmap, hdr: ptr nm_pkthdr): cstring =
  result = nm_nextpkt(nm.nm_desc, hdr)