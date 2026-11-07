// Code your design here

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic clk,
    input  logic rst,

    input  logic wr_en,
    input  logic rd_en,

    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,

    output logic full,
    output logic empty
);

    // Calculate pointer and counter widths
    localparam PTR_WIDTH = $clog2(DEPTH);
    localparam COUNT_WIDTH = $clog2(DEPTH + 1);

    // FIFO memory
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read and write pointers
    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    // Number of stored elements
    logic [COUNT_WIDTH-1:0] count;

    // Status flags
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // Main FIFO operation
    always_ff @(posedge clk) begin

        if (rst) begin

            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            data_out <= 0;

        end

        else begin

            // Write operation
            if (wr_en && !full) begin

                mem[wr_ptr] <= data_in;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end

            // Read operation
            if (rd_en && !empty) begin

                data_out <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end

            // Update FIFO counter
            case ({wr_en && !full, rd_en && !empty})

                2'b10: count <= count + 1'b1;

                2'b01: count <= count - 1'b1;

                2'b11: count <= count;

                default: count <= count;

            endcase

        end

    end

    // Check parameter validity
    initial begin
        if (DEPTH < 2)
            $error("FIFO DEPTH must be at least 2");
    end

endmodule
