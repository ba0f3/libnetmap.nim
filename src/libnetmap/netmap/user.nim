import posix, netmap, legacy

{.passC: "-DNETMAP_WITH_LIBS".}

template NETMAP_OFFSET(t, p, offset: untyped): untyped = cast[t](cast[int](ptr) + offset)

template NETMAP_IF*(base, ofs: untyped): untyped =
  NETMAP_OFFSET(ptr netmap_if, base, ofs)

template NETMAP_TXRING*(nifp, index: untyped): untyped =
  NETMAP_OFFSET(ptr netmap_ring, nifp, index)

template NETMAP_RXRING*(nifp, index: untyped): untyped =
  NETMAP_OFFSET(ptr netmap_ring, nifp, nifp.ring_ofs[index + nifp.ni_tx_rings + nifp.ni_host_tx_rings])

template NETMAP_BUF*(ring, index: untyped): untyped =
  ring + ring.buf_ofs + index * ring.nr_buf_size

template NETMAP_BUF_IDX*(ring, buf: untyped): untyped =
  (buf - ring + ring.buf_ods) / ring.nr_buf_size


template NETMAP_ROFFSET*(ring, slot: untyped): untyped =
  ((slot).pptr and (ring).offset_mask)

template NETMAP_WOFFSET*(ring, slot, offset: untyped): void =
  while true:
    (slot).pptr = ((slot).pptr and not (ring).offset_mask) or
      ((offset) and (ring).offset_mask)
  if not 0: break

template NETMAP_BUF_OFFSET*(ring, slot: untyped): untyped =
  (NETMAP_BUF(ring, (slot).buf_idx) + NETMAP_ROFFSET(ring, slot))


{.push importc, header: "/usr/local/include/net/netmap_user.h".}

proc nm_ring_next*(r: ptr netmap_ring, i: uint32): uint32 {.inline.}

proc nm_tx_pending*(r: ptr netmap_ring): bool {.inline.}

proc nm_ring_space*(ring: ptr netmap_ring): uint32 {.inline.}

{.pop.}

const
  NM_ERRBUF_SIZE = 512

type
  nm_pkthdr* = object
    ts*: Timeval
    caplen*: uint32
    len: uint32
    flags*: uint64
    d*: ptr nm_desc
    slot*: ptr netmap_slot
    buf*: ptr uint8

  nm_stat* = object
    ps_recv*: int
    ps_drop*: int
    ps_ifdrop*: int
    bs_capt*: int

  nm_desc* = object
    self*: ptr nm_desc
    fd*: int32
    mem*: pointer
    memsize*: csize_t
    dome_mmap*: int
    nifp*: ptr netmap_if
    first_tx_ring*: uint16
    last_tx_ring*: uint16
    cur_tx_ring*: uint16
    first_rx_ring*: uint16
    last_rx_ring*: uint16
    cur_rx_ring*: uint16
    req*: nmreq
    hdr*: nm_pkthdr
    some_ring*: ptr netmap_ring
    buf_start*: pointer
    buf_end*: pointer
    snaplen*: int32
    promisc*: int32
    to_ms*: int32
    errbuf*: pointer
    if_flags*: uint32
    if_reqcap*: uint32
    if_curcap*: int32
    st*: nm_stat
    msg*: array[NM_ERRBUF_SIZE, char]

  nm_cb_t* = proc(a1: cstring, a2: ptr nm_pkthdr, a3: cstring)

  NM_OPEN_FLAG* = enum
    NM_OPEN_NONE = 0
    NM_OPEN_NO_MMAP = 0x00040000 ##  reuse mmap from parent
    NM_OPEN_IFNAME = 0x00080000  ##  nr_name, nr_ringid, nr_flags
    NM_OPEN_ARG1 = 0x00100000
    NM_OPEN_ARG2 = 0x00200000
    NM_OPEN_ARG3 = 0x00400000
    NM_OPEN_RING_CFG = 0x00800000 ##  tx|rx rings|slots

{.push importc, header: "/usr/local/include/net/netmap_user.h".}
proc nm_open*(ifname: cstring, req: ptr nmreq, flags: NM_OPEN_FLAG, arg: ptr nm_desc): ptr nm_desc
proc nm_close*(a2: ptr nm_desc): int
proc nm_mmap*(a2: ptr nm_desc, a3: ptr nm_desc): int
proc nm_inject*(a2: ptr nm_desc, a3: pointer, a4: csize_t): int
proc nm_dispatch*(a2: ptr nm_desc, a3: int32, a4: nm_cb_t, a5: cstring): int
proc nm_nextpkt*(a2: ptr nm_desc, a3: ptr nm_pkthdr): cstring
proc nm_parse*(ifname: cstring, d: ptr nm_desc, err: cstring): int
proc nm_is_identifier*(s: cstring, e: cstring): int
{.pop.}
