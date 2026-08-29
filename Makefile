BUILD_DIR := build
RTL_SOURCES := rtl/smoke.sv
TB_SOURCES := tb/smoke_tb.sv
SV_SOURCES := $(RTL_SOURCES) $(TB_SOURCES)

.PHONY: format format-check lint test clean

format:
	verible-verilog-format --inplace $(SV_SOURCES)

format-check:
	@for file in $(SV_SOURCES); do \
		verible-verilog-format --verify $$file || exit 1; \
	done

lint:
	verible-verilog-lint $(SV_SOURCES)
	verilator --lint-only --timing --top-module smoke_tb $(SV_SOURCES)

test:
	mkdir -p $(BUILD_DIR)
	verilator --binary --timing --trace-fst --top-module smoke_tb \
		--Mdir $(BUILD_DIR)/obj_smoke -o smoke_test $(SV_SOURCES)
	./$(BUILD_DIR)/obj_smoke/smoke_test

clean:
	rm -rf $(BUILD_DIR)
