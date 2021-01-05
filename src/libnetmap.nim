import libnetmap/netmap/[netmap, user]

when not defined(release):
  {.passC: "-DDEBUG_NETMAP_USER".}

const NMREQ_OPT_MAXKEYS* = 16


type
  nmem_d* = object ## describes a memory region currently used
    mem_id*: uint16          ##  the region netmap identifier
    refcount*: cint            ##  how many nmport_d's point here
    mem*: pointer              ##  memory region base address
    size*: csize_t               ##  memory region size
    is_extmem*: cint           ##  was it obtained via extmem?
                   ##  pointers for the circular list implementation.
                   ##  The list head is the mem_descs filed in the nmctx
                   ##
    next*: ptr nmem_d
    prev*: ptr nmem_d


  nmport_cleanup_d* = object
    next*: ptr nmport_cleanup_d
    cleanup*: proc (a1: ptr nmport_cleanup_d, a2: ptr nmport_d)

  nmport_d* = object
    hdr*: nmreq_header
    reg*: nmreq_register
    mem*: ptr nmem_d
    ctx*: ptr nmctx
    register_done*: int32
    mmap_done*: int32
    extmem*: ptr nmreq_opt_extmem
    fd*: int32
    nifp*: ptr netmap_if
    firstx_ring*: uint16
    lastx_ring*: uint16
    first_rx_ring*: uint16
    last_rx_ring*: uint16
    curx_ring*: uint16
    cur_rx_ring*: uint16
    clist*: ptr nmport_cleanup_d

  nmreq_opt_parser* = object ## describes an option parser
    prefix*: cstring           ##  matches one option prefix
    parse*: nmreq_opt_parser_cb ##  the parse callback
    default_key*: int32         ##  which option is the default if the parser is multi-key (-1 if none)
    nr_keys*: int32
    flags*: int32
    next*: ptr nmreq_opt_parser ##  list of options
                             ##  recognized keys
    keys*: array[NMREQ_OPT_MAXKEYS, nmreq_opt_key]

  nmreq_parse_ctx* = object
    ctx*: ptr nmctx             ##  the nmctx for errors and malloc/free
    token*: pointer ##  the token passed to nmreq_options_parse
    keys*: array[NMREQ_OPT_MAXKEYS, cstring]


  nmreq_opt_key* = object ## describes an option key
    key*: cstring              ##  the key name
    id*: int32                  ##  its position in the parse context
    flags*: uint32

  nmreq_opt_parser_cb* = proc (a1: ptr nmreq_parse_ctx): int32
  nmctx_error_cb* = proc (a1: ptr nmctx, a2: cstring)
  nmctx_malloc_cb* = proc (a1: ptr nmctx, a2: csize_t): pointer
  nmctx_free_cb* = proc (a1: ptr nmctx, a2: pointer)
  nmctx_lock_cb* = proc (a1: ptr nmctx, a2: cint)

  nmctx* = object
    verbose*: cint
    error*: nmctx_error_cb
    malloc*: nmctx_malloc_cb
    free*: nmctx_free_cb
    lock*: nmctx_lock_cb
    mem_descs*: ptr nmem_d


{.passL: "-lnetmap".}
{.push discardable, cdecl, importc.}
proc nmport_open*(portspec: cstring): ptr nmport_d ## opens a port from a portspec

proc nmport_close*(d: ptr nmport_d) ## close a netmap port

proc nmport_inject*(d: ptr nmport_d, buf: pointer, size: csize_t): int32 ## sends a packet

proc nmport_new*(): ptr nmport_d ## create a new nmport_d

proc nmport_parse*(d: ptr nmport_d, portspec: cstring): int32 ## fills the nmport_d netmap-register request

proc nmport_register*(a1: ptr nmport_d): int32 ## registers the port with netmap

proc nmport_mmap*(a1: ptr nmport_d): int32 ## maps the port resources into the process memory

