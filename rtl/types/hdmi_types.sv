package hdmi_types;
  typedef struct packed {
    logic [7:0] char_code;
    logic [3:0] fg_col;
    logic [3:0] bg_col;
  } char_cell_t;

  typedef struct packed {
    logic [6:0] x_pos;
    logic [4:0] y_pos;
  } char_pos_t;  // the position of the char on the screen

  typedef struct packed {
    logic [7:0] r_pixel;
    logic [7:0] g_pixel;
    logic [7:0] b_pixel;
  } pixel_rgb_t;

  typedef enum logic [1:0] {
    HDMI_HOR_ACTIVE,
    HDMI_HOR_FPORCH,
    HDMI_HOR_HSYNC,
    HDMI_HOR_BPORCH
  } hdmi_horizontal_state_t;

  typedef enum logic [1:0] {
    HDMI_VER_ACTIVE,
    HDMI_VER_FPORCH,
    HDMI_VER_VSYNC,
    HDMI_VER_BPORCH
  } hdmi_vertical_state_t;
endpackage
