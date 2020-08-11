
 
// ODIN and SPI clock periods
`define CLK_HALF_PERIOD     10
`define SCK_HALF_PERIOD     50

// Testbench routines selection
`define PROGRAM_AND_VERIFY_NEURON_MEMORY  0
`define PROGRAM_AND_VERIFY_SYNAPSE_MEMORY 0
`define DO_LIF_NEURON_TEST                1

// ODIN global parameters and configuration registers
`define SPI_OPEN_LOOP              1'b1
`define SPI_BURST_TIMEREF          20'b0
`define SPI_OUT_AER_MONITOR_EN     1'b0
`define SPI_AER_SRC_CTRL_nNEUR     1'b0
`define SPI_MONITOR_NEUR_ADDR      8'd0
`define SPI_MONITOR_SYN_ADDR       8'd0
`define SPI_UPDATE_UNMAPPED_SYN    1'b0
`define SPI_PROPAGATE_UNMAPPED_SYN 1'b0
`define SPI_SYN_SIGN               256'h0
`define SPI_SDSP_ON_SYN_STIM       1'b0

// Test leaky integrate-and-fire (LIF) parameters
`define PARAM_LEAK_STR   7'd0
`define PARAM_LEAK_EN    1'b0
`define PARAM_THR        8'd100
`define PARAM_CA_SYN_EN  1'b0
`define PARAM_THETAMEM   8'd0
`define PARAM_CA_THETA1  3'd0
`define PARAM_CA_THETA2  3'd0
`define PARAM_CA_THETA3  3'd0
`define PARAM_CALEAK     5'd0
 

