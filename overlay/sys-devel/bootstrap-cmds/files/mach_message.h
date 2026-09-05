#ifndef _MACH_MESSAGE_H_
#define _MACH_MESSAGE_H_
#include <stdint.h>
#include <mach/boolean.h>

typedef uint32_t mach_msg_bits_t;
typedef uint32_t mach_msg_size_t;
typedef uint32_t mach_msg_id_t;
typedef uint32_t mach_port_t;
typedef uint32_t mach_port_name_t;
typedef uint32_t mach_msg_type_name_t;
typedef uint32_t mach_msg_type_size_t;
typedef uint32_t mach_msg_type_number_t;
typedef uint32_t mach_msg_descriptor_type_t;

#define MACH_MSG_TYPE_MOVE_RECEIVE 16
#define MACH_MSG_TYPE_MOVE_SEND 17
#define MACH_MSG_TYPE_MOVE_SEND_ONCE 18
#define MACH_MSG_TYPE_COPY_SEND 19
#define MACH_MSG_TYPE_MAKE_SEND 20
#define MACH_MSG_TYPE_MAKE_SEND_ONCE 21
#define MACH_MSG_TYPE_PORT_NAME 15
#define MACH_MSG_TYPE_POLYMORPHIC ((mach_msg_type_name_t) -1)

#define MACH_PORT_NULL 0
#define MACH_PORT_DEAD 0xffffffff

typedef struct {
    mach_msg_bits_t msgh_bits;
    mach_msg_size_t msgh_size;
    mach_port_t msgh_remote_port;
    mach_port_t msgh_local_port;
    mach_port_name_t msgh_voucher_port;
    mach_msg_id_t msgh_id;
} mach_msg_header_t;

typedef struct {
    void *pad;
} mach_msg_body_t;

typedef struct {
    mach_msg_type_name_t msgt_name : 8,
                         msgt_size : 8,
                         msgt_number : 12,
                         msgt_inline : 1,
                         msgt_longform : 1,
                         msgt_deallocate : 1,
                         msgt_unused : 1;
} mach_msg_type_t;

typedef struct {
    mach_msg_type_t msgtl_header;
    unsigned short msgtl_name;
    unsigned short msgtl_size;
    uint32_t msgtl_number;
} mach_msg_type_long_t;

#define MACH_MSG_TYPE_PORT_SEND 17
#define MACH_MSG_TYPE_PORT_RECEIVE 16
#define MACH_MSG_PORT_DESCRIPTOR 0
#define MACH_MSG_OOL_DESCRIPTOR 1
#define MACH_MSG_OOL_PORTS_DESCRIPTOR 2
#define MACH_MSG_OOL_VOLATILE_DESCRIPTOR 3

typedef uint32_t natural_t;

#define MIG_VERSION "mig-138"
#define MACH_MSG_TYPE_PORT_SEND_ONCE MACH_MSG_TYPE_MOVE_SEND_ONCE
#define MACH_MSG_TYPE_PORT_ANY(x) (((x) >= MACH_MSG_TYPE_MOVE_RECEIVE) && ((x) <= MACH_MSG_TYPE_MAKE_SEND_ONCE))
#define MACH_MSG_TYPE_PORT_ANY_SEND(x) (((x) >= MACH_MSG_TYPE_MOVE_SEND) && ((x) <= MACH_MSG_TYPE_MAKE_SEND_ONCE))
#define MACH_MSG_TYPE_PORT_ANY_RIGHT(x) (((x) >= MACH_MSG_TYPE_MOVE_RECEIVE) && ((x) <= MACH_MSG_TYPE_MOVE_SEND_ONCE))

#endif
