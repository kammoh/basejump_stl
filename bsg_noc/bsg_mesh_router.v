// bsg_mesh_router
//
// Dimension ordered routing decoder
// XY_order_p = 0 :  X then Y
// XY_order_p = 1 :  Y then X

module bsg_mesh_router_dor_decoder

// import enum Dirs for directions
import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (processor core)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south
 #( parameter x_cord_width_p  = -1
   ,parameter y_cord_width_p = -1
   ,parameter dirs_lp       = 5
   ,parameter stub_p        = { dirs_lp {1'b0} }  // SNEWP
//   ,parameter allow_S_to_EW_p = 0
   ,parameter XY_order_p    = 1
 )
 ( input clk_i   // debug only
  ,input reset_i // clock only
  ,input [dirs_lp-1:0] v_i

  ,input [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs_i
  ,input [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs_i

  ,input [x_cord_width_p-1:0] my_x_i
  ,input [y_cord_width_p-1:0] my_y_i

  ,output [dirs_lp-1:0][dirs_lp-1:0] req_o
 );

   wire [dirs_lp-1:0] x_eq, x_gt, x_lt;
   wire [dirs_lp-1:0] y_eq, y_gt, y_lt;

   wire [dirs_lp-1:0] v_i_stub = v_i & ~stub_p;

   // this is the routing function;
   genvar            i, j;

   for (i = 0; i < dirs_lp; i=i+1) begin: comps
        assign x_eq[i] = (x_dirs_i[i] == my_x_i);
        assign y_eq[i] = (y_dirs_i[i] == my_y_i);
        assign x_gt[i] = (x_dirs_i[i] > my_x_i);
        assign y_gt[i] = (y_dirs_i[i] > my_y_i);
        assign x_lt[i] = ~x_gt[i] & ~x_eq[i];
        assign y_lt[i] = ~y_gt[i] & ~y_eq[i];
   end

  //-------------------------------------------------------
  // request signals: format req[<input dir>][<output dir>]

if( XY_order_p == 1 ) begin:XY_dor
    for( i=W; i<=E; i++) begin:x2y // X dim to Y dim
        assign req_o[i][N] = v_i_stub[i] & x_eq[i] & y_lt[i];
        assign req_o[i][S] = v_i_stub[i] & x_eq[i] & y_gt[i];
    end

    for( i=N; i<=S; i++) begin:y2x// Y dim to X dim
        assign req_o[i][W] = 1'b0;
        assign req_o[i][E] = 1'b0;
    end

    for( i=W; i<=E; i++) begin// the same X dim routings. For X/Y routing, we don't care Y dimesions.
        assign  req_o[i][W] =  i==W ? 1'b0 : v_i_stub[i] & x_lt[i];
        assign  req_o[i][E] =  i==E ? 1'b0 : v_i_stub[i] & x_gt[i];
    end

    for( i=N; i<=S; i++) begin// the same Y dim routings. For X/Y routing, X must be equal first.
        assign  req_o[i][N] =  i==N ? 1'b0 : v_i_stub[i] & x_eq[i] & y_lt[i];
        assign  req_o[i][S] =  i==S ? 1'b0 : v_i_stub[i] & x_eq[i] & y_gt[i];
    end
    //The request from P
    assign req_o[P][E]  =  v_i_stub[P] & x_gt [P];  //ignore Y cord
    assign req_o[P][W]  =  v_i_stub[P] & x_lt [P];  //ignore Y cord

    assign req_o[P][P]  =  v_i_stub[P] & x_eq[P] & y_eq [P];

    assign req_o[P][S]  =  v_i_stub[P] & x_eq[P] & y_gt [P]; // X must equal
    assign req_o[P][N]  =  v_i_stub[P] & x_eq[P] & y_lt [P]; // X must equal
    //The request to P
    for( i=W; i<=S; i++) begin
        assign req_o[i][P] = v_i_stub[i] & x_eq[i] & y_eq[i];
    end
    //--------------------------------------------------------------
    //  Checking
    //synopsys translate_off
    always@(negedge clk_i)
      begin
         //Y dim to X dim
         assert( (reset_i !== 1'b0)
                 |  ~(
                      (v_i[N]& ~x_eq[N])
                      | (v_i[S] & ~x_eq[S])
                      )
                 ) else
           begin
              $error("%m:Y dim to X dim routing. XY_order_p = %b", XY_order_p);
              $finish();
           end

         // the same X dim routings. For X/Y routing, we don't care Y dimesions.
         assert( (reset_i !== 1'b0)
                 |  ~(
                      (v_i[W] & x_lt[W])
                      | (v_i[E] & x_gt [E] )
                      )
                 ) else
           begin
              $error("%m: X dim loopback routing", XY_order_p);
              $finish();
           end

       // the same Y dim routings. For X/Y routing, X must be equal first.
       assert(  (reset_i !== 1'b0 )
                |  ~(
                     (v_i[N] & x_eq[N] & y_lt[N])
                     | (v_i[S] & x_eq[S] & y_gt [S])
                     )
                ) else
         begin
            $error("%m: Y dim loopback routing", XY_order_p);
            $finish();
         end
    end
    //synopsys translate_on

    //--------------------------------------------------------------
end else begin:YX_dor
    for( i=W; i<=E; i++) begin:x2y // X dim to Y dim
        assign req_o[i][N] = 1'b0;
        assign req_o[i][S] = 1'b0;
    end

    for( i=N; i<=S; i++) begin:y2x // Y dim to X dim
        assign req_o[i][W] = v_i_stub[i] & y_eq[i] & x_lt[i];
        assign req_o[i][E] = v_i_stub[i] & y_eq[i] & x_gt[i];
    end

    for( i=N; i<=S; i++) begin// the same Y dim routings. For Y/X routing, we don't care X dimesions
        assign req_o[i][N] =  i==N ? 1'b0 : v_i_stub[i] &  y_lt[i];
        assign req_o[i][S] =  i==S ? 1'b0 : v_i_stub[i] &  y_gt[i];
    end

    for( i=W; i<=E; i++) begin// the same X dim routings. For Y/X routing, Y must equal first
        assign req_o[i][W] =  i==W ? 1'b0 : v_i_stub[i] & y_eq[i] & x_lt[i];
        assign req_o[i][E] =  i==E ? 1'b0 : v_i_stub[i] & y_eq[i] & x_gt[i];
    end

    //The request from P
    assign req_o[P][S]  =  v_i_stub[P] & y_gt [P];  //ignore X cord
    assign req_o[P][N]  =  v_i_stub[P] & y_lt [P];  //ignore X cord

    assign req_o[P][P]  =  v_i_stub[P] & x_eq[P] & y_eq [P];

    assign req_o[P][E]  =  v_i_stub[P] & y_eq[P] & x_gt [P]; // Y must equal first
    assign req_o[P][W]  =  v_i_stub[P] & y_eq[P] & x_lt [P]; // Y must equal first
    //The request to P
    for( i=W; i<=S; i++) begin
        assign req_o[i][P] = v_i_stub[i] & x_eq[i] & y_eq[i];
    end
    //--------------------------------------------------------------
    //  Checking
    //synopsys translate_off
    always@(negedge clk_i)
      begin
         //X dim to Y dim
         assert( (reset_i !== 1'b0)
                 | ~(
                     (v_i[W] & ~y_eq[W])
                     | (v_i[E] & ~y_eq[E])
                     )
                 ) else
           begin
              $error("%m:X dim to Y dim routing. XY_order_p = %b", XY_order_p);
              $finish();
           end

         // the same X dim routings. For Y/X routing, Y must be equal first
         assert( (reset_i !== 1'b0)
                 | ~(
                     (v_i[W] & y_eq[W] & x_lt[W])
                     | (v_i[E] & y_eq[E] & x_gt [E] )
                     )
                 ) else
           begin
              $error("%m: X dim loopback routing", XY_order_p);
              $finish();
           end

         // the same Y dim routings. For Y/X routing, ignore X cord
         assert( (reset_i !== 1'b0)
                 | ~(
                     (v_i  [N] & y_lt[N])
                     | (v_i[S] & y_gt[S])
                     )
                 )
           else
             begin
                $error("%m: Y dim loopback routing", XY_order_p);
                $finish();
             end
      end
   //synopsys translate_on
   //--------------------------------------------------------------
end
endmodule


module bsg_mesh_router
import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (processor core)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south
    #(
         parameter width_p        = -1
        ,parameter x_cord_width_p = -1
        ,parameter y_cord_width_p = -1
        ,parameter debug_p       = 0
        ,parameter dirs_lp       = 5
        ,parameter stub_p        = { dirs_lp {1'b0} }  // SNEWP
        ,parameter XY_order_p    = 1
        )
   (  input clk_i
     ,input reset_i

     // dirs: NESWP (P=0, W=1, E=2, N=3, S=4)

     ,input   [dirs_lp-1:0] [width_p-1:0] data_i  // from input twofer
     ,input   [dirs_lp-1:0]               v_i // from input twofer
     ,output  logic [dirs_lp-1:0]         yumi_o  // to input twofer

     ,input   [dirs_lp-1:0]               ready_i // from output twofer
     ,output  [dirs_lp-1:0] [width_p-1:0] data_o  // to output twofer
     ,output  logic [dirs_lp-1:0]         v_o // to output twofer

     ,input   [x_cord_width_p-1:0] my_x_i           // node's x and y coord
     ,input   [y_cord_width_p-1:0] my_y_i
     );

   wire [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs;
   wire [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs;

   // stubbed ports accept all I/O and send none.

   wire [dirs_lp-1:0] ready_i_stub = ready_i | stub_p;
   wire [dirs_lp-1:0] v_i_stub     = v_i     & ~stub_p;

   genvar                               i;

   for (i = 0; i < dirs_lp; i=i+1)
     begin: reshape
        assign x_dirs[i] = data_i[i][0+:x_cord_width_p];
        assign y_dirs[i] = data_i[i][x_cord_width_p+:y_cord_width_p];
     end

   wire [dirs_lp-1:0][dirs_lp-1:0] req;

   bsg_mesh_router_dor_decoder  #( .x_cord_width_p  (x_cord_width_p)
                                   ,.y_cord_width_p (y_cord_width_p)
                                   ,.dirs_lp        (dirs_lp       )
                                   ,.XY_order_p     (XY_order_p    )
                                   ) dor_decoder
     (  .clk_i(clk_i)     // debug only
       ,.reset_i(reset_i) // debug only
       ,.v_i            (v_i_stub)
       ,.my_x_i
       ,.my_y_i
       ,.x_dirs_i       (x_dirs)
       ,.y_dirs_i       (y_dirs)
       ,.req_o          (req)
       );

   // grant signals: format <output dir>_gnt_<input dir>
   // these determine whose data we actually send
   wire P_gnt_p, P_gnt_e, P_gnt_s, P_gnt_n, P_gnt_w;
   wire W_gnt_e, W_gnt_p;
   wire E_gnt_w, E_gnt_p;
   wire N_gnt_s, N_gnt_p;
   wire S_gnt_n, S_gnt_p;
   // for XY_order_p = 1 only
        wire N_gnt_e, N_gnt_w;
        wire S_gnt_e, S_gnt_w;
   // for XY_order_p = 0 only
        wire W_gnt_n, W_gnt_s;
        wire E_gnt_n, E_gnt_s;

   // selection signals
   wire P_sel_p, P_sel_e, P_sel_s, P_sel_n, P_sel_w;
   wire W_sel_e, W_sel_p;
   wire E_sel_w, E_sel_p;
   wire N_sel_s, N_sel_p;
   wire S_sel_n, S_sel_p;
   // for XY_order_p = 1 only
        wire N_sel_e, N_sel_w;
        wire S_sel_e, S_sel_w;
   // for XY_order_p = 0 only
        wire W_sel_n, W_sel_s;
        wire E_sel_n, E_sel_s;

   //------------------------------------------------
   // To West
   if( XY_order_p == 1) begin
        bsg_round_robin_arb #(.inputs_p(2)
                             ) west_rr_arb
               (.clk_i
                ,.reset_i
                ,.grants_en_i(ready_i_stub[W])

                ,.reqs_i             ({req[E][W],    req[P][W]})
                ,.grants_o           ({W_gnt_e,      W_gnt_p})
                ,.sel_one_hot_o      ({W_sel_e,      W_sel_p})

                ,.v_o    (v_o[W])
                ,.tag_o  ()
                ,.yumi_i (v_o[W] & ready_i_stub[W])
                );
         bsg_mux_one_hot #(.width_p(width_p)
                               ,.els_p(2)
                               ) mux_data_west
               ( .data_i        ({data_i[P], data_i[E]})
                ,.sel_one_hot_i ({W_sel_p  , W_sel_e  })
                ,.data_o       (data_o[W])
               );
        assign W_gnt_n = 1'b0;
        assign W_gnt_s = 1'b0;
   end else begin
        bsg_round_robin_arb #(.inputs_p(4)
                             ) west_rr_arb
               (.clk_i
                ,.reset_i
                ,.grants_en_i(ready_i_stub[W])

                ,.reqs_i             ({req[E][W],       req[P][W], req[N][W],      req[S][W]})
                ,.grants_o           ({W_gnt_e,         W_gnt_p,   W_gnt_n,        W_gnt_s  })
                ,.sel_one_hot_o      ({W_sel_e,         W_sel_p,   W_sel_n,        W_sel_s  })

                ,.v_o    (v_o[W])
                ,.tag_o  ()
                ,.yumi_i (v_o[W] & ready_i_stub[W])
                );
         bsg_mux_one_hot #(.width_p(width_p)
                               ,.els_p(4)
                               ) mux_data_west
               ( .data_i        ({data_i[P], data_i[E], data_i[N], data_i[S]})
                ,.sel_one_hot_i ({W_sel_p  , W_sel_e  , W_sel_n,   W_sel_s  })
                ,.data_o       (data_o[W])
               );
   end
   //------------------------------------------------
   // To East
   if (XY_order_p == 1) begin
        bsg_round_robin_arb #(.inputs_p(2)
                        ) east_rr_arb
          ( .clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[E])

           ,.reqs_i             ({req[W][E],    req[P][E]})
           ,.grants_o           ({E_gnt_w,      E_gnt_p})
           ,.sel_one_hot_o      ({E_sel_w,      E_sel_p})

           ,.v_o   (v_o[E])
           ,.tag_o ()
           ,.yumi_i(v_o[E] & ready_i_stub[E])
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(2)
                          ) mux_data_east
          ( .data_i        ({data_i[P], data_i[W]})
           ,.sel_one_hot_i ({E_sel_p  , E_sel_w  })
           ,.data_o       (data_o[E])
           );
        assign E_gnt_n = 1'b0;
        assign E_gnt_s = 1'b0;
   end else begin
        bsg_round_robin_arb #(.inputs_p(4)
                        ) east_rr_arb
          ( .clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[E])

           ,.reqs_i             ({req[W][E],    req[P][E],      req[N][E],      req[S][E]})
           ,.grants_o           ({E_gnt_w,      E_gnt_p,        E_gnt_n,        E_gnt_s  })
           ,.sel_one_hot_o      ({E_sel_w,      E_sel_p,        E_sel_n,        E_sel_s  })

           ,.v_o   (v_o[E])
           ,.tag_o ()
           ,.yumi_i(v_o[E] & ready_i_stub[E])
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(4)
                          ) mux_data_east
          ( .data_i        ({data_i[P], data_i[W], data_i[N], data_i[S]})
           ,.sel_one_hot_i ({E_sel_p  , E_sel_w,   E_sel_n,   E_sel_s  })
           ,.data_o       (data_o[E])
           );
   end
   //------------------------------------------------
   // To North
   if(XY_order_p == 1) begin
        bsg_round_robin_arb #(.inputs_p(4)
                              ) north_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[N])

           ,.reqs_i          ({req[S][N], req[E][N], req[W][N], req[P][N]})
           ,.grants_o        ({ N_gnt_s,  N_gnt_e,   N_gnt_w,   N_gnt_p })
           ,.sel_one_hot_o   ({ N_sel_s,  N_sel_e,   N_sel_w,   N_sel_p })

           ,.v_o   (v_o[N])
           ,.tag_o ()
           ,.yumi_i(v_o[N] & ready_i_stub[N])
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(4)
                          ) mux_data_north
          (.data_i        ({data_i[P], data_i[E], data_i[S], data_i[W]})
           ,.sel_one_hot_i({N_sel_p  , N_sel_e  , N_sel_s  , N_sel_w  })
           ,.data_o       (data_o[N])
           );
   end else begin
        assign N_gnt_e = 1'b0;
        assign N_gnt_w = 1'b0;
        bsg_round_robin_arb #(.inputs_p(2)
                              ) north_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[N])

           ,.reqs_i          ({req[S][N], req[P][N]})
           ,.grants_o        ({ N_gnt_s,  N_gnt_p })
           ,.sel_one_hot_o   ({ N_sel_s,  N_sel_p })

           ,.v_o   (v_o[N])
           ,.tag_o ()
           ,.yumi_i(v_o[N] & ready_i_stub[N])
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(2)
                          ) mux_data_north
          (.data_i        ({data_i[P],  data_i[S] })
           ,.sel_one_hot_i({N_sel_p  ,  N_sel_s   })
           ,.data_o       (data_o[N])
           );
   end
   //------------------------------------------------
   // To South
   if(XY_order_p == 1) begin
        bsg_round_robin_arb #(.inputs_p(4)
                              ) south_rr_arb
          (.clk_i
           ,.reset_i

           ,.grants_en_i(ready_i_stub[S])

           ,.reqs_i          ({req[N][S], req[E][S], req[W][S], req[P][S]})
           ,.grants_o        ({ S_gnt_n,  S_gnt_e,   S_gnt_w,   S_gnt_p })
           ,.sel_one_hot_o   ({ S_sel_n,  S_sel_e,   S_sel_w,   S_sel_p })

           ,.v_o   (v_o[S])
           ,.tag_o ()
           ,.yumi_i(v_o[S] & ready_i_stub[S] )
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(4)
                          ) mux_data_south
          (.data_i        ({data_i[P], data_i[E], data_i[N], data_i[W]})
           ,.sel_one_hot_i({S_sel_p  , S_sel_e  , S_sel_n  , S_sel_w  })
           ,.data_o       (data_o[S])
          );
   end else begin
        assign S_gnt_e = 1'b0;
        assign S_gnt_w = 1'b0;
        bsg_round_robin_arb #(.inputs_p(2)
                              ) south_rr_arb
          (.clk_i
           ,.reset_i

           ,.grants_en_i(ready_i_stub[S])

           ,.reqs_i          ({req[N][S], req[P][S]})
           ,.grants_o        ({ S_gnt_n,  S_gnt_p })
           ,.sel_one_hot_o   ({ S_sel_n,  S_sel_p })

           ,.v_o   (v_o[S])
           ,.tag_o ()
           ,.yumi_i(v_o[S] & ready_i_stub[S] )
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(2)
                          ) mux_data_south
          (.data_i        ({data_i[P],  data_i[N] })
           ,.sel_one_hot_i({S_sel_p  ,  S_sel_n   })
           ,.data_o       (data_o[S])
          );
   end
   //------------------------------------------------
   // To Processor
   bsg_round_robin_arb #(.inputs_p(5)
                         ) proc_rr_arb
     (.clk_i
      ,.reset_i
      ,.grants_en_i(ready_i_stub[P])

      ,.reqs_i          ({req[S][P], req[N][P], req[E][P], req[W][P], req[P][P]})
      ,.grants_o        ({ P_gnt_s,  P_gnt_n,   P_gnt_e,   P_gnt_w,   P_gnt_p })
      ,.sel_one_hot_o   ({ P_sel_s,  P_sel_n,   P_sel_e,   P_sel_w,   P_sel_p })

      ,.v_o   (v_o[P])
      ,.tag_o ()
      ,.yumi_i(v_o[P] & ready_i_stub[P])
      );

   bsg_mux_one_hot #(.width_p(width_p)
                     ,.els_p(5)
                     ) mux_data_proc
     (.data_i        ({data_i[P], data_i[E], data_i[S], data_i[W], data_i[N]})
      ,.sel_one_hot_i({P_sel_p  , P_sel_e  , P_sel_s  , P_sel_w  , P_sel_n  })
      ,.data_o       (data_o[P])
      );


   // yumi signals; this deques the data from the inputs

   assign yumi_o[P] = E_gnt_p | N_gnt_p | S_gnt_p | P_gnt_p | W_gnt_p;

   if( XY_order_p == 1) begin
        assign yumi_o[W] = E_gnt_w | N_gnt_w | S_gnt_w | P_gnt_w;
        assign yumi_o[E] = W_gnt_e | N_gnt_e | S_gnt_e | P_gnt_e;
        assign yumi_o[N] = S_gnt_n | P_gnt_n;
        assign yumi_o[S] = N_gnt_s | P_gnt_s;
   end else begin
        assign yumi_o[W] = E_gnt_w | P_gnt_w;
        assign yumi_o[E] = W_gnt_e | P_gnt_e;
        assign yumi_o[N] = S_gnt_n | W_gnt_n | E_gnt_n | P_gnt_n;
        assign yumi_o[S] = N_gnt_s | W_gnt_s | E_gnt_s | P_gnt_s;
   end

   // synopsys translate_off
   if (debug_p)
     for (i = P; i <= S; i=i+1)
       begin: rof
          Dirs dir = Dirs ' (i);

          always_ff @(negedge clk_i)
            begin
               if (v_i_stub[i])
                 $display("%m wants to send %x to {x,y}={%x,%x} from dir %s, req[SNEWP] = %b, ready_i[SNEWP] = %b"
                          , data_i[i], x_dirs[i],y_dirs[i],dir.name(), req[i], ready_i_stub);
               if (v_o[i])
                 $display("%m sending %x in dir %s", data_o[i], dir.name());
            end
       end

   // synopsys translate_on

endmodule
