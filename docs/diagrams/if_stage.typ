#import "@preview/circuiteria:0.2.1": circuit, element, wire

#set page(width: auto, height: auto, margin: 1cm)

#let if-stage(
  show-control:true,
  show-internals: true
) = {

  circuit({
    // Program counter
    element.group(
      id: "if_stage", stroke: (dash: "dashed"),
      padding: (top: 2.5, right: 1),
      {
        element.block( x: 0, y: 0, w: 3.0, h: 5,
          id: "PC",
          // name: [Program Counter],
          ports: (
            west: (
              (id: "rst", name: "rst" ),
              (id: "next_pc", name: "next_pc"),),
            north: (
              (id: "clk",  clock: true),),
            south: (
              (id: "en", name: "enable"),),
          east: (
            (id: "pc_out"),),
          ),
        )

        // PC + 4
        element.block( x: 0.5, y: -4.5, w: 2, h: 2,
          id: "ADD4", name: [$+4$],
          ports: (
            west: (
              (id: "out"),),
            east: (
              (id: "in"),),
          ),
        )


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
      wire.intersection("pc-to-add4.zig")

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
      }) // end group

let instruction-y = 0

let instruction-in = (
  rel: (0, instruction-y), to: "if_stage.north-west",)

let instruction-out = (
  rel: (0, instruction-y), to: "if_stage.north-east",)

let clk-address-pos = (
  "if_stage.west", "|-", (rel:(0,1.0), to: ("PC-port-clk")))

let rst-address-pos = (
  "if_stage.west", "|-", (rel:(0,0), to: ("PC-port-rst")))


wire.stub(
  clk-address-pos, "west",
  name: [clk],
  length:1)

wire.stub(
  rst-address-pos, "west",
  name: [rst],
  length:1)

wire.wire(
  "clk-to-stub",
  ( "PC-port-clk", clk-address-pos,),
  style: "zigzag", zigzag-ratio: 0%)

wire.wire(
  "rst-to-stub",
  ( "PC-port-rst", rst-address-pos,))


wire.stub(
  instruction-in,
  "west",
  name: [#text(size: 8pt)[instruction_memory_read_data_i]],
  length: 1,)

wire.stub(
  instruction-out,
  "east",
  name: [#text(size: 8pt)[instruction_if_o]],
  length: 1,
)


let imem-address-pos = (
  "if_stage.east", "|-", "PC-port-pc_out",)

wire.stub(
  imem-address-pos,
  "east",
  name: "instruction_memory_address_o",)

wire.wire(
  "pc-to-imem-address",
  ( "PC-port-pc_out", imem-address-pos,),
  bus: true,)

wire.wire(
  "instruction-pass-through",
  ( instruction-in, instruction-out,),
  bus: true,
)
  })
}


#if-stage()
