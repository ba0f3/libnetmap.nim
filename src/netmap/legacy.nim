type
  nmreq* = object
    nr_name*: array[16, char]
    nr_version*: int32
    nr_offset*: uint32
    nr_memsize*: uint32
    nr_tx_slots*: uint32
    nr_rx_slots*: uint32
    nr_tx_rings*: uint16
    nr_rx_rings*: uint16

    nr_ringid*: uint16
    nr_cmd*: uint16
    nr_arg1*: uint16
    nr_arg2*: uint16
    nr_arg3*: uint32
    nr_flags*: uint32
    spare2*: array[1, uint32]

  nm_ifreq* = object
    nifr_name*: array[16, char]
    data*: array[256, char]