proc nmport_delete*(a1: ptr nmport_d)
proc nmport_undo_parse*(a1: ptr nmport_d)
proc nmport_undo_register*(a1: ptr nmport_d)
proc nmport_undo_mmap*(a1: ptr nmport_d)

proc nmport_prepare*(portspec: cstring): ptr nmport_d ## create a port descriptor, but do not open it

proc nmport_open_desc*(d: ptr nmport_d): int32 ## open an initialized port descriptor

proc nmport_undo_prepare*(a1: ptr nmport_d)
proc nmport_undo_open_desc*(a1: ptr nmport_d)

proc nmport_clone*(a1: ptr nmport_d): ptr nmport_d ## copy an nmport_d

proc nmport_extmem*(d: ptr nmport_d, base: pointer, size: csize_t): int32 ## use extmem for this port

proc nmport_extmem_from_file*(d: ptr nmport_d, fname: cstring): int32 ## use the extmem obtained by mapping a file

proc nmport_extmem_getinfo*(d: ptr nmport_d): ptr nmreq_pools_info ## opbtai a pointer to the extmem configuration

proc nmport_offset*(d: ptr nmport_d, initial: uint64, maxoff: uint64, bits: uint64, mingap: uint64): int32
  ## use offsets for this port

proc nmport_disable_option*(opt: cstring) ## enable options
proc nmport_enable_option*(opt: cstring): int32 ## disable options

proc nmreq_header_init*(hdr: ptr nmreq_header, reqtype: uint16, body: pointer) ## initialize an nmreq_header

proc nmreq_header_decode*(ppspec: cstringArray, hdr: ptr nmreq_header, ctx: ptr nmctx): int32
  ## initialize an nmreq_header

proc nmreq_register_decode*(pmode: cstringArray, reg: ptr nmreq_register, ctx: ptr nmctx): int32
  ## initialize an nmreq_register

proc nmreq_options_decode*(opt: cstring, parsers: ptr nmreq_opt_parser, token: pointer, ctx: ptr nmctx): int32
  ## parse the "options" part of the portspec


proc nmreq_get_mem_id*(portname: cstringArray, ctx: ptr nmctx): int32
  ##  option list manipulation

proc nmreq_push_option*(a1: ptr nmreq_header, a2: ptr nmreq_option)
proc nmreq_remove_option*(a1: ptr nmreq_header, a2: ptr nmreq_option)
proc nmreq_find_option*(a1: ptr nmreq_header, a2: uint32): ptr nmreq_option
proc nmreq_free_options*(a1: ptr nmreq_header)
proc nmreq_option_name*(a1: uint32): cstring

##  nmctx_get - obtain a pointer to the current default context

proc nmctx_get*(): ptr nmctx
##  nmctx_set_default - change the default context
##  @ctx		pointer to the new context
##
##  Returns a pointer to the previous default context.
##

proc nmctx_set_default*(ctx: ptr nmctx): ptr nmctx
##  internal functions and data structures
##  struct nmem_d - describes a memory region currently used


proc libnetmap_init*()
  ##  a trick to force the inclusion of libpthread only if requested. If
  ##  LIBNETMAP_NOTHREADSAFE is defined, no pthread symbol is imported.
  ##
  ##  There is no need to actually call this function: the ((used)) attribute is
  ##  sufficient to include it in the image.

proc nmctx_sethreadsafe*() ## install a threadsafe default context

proc nmctx_ferror*(a1: ptr nmctx, a2: cstring) {.varargs.} ## format and send an error message

proc nmctx_malloc*(a1: ptr nmctx, a2: csize_t): pointer ## allocate memory

proc nmctx_free*(a1: ptr nmctx, a2: pointer) ## free memory allocated via nmctx_malloc

proc nmctx_lock*(a1: ptr nmctx) ## lock the list of nmem_d

proc nmctx_unlock*(a1: ptr nmctx) ## unlock the list of nmem_d

{.pop.}