package hdmi_types;

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
