module memory #(
    parameter int MEM_WORDS = 1024,
    parameter string INIT_FILE = "",
    parameter string INIT_FILE_LANE0 = "",
    parameter string INIT_FILE_LANE1 = "",
    parameter string INIT_FILE_LANE2 = "",
    parameter string INIT_FILE_LANE3 = ""
) (
    input logic clk,
    input logic [31:0] port_a_read_address_i,
    input logic port_a_read_enable_i,
    output logic [31:0] port_a_read_data_o,

    // One shared access enable and write selector match Gowin RAM inference.
    // Disabled accesses hold the read output. Writes use write-first mode.
    input logic [31:0] port_b_address_i,
    input logic port_b_write_enable_i,
    input logic [3:0] port_b_write_byte_enable_i,
    input logic port_b_enable_i,
    input logic [31:0] port_b_write_data_i,
    output logic [31:0] port_b_read_data_o
);
  localparam int AddressWidth = $clog2(MEM_WORDS);
  logic [7:0] memory_lane0[MEM_WORDS];
  logic [7:0] memory_lane1[MEM_WORDS];
  logic [7:0] memory_lane2[MEM_WORDS];
  logic [7:0] memory_lane3[MEM_WORDS];

  if (INIT_FILE_LANE0 != "") begin : generate_lane_initialization
    initial begin
      $readmemh(INIT_FILE_LANE0, memory_lane0);
      $readmemh(INIT_FILE_LANE1, memory_lane1);
      $readmemh(INIT_FILE_LANE2, memory_lane2);
      $readmemh(INIT_FILE_LANE3, memory_lane3);
    end
  end else begin : generate_word_initialization
    logic [31:0] initialization_words[MEM_WORDS];
    string runtime_init_file;

    initial begin
      if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, initialization_words);
      end else if ($value$plusargs("memory_init=%s", runtime_init_file)) begin
        $readmemh(runtime_init_file, initialization_words);
      end

      for (int word = 0; word < MEM_WORDS; word++) begin
        memory_lane0[word] = initialization_words[word][7:0];
        memory_lane1[word] = initialization_words[word][15:8];
        memory_lane2[word] = initialization_words[word][23:16];
        memory_lane3[word] = initialization_words[word][31:24];
      end
    end
  end

  always @(posedge clk) begin
    if (port_a_read_enable_i) begin
      port_a_read_data_o <= {
        memory_lane3[port_a_read_address_i[AddressWidth+1:2]],
        memory_lane2[port_a_read_address_i[AddressWidth+1:2]],
        memory_lane1[port_a_read_address_i[AddressWidth+1:2]],
        memory_lane0[port_a_read_address_i[AddressWidth+1:2]]
      };
    end
  end

  // Explicit write-first behavior maps to Gowin's supported WRITE_MODE=01.
  always @(posedge clk) begin
    if (port_b_enable_i) begin
      if (port_b_write_enable_i && port_b_write_byte_enable_i[0]) begin
        memory_lane0[port_b_address_i[AddressWidth+1:2]] <= port_b_write_data_i[7:0];
        port_b_read_data_o[7:0] <= port_b_write_data_i[7:0];
      end else begin
        port_b_read_data_o[7:0] <= memory_lane0[port_b_address_i[AddressWidth+1:2]];
      end
    end
  end

  always @(posedge clk) begin
    if (port_b_enable_i) begin
      if (port_b_write_enable_i && port_b_write_byte_enable_i[1]) begin
        memory_lane1[port_b_address_i[AddressWidth+1:2]] <= port_b_write_data_i[15:8];
        port_b_read_data_o[15:8] <= port_b_write_data_i[15:8];
      end else begin
        port_b_read_data_o[15:8] <= memory_lane1[port_b_address_i[AddressWidth+1:2]];
      end
    end
  end

  always @(posedge clk) begin
    if (port_b_enable_i) begin
      if (port_b_write_enable_i && port_b_write_byte_enable_i[2]) begin
        memory_lane2[port_b_address_i[AddressWidth+1:2]] <= port_b_write_data_i[23:16];
        port_b_read_data_o[23:16] <= port_b_write_data_i[23:16];
      end else begin
        port_b_read_data_o[23:16] <= memory_lane2[port_b_address_i[AddressWidth+1:2]];
      end
    end
  end

  always @(posedge clk) begin
    if (port_b_enable_i) begin
      if (port_b_write_enable_i && port_b_write_byte_enable_i[3]) begin
        memory_lane3[port_b_address_i[AddressWidth+1:2]] <= port_b_write_data_i[31:24];
        port_b_read_data_o[31:24] <= port_b_write_data_i[31:24];
      end else begin
        port_b_read_data_o[31:24] <= memory_lane3[port_b_address_i[AddressWidth+1:2]];
      end
    end
  end


endmodule
