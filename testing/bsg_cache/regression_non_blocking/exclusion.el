//==================================================
// This file contains the Excluded objects
// Generated By User: dcjung
// Format Version: 2
// Date: Fri Nov  8 23:58:08 2019
// ExclMode: default
//==================================================
CHECKSUM: "1876878299 3164324781"
INSTANCE: testbench.DUT.miss_fifo0
Block 33 "3917637695" "deque = 1'b0;"
CHECKSUM: "3751605485 1361462809"
INSTANCE: testbench.DUT.dma0.out_fifo
Block 10 "4141722622" "full_r <= ((((~empty_r) & enq_i) & (~deq_i)) | (full_r & (~(deq_i ^ enq_i))));"
CHECKSUM: "3454857118 4212564062"
INSTANCE: testbench.DUT.decode0
Block 2 "3818645615" "decode_o.size_op = 2'b11;"
CHECKSUM: "505412087 1352501511"
INSTANCE: testbench.DUT.dma0
Fsm dma_state_r "1352501511"
Transition SEND_REFILL_ADDR->IDLE "1->0"
Transition SEND_EVICT_ADDR->IDLE "2->0"
Transition SEND_EVICT_DATA->IDLE "3->0"
Transition RECV_REFILL_DATA->IDLE "4->0"
CHECKSUM: "4069356448 1095362285"
INSTANCE: testbench.DUT.mhu0
Fsm mhu_state_r "1756338327"
Transition READ_TAG1->IDLE "4->0"
Transition SEND_DMA_REQ1->IDLE "5->0"
Transition WAIT_DMA_DONE->IDLE "6->0"
Transition DEQUEUE_MODE->IDLE "7->0"
Transition READ_TAG2->IDLE "8->0"
Transition SEND_DMA_REQ2->IDLE "9->0"
Transition SCAN_MODE->IDLE "10->0"
CHECKSUM: "3186318530"
INSTANCE:testbench.dma_model
CHECKSUM: "3724579720"
INSTANCE:testbench.clock_gen
CHECKSUM: "4045973507"
INSTANCE:testbench.yumi_gen
CHECKSUM: "783602680"
INSTANCE:testbench.trace_replay
CHECKSUM: "3168410882"
INSTANCE:testbench.test_rom
CHECKSUM: "714139277"
INSTANCE:testbench.reset_gen