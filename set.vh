`ifndef SET_H
`define SET_H

typedef enum {
  E_NOTHING, E_BUS_RD, E_BUS_WR, E_PR_RD, E_PR_WR
} event_t;

typedef struct packed {
  event_t ev;
} bus_prefix_t;

`endif // ifndef SET_H