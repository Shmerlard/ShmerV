package hdmi_types;

  typedef struct packed {
    logic hdmi_enable;
    logic cursor_enable;
    logic cursor_blink;
    logic write_wrap;
    logic hdmi_ie;
  } hdmi_ctrl_reg_t;

  typedef enum logic [2:0] {
    HDMI_TARGET_CTRL = 3'd0,
    HDMI_TARGET_CURSOR_POS = 3'd1,
    HDMI_TARGET_START_ROW = 3'd2,
    HDMI_TARGET_CURSOR_DATA = 3'd3,  // TODO: better name
    HDMI_TARGET_RESERVED = 3'd4,
    HDMI_TARGET_CMEM = 3'd5
  } hdmi_access_target_t;

  // Fixed VGA text palette indices; match sw/include/shmerv_hdmi.h.
  typedef enum logic [3:0] {
    HDMI_COLOR_BLACK = 4'h0,
    HDMI_COLOR_BLUE = 4'h1,
    HDMI_COLOR_GREEN = 4'h2,
    HDMI_COLOR_CYAN = 4'h3,
    HDMI_COLOR_RED = 4'h4,
    HDMI_COLOR_MAGENTA = 4'h5,
    HDMI_COLOR_BROWN = 4'h6,
    HDMI_COLOR_LIGHT_GRAY = 4'h7,
    HDMI_COLOR_DARK_GRAY = 4'h8,
    HDMI_COLOR_LIGHT_BLUE = 4'h9,
    HDMI_COLOR_LIGHT_GREEN = 4'hA,
    HDMI_COLOR_LIGHT_CYAN = 4'hB,
    HDMI_COLOR_LIGHT_RED = 4'hC,
    HDMI_COLOR_LIGHT_MAGENTA = 4'hD,
    HDMI_COLOR_YELLOW = 4'hE,
    HDMI_COLOR_WHITE = 4'hF
  } hdmi_color_t;

  typedef struct packed {
    logic [7:0] char_code;
    logic [3:0] fg_col;
    logic [3:0] bg_col;
  } char_cell_t;

  typedef struct packed {
    logic [6:0] x_pos;
    logic [4:0] y_pos;
  } screen_cell_pos_t;  // the position of the char on the screen

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
