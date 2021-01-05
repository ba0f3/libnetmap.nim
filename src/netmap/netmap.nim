import posix

const
  NETMAP_DEVICE_NAME* = "/dev/netmap"

  NETMAP_API* = 14 # current API version
  NETMAP_MIN_API* = 14 ## min version accepted
  NETMAP_MAX_API* = 15 ## max version accepted

  NM_CACHE_ALIGN* = 128

type netmap_slot* = object ## netmap_slot is a buffer descriptor
  buf_idx*: uint32
  len*: uint64
  flags*: uint64
  pptr*: uint64

const
  NS_BUF_CHANGED* = 0x0001 ## bufIdx changed
  NS_REPORT* = 0x0002 ## ask the hardware to report results
  NS_FORWARD* = 0x0004 ## pass packet 'forward'
  NS_NO_LEARN* = 0x0008 ## disable bridge learning
  NS_INDIRECT* = 0x0010 ## userspace buffer
  NS_MOREFRAG* = 0x0020 ## packet hs more fragments
  NS_TXMON* = 0x0040
  NS_PORT_SHIFT* = 8
  NS_PORT_MASK* = 0xff shl NS_PORT_SHIFT
  NETMAP_MAX_FRAGS* = 64 ## max number of fragments

template NS_RFRAGS*(slot: netmap_slot) = (slot.flags shr 8) and 0xff


type netmap_ring* = object ## buf_ofs is meant to be used through macros.
  buf_ofs: int64
  num_slots*: uint32
  nr_buf_size*: uint32
  ringid*: uint16
  dir*: int16
  head*: uint32
  cur*: uint32
  tail*: uint32
  flags*: uint32
  ts*: Timeval
  offset_mask*: uint64
  buf_align*: uint64
  sem* {.align(NM_CACHE_ALIGN).}: array[128, uint8]
  slot*: UncheckedArray[netmap_slot]

const
  NR_TIMESTAMP* = 0x0002 ## set timestamp on *sync()
  NR_FORWARD* = 0x0004 # enable NS_FORWARD for ring


proc nm_ring_empty*(ring: ptr netmap_ring): bool =
  ## Check if space is available in the ring
  result = ring.head == ring.tail


type netmap_if* = object
  ni_name*: array[16, char]
  ni_version*: uint32
  ni_flags*: uint32
  ni_tx_rings*: uint32
  nt_rx_rings*: uint32
  ni_bufs_head*: uint32
  ni_host_tx_rings*: uint32
  ni_host_rt_rings*: uint32
  ni_spare1*: array[3, uint32]
  ring_ofs*: UncheckedArray[csize_t]

const NETMAP_REQ_MAXSIZE* = 4096

type
  nmreq_option* = object
    nro_next*: uint64
    nro_reqtype*: uint32
    nro_status*: uint32
    nro_size*: uint64

  nmreq_header* = object
    nr_version*: uint16
    nr_reqtype*: int16
    nr_reserved*: uint32
    nr_name*: array[64, char]
    nr_options*: uint64
    nr_body*: uint64

  NETMAP_REQ* = enum
    NETMAP_REQ_REGISTER = 1
    NETMAP_REQ_POST_INFO_GET
    NETMAP_REQ_VALE_ATTACH
    NETMAP_REQ_VALE_DEATCH
    NETMAP_REQ_VALE_LIST
    NETMAP_REQ_PORT_HDR_SET
    NETMAP_REQ_PORT_HDR_GET
    NETMAP_REQ_VALE_NEWIF
    NETMAP_REQ_VALUE_DELIF
    NETMAP_REQ_VALE_POLLING_ENABLE
    NETMAP_REQ_VALE_POLLING_DISABLE
    NETMAP_REQ_POOLS_INFO_GET
    NETMAP_REQ_SYNC_KLOOP_START
    NETMAP_REQ_SYNC_KLOOP_STOP
    NETMAP_REQ_CSB_ENABLE

  NETMAP_REQ_OPT* = enum
    NETMAP_REQ_OPT_EXMEM = 1
    NETMAP_REQ_OPT_SYNC_KLOOP_EVENTFDS
    NETMAP_REQ_OPT_CSB
    NETMAP_REQ_OPT_SYNC_KLOOP_MODE
    NETMAP_REQ_OPT_OFFSETS
    NETMAP_REQ_OPT_MAX

  nmreq_register* = object
    nr_offset*: uint64
    nr_memsize*: uint64
    nr_tx_slots*: uint32
    nr_rx_slots*: uint32
    nr_tx_rings*: uint16
    nr_rx_rings*: uint16
    nr_host_tx_rings*: uint16
    nr_host_rx_rings*: uint16

    nr_mem_id*: uint16
    nr_ringid*: uint16
    nr_mode*: uint32
    nr_extra_bufs*: uint32

    nr_flags*: uint64

  NR_REG* = enum
    NR_REG_DEFAULT
    NR_REG_ALL_NIC
    NR_REG_SW
    NR_REG_NIC_SW
    NR_REG_ONE_NIC
    NR_REG_PIPE_MASTER
    NR_REG_PIPE_SLAVE
    NR_REG_NULL
    NR_REG_ONE_SW

  nmreq_port_info_get* = object
    nr_memsize*: uint64
    nr_tx_slots*: uint32
    nr_rx_slots*: uint32
    nr_tx_rings*: uint16
    nr_rx_rings*: uint16
    nr_host_tx_rings*: uint16
    nr_host_rx_rings*: uint16
    nr_mem_id*: uint16
    pad*: array[3, uint16]

  nmreq_val_attach* = object
    reg*: nmreq_register
    port_index*: uint32
    pad1: uint32

  mnreq_vale_deatch* = object
    port_index*: uint32
    pad1*: uint32

  nmreq_vale_list* = object
    nr_bridge_idx*: uint16
    pad1*: uint16
    nr_port_idx*: uint32

  nmreq_port_hdr* = object
    nr_hdr_len*: uint32
    pad1*: uint32

  nmreq_vale_newif* = object
    nr_tx_slots*: uint32
    nr_rx_slots*: uint32
    nr_tx_rings*: uint16
    nr_rx_rings*: uint16
    nr_mem_id*: uint16
    pad1*: uint16

const
  NETMAP_POLLING_MODE_SINGLE_CPU* = 1
  NETMAP_POLLING_MODE_MULTI_CPU* = 2

type
  nmreq_vale_polling* = object
    nr_mode*: uint32
    nr_first_cpu_id*: uint32
    nr_num_polling_cpus*: uint32
    pad1*: uint32

  nmreq_pools_info* = object
    nr_memsize*: uint64
    nr_mem_id*: uint16
    pad1*: array[3, uint16]
    nr_if_pool_offset*: uint64
    nr_if_pool_objtotal*: uint32
    nr_if_pool_objsize*: uint32
    nr_ring_pool_offset*: uint64
    nr_ring_pool_objtotal*: uint32
    nr_ring_pool_objsize*: uint32
    nr_buf_pool_offset*: uint64
    nr_buf_pool_objtotal*: uint32
    nr_buf_pool_objsize*: uint32

  nmreq_sync_kloop_start* = object
    sleep_us*: uint32
    pad1*: uint32

  nm_csb_atok* = object
    head*: uint32
    cur*: uint32
    appl_need_kick*: uint32
    sync_flags*: uint32
    pad*: array[12, uint32]

  nm_csb_ktoa* = object
    hwcur*: uint32
    hwtail*: uint32
    kern_need_kick*: uint32
    pad*: array[13, uint32]