module tbench #(
);

    logic            CLK;
    logic            RST;

    logic            SCK, MOSI, MISO;
    logic [    16:0] AERIN_ADDR;
    logic [     7:0] AEROUT_ADDR;
    logic            AERIN_REQ, AERIN_ACK, AEROUT_REQ, AEROUT_ACK;
    
    logic            SPI_config_rdy;
    logic            SPI_param_checked;
    logic            SNN_initialized_rdy;
    
    logic [    31:0] synapse_pattern , syn_data;
    logic [   127:0] neuron_pattern  , neur_data;
    logic [    31:0] shift_amt;
    logic [    15:0] addr_temp;
    logic [   255:0] data_temp;
    
    logic [    19:0] spi_read_data;
    
    integer i, j;
    

    /***************************
      INIT 
    ***************************/ 
    
    initial begin
        SCK        =  1'b0;
        MOSI       =  1'b0;
        AERIN_ADDR = 17'b0;
        AERIN_REQ  =  1'b0;
        AEROUT_ACK =  1'b0;
        
        SPI_config_rdy = 1'b0;
        SPI_param_checked = 1'b0;
        SNN_initialized_rdy = 1'b0;
    end
    

    /***************************
      CLK
    ***************************/ 
    
    initial begin
        CLK = 1'b1; 
        forever begin
            wait_ns(`CLK_HALF_PERIOD);
            CLK = ~CLK; 
        end
    end 

    
    /***************************
      RST
    ***************************/
    
    initial begin 
        RST = 1'b0;
        wait_ns(50);
        RST = 1'b1;
        wait_ns(50);
        RST = 1'b0;
        wait_ns(50);
        SPI_config_rdy = 1'b1;
        while (~SPI_param_checked) wait_ns(1);
        SNN_initialized_rdy = 1'b1;
    end

    
    /***************************
      STIMULI GENERATION
    ***************************/

    initial begin 
        while (~SPI_config_rdy) wait_ns(1);
        
        /*****************************************************************************************************************************************************************************************************************
                                                                              PROGRAMMING THE CONTROL REGISTERS THROUGH 20-bit SPI
        *****************************************************************************************************************************************************************************************************************/
        
        spi_write (.addr({1'b0,1'b0,2'b00,16'd0 }), .data(20'b1                    ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));   //SPI_GATE_ACTIVITY --> 1
        spi_write (.addr({1'b0,1'b0,2'b00,16'd1 }), .data(`SPI_OPEN_LOOP           ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));   //SPI_OPEN_LOOP
        data_temp = `SPI_SYN_SIGN;
        for (i=0; i<16; i++) begin
            spi_write (.addr({1'b0,1'b0,2'b00,(16'd2+i)}), .data(data_temp[15:0]), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));      //SPI_SYN_SIGN
            data_temp = data_temp >> 16;
        end
        spi_write (.addr({1'b0,1'b0,2'b00,16'd18}), .data(`SPI_BURST_TIMEREF         ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_BURST_TIMEREF
        spi_write (.addr({1'b0,1'b0,2'b00,16'd20}), .data(`SPI_OUT_AER_MONITOR_EN    ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_OUT_AER_MONITOR_EN
        spi_write (.addr({1'b0,1'b0,2'b00,16'd19}), .data(`SPI_AER_SRC_CTRL_nNEUR    ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_AER_SRC_CTRL_nNEUR
        spi_write (.addr({1'b0,1'b0,2'b00,16'd21}), .data(`SPI_MONITOR_NEUR_ADDR     ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_MONITOR_NEUR_ADDR
        spi_write (.addr({1'b0,1'b0,2'b00,16'd22}), .data(`SPI_MONITOR_SYN_ADDR      ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_MONITOR_SYN_ADDR
        spi_write (.addr({1'b0,1'b0,2'b00,16'd23}), .data(`SPI_UPDATE_UNMAPPED_SYN   ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_UPDATE_UNMAPPED_SYN
        spi_write (.addr({1'b0,1'b0,2'b00,16'd24}), .data(`SPI_PROPAGATE_UNMAPPED_SYN), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_PROPAGATE_UNMAPPED_SYN
        spi_write (.addr({1'b0,1'b0,2'b00,16'd25}), .data(`SPI_SDSP_ON_SYN_STIM      ), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_SDSP_ON_SYN_STIM

        
        /*****************************************************************************************************************************************************************************************************************
                                                                                VERIFYING THE CONTROL REGISTERS THROUGH 20-bit SPI
        *****************************************************************************************************************************************************************************************************************/        
        
        $display("----- Starting verification of programmed SNN parameters");
        assert(snn_0.spi_slave_0.SPI_GATE_ACTIVITY          ==  1'b1                      ) else $fatal(0, "SPI_GATE_ACTIVITY parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_OPEN_LOOP              == `SPI_OPEN_LOOP             ) else $fatal(0, "SPI_OPEN_LOOP parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_SYN_SIGN               == `SPI_SYN_SIGN              ) else $fatal(0, "SPI_SYN_SIGN parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_BURST_TIMEREF          == `SPI_BURST_TIMEREF         ) else $fatal(0, "SPI_BURST_TIMEREF parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_OUT_AER_MONITOR_EN     == `SPI_OUT_AER_MONITOR_EN    ) else $fatal(0, "SPI_OUT_AER_MONITOR_EN parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_AER_SRC_CTRL_nNEUR     == `SPI_AER_SRC_CTRL_nNEUR    ) else $fatal(0, "SPI_AER_SRC_CTRL_nNEUR parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_MONITOR_NEUR_ADDR      == `SPI_MONITOR_NEUR_ADDR     ) else $fatal(0, "SPI_MONITOR_NEUR_ADDR parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_MONITOR_SYN_ADDR       == `SPI_MONITOR_SYN_ADDR      ) else $fatal(0, "SPI_MONITOR_SYN_ADDR parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_UPDATE_UNMAPPED_SYN    == `SPI_UPDATE_UNMAPPED_SYN   ) else $fatal(0, "SPI_UPDATE_UNMAPPED_SYN parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_PROPAGATE_UNMAPPED_SYN == `SPI_PROPAGATE_UNMAPPED_SYN) else $fatal(0, "SPI_PROPAGATE_UNMAPPED_SYN parameter not correct.");
        assert(snn_0.spi_slave_0.SPI_SDSP_ON_SYN_STIM       == `SPI_SDSP_ON_SYN_STIM      ) else $fatal(0, "SPI_SDSP_ON_SYN_STIM parameter not correct.");
        $display("----- Ending verification of programmed SNN parameters, no error found!");
        
        SPI_param_checked = 1'b1;
        while (~SNN_initialized_rdy) wait_ns(1);
        
        
        /*****************************************************************************************************************************************************************************************************************
                                                                                                    PROGRAM NEURON MEMORY WITH TEST VALUES
        *****************************************************************************************************************************************************************************************************************/

        if (`PROGRAM_AND_VERIFY_NEURON_MEMORY) begin
            $display("----- Starting programmation of neuron memory in the SNN through SPI.");
            neuron_pattern = {8{8'b01010101,8'b10101010}}; //dummy test values
            for (i=0; i<256; i=i+1) begin
                shift_amt = 32'b0;
                for (j=0; j<16; j=j+1) begin
                    neur_data       = neuron_pattern >> shift_amt;
                    addr_temp[15:8] = j;
                    addr_temp[7:0]  = i;    // Each single neuron
                    spi_write (.addr({1'b0,1'b1,2'b01,addr_temp[15:0]}), .data({4'b0,8'h00,neur_data[7:0]}), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));
                    shift_amt       = shift_amt + 32'd8;
                end
                if(!(i%10))
                    $display("Programming neurons... (i=%0d/256)", i);
            end
            $display("----- Ending programmation of neuron memory in the SNN through SPI.");
        end else
            $display("----- Skipping programmation of neuron memory in the SNN through SPI.");
            
        
        /*****************************************************************************************************************************************************************************************************************
                                                                                                        READ BACK AND TEST NEURON MEMORY
        *****************************************************************************************************************************************************************************************************************/
        
        if (`PROGRAM_AND_VERIFY_NEURON_MEMORY) begin
            $display("----- Starting verification of neuron memory in the SNN through SPI.");
            for (i=0; i<256; i=i+1) begin
                shift_amt = 32'b0;
                for (j=0; j<16; j=j+1) begin
                    neur_data       = neuron_pattern >> shift_amt;
                    addr_temp[15:8] = j;
                    addr_temp[7:0]  = i;    // Each single neuron
                    spi_read (.addr({1'b1,1'b0,2'b01,addr_temp[15:0]}), .data(spi_read_data), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); 
                    assert(spi_read_data == {12'b0,neur_data[7:0]}) else $fatal(0, "Byte %d of neuron %d not written/read correctly.", j, i);
                    shift_amt       = shift_amt + 32'd8;
                end
                if(!(i%10))
                    $display("Verifying neurons... (i=%0d/256)", i);
            end
            $display("----- Ending verification of neuron memory in the SNN through SPI, no error found!");
        end else
            $display("----- Skipping verification of neuron memory in the SNN through SPI.");
        
        
        /*****************************************************************************************************************************************************************************************************************
                                                                                                    PROGRAM ALL SYNAPSES WITH TEST VALUES
        *****************************************************************************************************************************************************************************************************************/
        
        if (`PROGRAM_AND_VERIFY_SYNAPSE_MEMORY) begin
            synapse_pattern = {4'd15,4'd7,4'd12,4'd13,4'd10,4'd5,4'd1,4'd2}; //dummy test values
            $display("----- Starting programmation of all synapses in the SNN through SPI.");
            for (i=0; i<8192; i=i+1) begin
                for (j=0; j<4; j=j+1) begin
                    syn_data        = synapse_pattern >> (j<<3);
                    addr_temp[15:13] = j;    // Each single byte in a 32-bit word
                    addr_temp[12:0 ] = i;    // Programmed address by address
                    spi_write (.addr({1'b0,1'b1,2'b10,addr_temp[15:0]}), .data({4'b0,8'h00,syn_data[7:0]}), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));
                end
                if(!(i%500))
                    $display("Programming synapses... (i=%0d/8192)", i);
            end
            $display("----- Ending programmation of all synapses in the SNN through SPI.");
        end else
            $display("----- Skipping programmation of all synapses in the SNN through SPI.");
            
        
        /*****************************************************************************************************************************************************************************************************************
                                                                                                        READ BACK AND TEST ALL SYNAPSES
        *****************************************************************************************************************************************************************************************************************/
        
        if (`PROGRAM_AND_VERIFY_SYNAPSE_MEMORY) begin
            $display("----- Starting verification of all synapses in the SNN through SPI.");
            for (i=0; i<8192; i=i+1) begin
                for (j=0; j<4; j=j+1) begin
                    syn_data        = synapse_pattern >> (j<<3);
                    addr_temp[15:13] = j;    // Each single byte in a 32-bit word
                    addr_temp[12:0 ] = i;    // Programmed address by address
                    spi_read (.addr({1'b1,1'b0,2'b10,addr_temp[15:0]}), .data(spi_read_data), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); 
                    assert(spi_read_data == {12'b0,syn_data[7:0]}) else $fatal(0, "Byte %d of address %d not written/read correctly.", j, i);
                end
                if(!(i%512))
                    $display("Verifying synapses... (i=%0d/8192)", i);
            end
            $display("----- Ending verification of all synapses in the SNN through SPI, no error found!");
        end else
            $display("----- Skipping verification of all synapses in the SNN through SPI.");
 
 
        /*****************************************************************************************************************************************************************************************************************
                                                                                                    STIMULATE A LIF NEURON
        *****************************************************************************************************************************************************************************************************************/
        
        if (`DO_LIF_NEURON_TEST) begin
            $display("----- Launching endless stimuli generation with a simple LIF neuron.");
            
            fork
                auto_ack_and_monitoring(.req(AEROUT_REQ), .ack(AEROUT_ACK), .addr(AEROUT_ADDR));
            join_none
                
            // Disabling all neurons
            $display("----- Disabling neurons 0 to 255.");   
            for (i=0; i<256; i=i+1) begin
                addr_temp[15:8] = 15;   // Programming only last byte for disabling
                addr_temp[7:0]  = i;    // all neurons
                spi_write (.addr({1'b0,1'b1,2'b01,addr_temp[15:0]}), .data({4'b0,8'h7F,8'h80}), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //Mask all bits in byte, except MSB
            end

            // Programming neuron 1 (test LIF neuron)
            $display("----- Programming neuron 1 to leaky integrate and fire (LIF) configuration (leakage and SDSP disabled, firing threshold is %0d)", `PARAM_THR);
            shift_amt = 32'b0;
            //Neuron programming data: asserted LSB for selecting LIF neuron model, all state information is initialized to zero
            neuron_pattern = {1'b0,89'b0,`PARAM_CALEAK,`PARAM_CA_THETA3,`PARAM_CA_THETA2,`PARAM_CA_THETA1,`PARAM_THETAMEM,`PARAM_CA_SYN_EN,`PARAM_THR,`PARAM_LEAK_EN,`PARAM_LEAK_STR,1'b1};
            for (j=0; j<16; j=j+1) begin
                neur_data       = neuron_pattern >> shift_amt;
                addr_temp[15:8] = j;    // All bytes of 
                addr_temp[7:0]  = 8'd1; // neuron 1 only
                spi_write (.addr({1'b0,1'b1,2'b01,addr_temp[15:0]}), .data({4'b0,8'h00,neur_data[7:0]}), .MISO(MISO), .MOSI(MOSI), .SCK(SCK));
                shift_amt       = shift_amt + 32'd8;
            end
            
            //Re-enable network operation, keep it open-loop
            spi_write (.addr({1'b0,1'b0,2'b00,16'd0}), .data(20'd0), .MISO(MISO), .MOSI(MOSI), .SCK(SCK)); //SPI_GATE_ACTIVITY --> 0
            wait_ns(5000); // Wait for SPI transaction to be over
            
            //Testing the LIF neuron
            $display("----- Launching test of neuron 1 (200 virtual events of weight 5)");
            for (j=0; j<200; j=j+1) begin
                aer_send (.addr_in({1'b0,8'h01,{3'd5,1'b0,1'b0,3'b001}}), .addr_out(AERIN_ADDR), .ack(AERIN_ACK), .req(AERIN_REQ)); //Stimulating the virtual synapse of neuron 1 with excitatory virtual weight 5
                wait_ns(100);
            end
        end
 
        wait_ns(50);
        $finish;
    end
    
    
    /***************************
      SNN INSTANTIATION
    ***************************/
    
    ODIN snn_0 (
        // Global input     -------------------------------
        .CLK(CLK),
        .RST(RST),
        
        // SPI slave        -------------------------------
        .SCK(SCK),
        .MOSI(MOSI),
        .MISO(MISO),
        
        // Input 17-bit AER -------------------------------
        .AERIN_ADDR(AERIN_ADDR),
        .AERIN_REQ(AERIN_REQ),
        .AERIN_ACK(AERIN_ACK),

        // Output 8-bit AER -------------------------------
        .AEROUT_ADDR(AEROUT_ADDR),
        .AEROUT_REQ(AEROUT_REQ),
        .AEROUT_ACK(AEROUT_ACK)
    );    
    
    
    /***********************************************************************
                            TASK IMPLEMENTATIONS
    ************************************************************************/ 

    /***************************
     SIMPLE TIME-HANDLING TASK
    ***************************/
    
    // This routine is based on a correct definition of the simulation timescale.
    task wait_ns;
        input   tics_ns;
        integer tics_ns;
        #tics_ns;
    endtask

    
    /***************************
     AER send event
    ***************************/
    
    task automatic aer_send (
        input  logic [  16:0] addr_in,
        ref    logic [  16:0] addr_out,
        ref    logic          ack,
        ref    logic          req
    );
        while (ack) wait_ns(1);
        addr_out = addr_in;
        wait_ns(5);
        req = 1'b1;
        while (!ack) wait_ns(1);
        wait_ns(5);
        req = 1'b0;
    endtask

    
    /***************************
     AER automatic acknowledge
    ***************************/

    task automatic auto_ack_and_monitoring (
        ref    logic       req,
        ref    logic       ack,
        ref    logic [7:0] addr
    );
    
        //Simple automatic acknowledge task (retrieves the address of the source spiking neuron if automatic monitoring format is not enabled)
        forever begin
            while (~req) wait_ns(1);
            if (!`SPI_OUT_AER_MONITOR_EN)
                $display("Neuron %0d spiked!", addr);
            ack = 1'b1;
            while (req) wait_ns(1);
            ack = 1'b0;
        end
    endtask

    
    /***************************
     SPI write data
    ***************************/

    task automatic spi_write (
        input  logic [19:0] addr,
        input  logic [19:0] data,
        input  logic        MISO, // not used for SPI write
        ref    logic        MOSI,
        ref    logic        SCK
    );
        integer i;
        
        for (i=0; i<20; i=i+1) begin
            MOSI = addr[19-i];
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b1;
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b0;
        end
        for (i=0; i<20; i=i+1) begin
            MOSI = data[19-i];
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b1;
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b0;
        end
    endtask
    
    /***************************
     SPI read data
    ***************************/

    task automatic spi_read (
        input  logic [19:0] addr,
        output logic [19:0] data,
        ref    logic        MISO,
        ref    logic        MOSI,
        ref    logic        SCK
    );
        integer i;
        
        for (i=0; i<20; i=i+1) begin
            MOSI = addr[19-i];
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b1;
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b0;
        end
        for (i=0; i<20; i=i+1) begin
            wait_ns(`SCK_HALF_PERIOD);
            data = {data[18:0],MISO};
            SCK  = 1'b1;
            wait_ns(`SCK_HALF_PERIOD);
            SCK  = 1'b0;
        end
    endtask
    
    
endmodule 
