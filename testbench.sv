
module tb_sync_fifo;

    // ==========================================
    // 1. PARAMETERS
    // ==========================================

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;

    // ==========================================
    // 2. SIGNAL DECLARATIONS
    // ==========================================

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    logic full;
    logic empty;

    // Scoreboard
    logic [DATA_WIDTH-1:0] expected_queue[$];
    logic [DATA_WIDTH-1:0] expected_data;

    integer total_transactions = 0;
    integer random_transactions = 0;


    // ==========================================
    // 3. CONSTRAINED RANDOM TRANSACTION CLASS
    // ==========================================

    class fifo_transaction #(int DW = 8);

        // Random transaction variables

        rand bit wr_req;
        rand bit rd_req;

        rand bit [DW-1:0] data;

        // Constraint 1: Write request distribution

        constraint write_constraint {

            wr_req dist {
                1'b0 := 30,
                1'b1 := 70
            };

        }

        // Constraint 2: Read request distribution

        constraint read_constraint {

            rd_req dist {
                1'b0 := 30,
                1'b1 := 70
            };

        }

        // Constraint 3: Data generation

        constraint data_constraint {

            data inside {[0:(2**DW)-1]};

        }

    endclass


    // Create transaction object

    fifo_transaction #(DATA_WIDTH) transaction;


    // ==========================================
    // 4. DUT INSTANTIATION
    // ==========================================

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) DUT (

        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .data_in(data_in),
        .data_out(data_out),

        .full(full),
        .empty(empty)

    );


    // ==========================================
    // 5. CLOCK GENERATION
    // ==========================================

    initial clk = 0;

    always #5 clk = ~clk;


    // ==========================================
    // 6. SYSTEMVERILOG ASSERTIONS
    // ==========================================

    // Assertion 1: Count cannot exceed DEPTH

    property p_count_limit;

        @(posedge clk)
        disable iff (rst)

        DUT.count <= DEPTH;

    endproperty

    assert property (p_count_limit)
        else $error("ASSERTION FAILED: Count limit");


    // Assertion 2: Empty flag correctness

    property p_empty_check;

        @(posedge clk)
        disable iff (rst)

        empty == (DUT.count == 0);

    endproperty

    assert property (p_empty_check)
        else $error("ASSERTION FAILED: Empty flag");


    // Assertion 3: Full flag correctness

    property p_full_check;

        @(posedge clk)
        disable iff (rst)

        full == (DUT.count == DEPTH);

    endproperty

    assert property (p_full_check)
        else $error("ASSERTION FAILED: Full flag");


    // Assertion 4: Read pointer validity

    property p_read_pointer;

        @(posedge clk)
        disable iff (rst)

        DUT.rd_ptr < DEPTH;

    endproperty

    assert property (p_read_pointer)
        else $error("ASSERTION FAILED: Read pointer");


    // Assertion 5: Write pointer validity

    property p_write_pointer;

        @(posedge clk)
        disable iff (rst)

        DUT.wr_ptr < DEPTH;

    endproperty

    assert property (p_write_pointer)
        else $error("ASSERTION FAILED: Write pointer");


    // Assertion 6: Full and empty cannot both be HIGH

    property p_full_empty_check;

        @(posedge clk)
        disable iff (rst)

        !(full && empty);

    endproperty

    assert property (p_full_empty_check)
        else $error("ASSERTION FAILED: Full and empty");


    // ==========================================
    // 7. FUNCTIONAL COVERAGE
    // ==========================================

    covergroup fifo_coverage @(posedge clk);

        option.per_instance = 1;

        // Write enable coverage

        cp_write: coverpoint wr_en iff (!rst) {

            bins disabled = {0};
            bins enabled = {1};

        }

        // Read enable coverage

        cp_read: coverpoint rd_en iff (!rst) {

            bins disabled = {0};
            bins enabled = {1};

        }

        // Read/write combinations

        cp_operations: cross cp_write, cp_read;

        // FIFO occupancy coverage

        cp_count: coverpoint DUT.count iff (!rst) {

            bins empty_state = {0};

            bins low_occupancy = {
                [1:DEPTH/4]
            };

            bins medium_occupancy = {
                [DEPTH/4+1:3*DEPTH/4]
            };

            bins high_occupancy = {
                [3*DEPTH/4+1:DEPTH-1]
            };

            bins full_state = {DEPTH};

        }

        // Full flag

        cp_full: coverpoint full iff (!rst) {

            bins not_full = {0};
            bins full = {1};

        }

        // Empty flag

        cp_empty: coverpoint empty iff (!rst) {

            bins not_empty = {0};
            bins empty = {1};

        }

        // Read pointer coverage

        cp_rd_ptr: coverpoint DUT.rd_ptr iff (!rst) {

            bins all_read_addresses[] = {
                [0:DEPTH-1]
            };

        }

        // Write pointer coverage

        cp_wr_ptr: coverpoint DUT.wr_ptr iff (!rst) {

            bins all_write_addresses[] = {
                [0:DEPTH-1]
            };

        }

    endgroup


    // Create coverage object

    fifo_coverage fifo_cov = new();


    // ==========================================
    // 8. SELF-CHECKING SCOREBOARD
    // ==========================================

    task automatic apply_cycle(

        input logic write_request,
        input logic read_request,
        input logic [DATA_WIDTH-1:0] write_data

    );

        bit write_accepted;
        bit read_accepted;

        begin

            // Apply stimulus at negative edge

            @(negedge clk);

            wr_en = write_request;
            rd_en = read_request;

            data_in = write_data;

            // Determine accepted operations

            write_accepted = write_request && !full;

            read_accepted = read_request && !empty;

            // Wait for positive edge

            @(posedge clk);

            // Wait for non-blocking assignments

            #1;

            // Check FIFO output

            if (read_accepted) begin

                if (expected_queue.size() == 0)

                    $fatal(1, "SCOREBOARD EMPTY ERROR");

                expected_data = expected_queue.pop_front();

                if (data_out !== expected_data) begin

                    $display("Expected = %h", expected_data);

                    $display("Actual   = %h", data_out);

                    $fatal(1, "FIFO DATA MISMATCH");

                end

            end

            // Add newly written data

            if (write_accepted) begin

                expected_queue.push_back(write_data);

            end

            // Check empty flag

            if (empty !== (expected_queue.size() == 0))

                $fatal(1, "EMPTY FLAG ERROR");

            // Check full flag

            if (full !== (expected_queue.size() == DEPTH))

                $fatal(1, "FULL FLAG ERROR");

            total_transactions++;

            $display(

                "PASS: WR=%b RD=%b DATA=%h COUNT=%0d",

                write_accepted,
                read_accepted,
                data_out,
                expected_queue.size()

            );

        end

    endtask


    // ==========================================
    // 9. MAIN TEST SEQUENCE
    // ==========================================

    initial begin

        // Generate waveform

        $dumpfile("dump.vcd");

        $dumpvars(0, tb_sync_fifo);

        // Initialise signals

        rst = 1;

        wr_en = 0;

        rd_en = 0;

        data_in = 0;

        expected_queue.delete();

        // Create random transaction object

        transaction = new();

        // Set repeatable random seed

        transaction.srandom(32'hC0FFEE);

        // Apply reset

        repeat (2) @(posedge clk);

        @(negedge clk);

        rst = 0;


        $display("");

        $display("====================================");

        $display(" FIFO ADVANCED VERIFICATION STARTED");

        $display("====================================");


        // --------------------------------------
        // TEST 1: BASIC WRITE
        // --------------------------------------

        $display("");

        $display("TEST 1: Basic write");

        apply_cycle(1, 0, 8'h10);

        apply_cycle(1, 0, 8'h20);

        apply_cycle(1, 0, 8'h30);


        // --------------------------------------
        // TEST 2: FIFO ORDER
        // --------------------------------------

        $display("");

        $display("TEST 2: FIFO order");

        apply_cycle(0, 1, 0);

        apply_cycle(0, 1, 0);

        apply_cycle(0, 1, 0);


        // --------------------------------------
        // TEST 3: UNDERFLOW
        // --------------------------------------

        $display("");

        $display("TEST 3: Underflow");

        apply_cycle(0, 1, 0);


        // --------------------------------------
        // TEST 4: SIMULTANEOUS OPERATIONS
        // --------------------------------------

        $display("");

        $display("TEST 4: Simultaneous read/write");

        apply_cycle(1, 0, 8'hA1);

        apply_cycle(1, 0, 8'hA2);

        apply_cycle(1, 1, 8'hA3);

        apply_cycle(0, 1, 0);

        apply_cycle(0, 1, 0);


        // --------------------------------------
        // TEST 5: OVERFLOW
        // --------------------------------------

        $display("");

        $display("TEST 5: FIFO full condition");

        for (int i = 0; i < DEPTH; i++) begin

            apply_cycle(1, 0, i);

        end

        // Attempt write when full

        apply_cycle(1, 0, 8'hFF);


        // --------------------------------------
        // TEST 6: READ WHEN FULL
        // --------------------------------------

        $display("");

        $display("TEST 6: Simultaneous request at full");

        apply_cycle(1, 1, 8'hBB);


        // --------------------------------------
        // TEST 7: EMPTY FIFO
        // --------------------------------------

        $display("");

        $display("TEST 7: Drain FIFO");

        while (expected_queue.size() > 0) begin

            apply_cycle(0, 1, 0);

        end


        // --------------------------------------
        // TEST 8: POINTER WRAPAROUND
        // --------------------------------------

        $display("");

        $display("TEST 8: Pointer wraparound");

        repeat (3) begin

            for (int i = 0; i < DEPTH; i++) begin

                apply_cycle(

                    1,
                    0,
                    $urandom_range(0,255)

                );

            end

            for (int i = 0; i < DEPTH; i++) begin

                apply_cycle(0, 1, 0);

            end

        end


        // --------------------------------------
        // TEST 9: CONSTRAINED RANDOM TESTING
        // --------------------------------------

        $display("");

        $display("TEST 9: CONSTRAINED RANDOM TESTING");

        repeat (1000) begin

            // Generate random transaction

            if (!transaction.randomize()) begin

                $fatal(1, "RANDOMIZATION FAILED!");

            end

            // Send generated transaction to FIFO

            apply_cycle(

                transaction.wr_req,

                transaction.rd_req,

                transaction.data

            );

            random_transactions++;

        end


        // --------------------------------------
        // TEST 10: FINAL FIFO DRAIN
        // --------------------------------------

        $display("");

        $display("TEST 10: Final FIFO drain");

        while (expected_queue.size() > 0) begin

            apply_cycle(0, 1, 0);

        end


        // --------------------------------------
        // 11. FINAL REPORT
        // --------------------------------------

        @(negedge clk);

        wr_en = 0;

        rd_en = 0;

        $display("");

        $display("====================================");

        $display(" FIFO VERIFICATION COMPLETED");

        $display("====================================");

        $display("Total transactions  = %0d",
                 total_transactions);

        $display("Random transactions = %0d",
                 random_transactions);

        $display("Functional coverage = %0.2f%%",
                 fifo_cov.get_coverage());

        $display("Remaining FIFO count = %0d",
                 expected_queue.size());

        $display("====================================");

        $display("CHECK SIMULATOR LOG FOR ASSERTION FAILURES");

        $display("====================================");

        $finish;

    end

endmodule
