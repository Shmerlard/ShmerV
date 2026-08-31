#import "@preview/circuiteria:0.2.1": circuit, element, wire

#set page(width: auto, height: auto, margin: 1cm)

#circuit({
  // Program counter
  element.group(
    id: "if_stage", stroke: (dash: "dashed"),
    {
      element.block(
        x: 0,
        y: 0,
        w: 3.1,
        h: 5,
        id: "PC",
        // name: [Program Counter],
        ports: (
          west: (
            (id: "rst" ),
            (id: "next_pc", name: "next_pc"),
          ),
          north: (
            (id: "clk",  clock: true),
          ),
          south: (
            (id: "en", name: "enable"),
          ),
          east: (
            (id: "pc_out", name: "pc_out"),
          ),
        ),
      )

      // PC + 4
      element.block(
        x: 0.5,
        y: -4.5,
        w: 2,
        h: 2,
        id: "ADD4",
        name: [$+4$],
        ports: (
          west: (
            (id: "out"),
          ),
          east: (
            (id: "in"),
          ),
        ),
      )

      // External control signals
      wire.stub("PC-port-clk", "north", name: "clk")
      wire.stub("PC-port-rst", "west", name: "rst")
      wire.stub("PC-port-en", "south", name: "pc_wr_en")

      // PC -> +4
      wire.wire(
        "pc-to-add4",
        (
          "PC-port-pc_out",
          "ADD4-port-in",
        ),
        style: "zigzag",
        zigzag-ratio: -206%,
        // name: "imem_addr",
        bus: true,
      )

      // +4 -> next_pc
      wire.wire(
        "add4-to-pc",
        (
          "ADD4-port-out",
          "PC-port-next_pc",
        ),
        style: "dodge",
        dodge-margins: (400%, 300%),
        dodge-sides: ("west", "west"),
        bus: true,
      )
    }
  )

})
