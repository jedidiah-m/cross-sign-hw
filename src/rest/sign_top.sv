`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sign_top(
    input  logic clk,
    input  logic rst,
    input  logic shift_seed_sk,
    input  logic [w-1:0] data_system,
    input  logic shift_seed_lambda,
    input  logic [w-1:0] seed_lambda,
    input  logic shift_salt,
    input  logic [w-1:0] salt,
    input  logic shift_message,
    input  logic [w-1:0]message,
    input  logic request_signature,
    output logic module_response,
    output logic [w-1:0] valid_signature_out,
    output logic occupied
    );

logic [3:0] write_sig_group;
logic write_sig;
logic [w-1:0] signature;

logic finished_ebar;
logic write_ebar;
logic [16*Z_BIT_WIDTH-1:0] place_ebar,place_memory_e_inst;
logic finished_vt;
logic write_vt;
logic [16*P_BIT_WIDTH-1:0] place_vt,place_memory_u_inst;
   //connect to shake
logic ready_o,ready_o_out;
logic valid_i,valid_i_out;
logic clear_in,clear_in_out;
logic ready_i;
logic valid_o;
logic [w-1:0] data_i,data_i_out;
logic [w-1:0] data_o;
logic [w-1:0] data_seed_lambda;
logic [w-1:0] data_salt;
logic [w-1:0] data_temp1,data_out_cmt_mem;
logic [w-1:0] data_temp2,data_o_stree,output_a,data_o_inst_gen,output_b;
logic rq_tmp;
logic [14:0]r_address_cmt,r_address_cmt_b;

logic [10:0] del_address_1;
logic del_write_1;
logic [16*P_BIT_WIDTH-1:0] del_data_in_1,v_t_1a;

logic [10:0] del_address_2;
logic del_write_2;
logic [16*P_BIT_WIDTH-1:0] del_data_in_2,v_t_2a;

logic [10:0] del_address_3;
logic del_write_3;
logic [16*P_BIT_WIDTH-1:0] del_data_in_3,v_t_1b;

logic [10:0] del_address_4;
logic del_write_4;
logic [16*P_BIT_WIDTH-1:0] del_data_in_4,v_t_2b;

logic [1:0] select_gen_inst;
logic [8:0] index_next_seed;

logic [12:0] del_address_e_bar_prime_1a;
logic [16*Z_BIT_WIDTH-1:0] del_data_in_e_bar_prime_1a;
logic [12:0] del_address_e_bar_prime_2a;
logic [16*Z_BIT_WIDTH-1:0] del_data_in_e_bar_prime_2a;
logic [12:0] del_address_e_bar_prime_1b;
logic [16*Z_BIT_WIDTH-1:0] del_data_in_e_bar_prime_1b;
logic [12:0] del_address_e_bar_prime_2b;
logic [16*Z_BIT_WIDTH-1:0] del_data_in_e_bar_prime_2b;

logic [12:0] del_address_u_prime_1a;
logic [16*P_BIT_WIDTH-1:0] del_data_in_u_prime_1a;
logic [12:0] del_address_u_prime_2a;
logic [16*P_BIT_WIDTH-1:0] del_data_in_u_prime_2a;
logic [12:0] del_address_u_prime_1b;
logic [16*P_BIT_WIDTH-1:0] del_data_in_u_prime_1b;
logic [12:0] del_address_u_prime_2b;
logic [16*P_BIT_WIDTH-1:0] del_data_in_u_prime_2b;

logic [w-1:0] comp_v_1a,comp_s_1a,comp_data_1a, comp_v_2a,comp_s_2a,comp_data_2a, comp_v_1b,comp_s_1b,comp_data_1b, comp_v_2b,comp_s_2b,comp_data_2b,compressed_v,data_out_b,data_out_c,data_out_cmt_mem_del;
logic [3:0] shift_v_all;

logic [1:0] select_branch_cmt0;
logic [14:0] raddress_read_cmt;
logic occ_mess,write_dig_cmt,occupied_reg;

logic [16*P_BIT_WIDTH-1:0]vector_u_prime_1a;
logic [16*Z_BIT_WIDTH-1:0]vector_e_bar_prime_1a;
logic [16*P_BIT_WIDTH-1:0]vector_u_prime_2a;
logic [16*Z_BIT_WIDTH-1:0]vector_e_bar_prime_2a;
logic [16*P_BIT_WIDTH-1:0]vector_u_prime_1b;
logic [16*Z_BIT_WIDTH-1:0]vector_e_bar_prime_1b;
logic [16*P_BIT_WIDTH-1:0]vector_u_prime_2b;
logic [16*Z_BIT_WIDTH-1:0]vector_e_bar_prime_2b;

logic [(4*P_BIT_WIDTH)-1:0]data_out_first_chall;


logic [w-1:0]data_in_yt_comp;
logic [13:0]r_address_yt_comp;
logic [13:0]addra_yt_comp;
logic [w-1:0]dina_yt_comp;
logic [0:0]chall_second;
logic [2:0]bytes_comp_mux;
logic [w-1:0]data_in_comp_mux,y2mem,comp_y1,comp_y2,comp_y3,comp_y4,douta_yt,dd_value_ch2,data_out_d,data_out_sec,written_response;

logic [1:0]select_write_chall_2;
logic [8:0]index_chall_2;

logic write_to_signature_a;
logic [13:0]address_signature_a;
logic [w-1:0]data_in_signature_a;
logic write_to_signature_b;
logic [13:0]address_signature_b;
logic [w-1:0]data_in_signature_b;

logic write_seed_signature,write_cmt0_signature,write_cmt1_signature,write_yv_signature;

logic [w-1:0]unreg_valid_signature_out;
logic unreg_module_response;

assign shift_v_all = {shift_v_1a,shift_v_2a,shift_v_1b,shift_v_2b};

always_comb begin
   compressed_v = 0;
   case(shift_v_all)
      4'b1000: compressed_v = comp_v_1a;
      4'b0100: compressed_v = comp_v_2a;
      4'b0010: compressed_v = comp_v_1b;
      4'b0001: compressed_v = comp_v_2b;
   endcase
end

key_generation_stage expand(
    .clk (clk),
    .rst (rst),
    .shift_seed_sk (shift_seed_sk),
    .data_system (data_system),
    .finished_ebar (finished_ebar),
    .write_ebar (write_ebar),
    .place_ebar (place_ebar),
    .finished_vt (finished_vt),
    .write_vt (write_vt),
    .place_vt (place_vt),
    //connect to shake
    .ready_o (ready_o),
    .valid_i (valid_i),
    .clear_in (clear_in),
    .ready_i (ready_i),
    .valid_o (valid_o),
    .data_i (data_i),
    .data_o (data_o)
    );
    
shake_input_control inpt(
    .clk         (clk),
    .rst         (rst),
    .init        (0),
    .switch      (finished_vt||finished_tree||fin_gen_inst),
    .ready_o     (((ready_o||ready_o_stree)||(ready_o_dvs||ready_o_cmt)) || ((ready_o_c||ready_o_ch1)||(ready_o_sec_chall))),
    .valid_i     (valid_i||valid_i_stree||valid_i_inst_gen||valid_i_c),
    .clear_in    (clear_in||clear_stree||clear_inst_gen||clear_c),
    .data_i      (data_i),
    .data_i2     (data_o_stree),
    .data_i3     (data_o_inst_gen),
    .data_i4     (data_out_c),
    .reset_logic (finished_vt),
    .ready_o_out (ready_o_out),
    .valid_i_out (valid_i_out),
    .clear_in_out(clear_in_out),
    .data_i_out  (data_i_out),
    .shake_reset (shake_reset)
);
    
shake128or256 shake(
    .clk (clk),
    .rst (rst||shake_reset),
    .ready_o (ready_o_out),
    .valid_i (valid_i_out),
    .clear_in (clear_in_out),
    .ready_i (ready_i),
    .valid_o (valid_o),
    .data_i (data_i_out),
    .data_o (data_o)
    );

arithmetic_unit alu_1a(
    .clk               (clk),//(clk),
    .rst               (rst),//(rst),
    .write_vt          (response_1a),//(write_vt),
    .finished_vt       (finished_vt_1a),//(finished_vt),
    .v_t               (v_t_1a),//(v_t),
    .chall_1           (data_out_first_chall[(4*P_BIT_WIDTH)-1:3*P_BIT_WIDTH]),//(chall_1),
    .push_v1           (shift_v_1a),//(push_v1),
    .push_s            (shift_s_1a),//(push_s),
    .push_y            (push_y1),//(push_y),
//    .vector_shift      (0),//(vector_shift),
    .write_e_bar       (write_ebar),//(write_e_bar),
    .write_e_bar_prime (write_out_e_inst&&(select_gen_inst == 0)),//(write_e_bar_prime),
    .write_u_prime     (write_out_u_inst&&(select_gen_inst == 0)),//(write_u_prime),
    .place_e_bar       (place_ebar),//(place_e_bar),
    .place_e_bar_prime (place_memory_e_inst),//(place_e_bar_prime),
    .place_u_prime     (place_memory_u_inst),//(place_u_prime),
    .comp_v1           (comp_v_1a),//(comp_v1),
    .comp_s            (comp_s_1a),//(comp_s),
    .ended             (ended_1a),
    .comp_y            (comp_y1),//(comp_y)
    .vector_u_prime    (vector_u_prime_1a),
    .vector_e_bar_prime(vector_e_bar_prime_1a),
    .response          (response_1a_mem)
    );
    
digest_prep#(
    .OFFSET(0)
)comp_res_1a(
    .clk       (clk),
    .rst       (rst),
    .end_matrix(ended_1a),
    .clear     (clear_1a),
    .access    (access_1a),
    .comp_s    (comp_s_1a),
    .comp_v    (comp_v_1a),
    .data_temp1(data_temp1),
    .write_cmt1(write_cmt1),
    .ready     (ready_1a),
    .shift_s   (shift_s_1a),
    .shift_v   (shift_v_1a),
    .sft_tmp1  (sft_tmp1_1a),
    .comp_data (comp_data_1a)
    );
    
arithmetic_unit alu_2a(
    .clk               (clk),//(clk),
    .rst               (rst),//(rst),
    .write_vt          (response_2a),//(write_vt),
    .finished_vt       (finished_vt_2a),//(finished_vt),
    .v_t               (v_t_2a),//(v_t),
    .chall_1           (data_out_first_chall[(3*P_BIT_WIDTH)-1:2*P_BIT_WIDTH]),//(chall_1),
    .push_v1           (shift_v_2a),//(push_v1),
    .push_s            (shift_s_2a),//(push_s),
    .push_y            (push_y2),//(push_y),
//    .vector_shift      (0),//(vector_shift),
    .write_e_bar       (write_ebar),//(write_e_bar),
    .write_e_bar_prime (write_out_e_inst&&(select_gen_inst == 1)),//(write_e_bar_prime),
    .write_u_prime     (write_out_u_inst&&(select_gen_inst == 1)),//(write_u_prime),
    .place_e_bar       (place_ebar),//(place_e_bar),
    .place_e_bar_prime (place_memory_e_inst),//(place_e_bar_prime),
    .place_u_prime     (place_memory_u_inst),//(place_u_prime),
    .comp_v1           (comp_v_2a),//(comp_v1),
    .comp_s            (comp_s_2a),//(comp_s),
    .ended             (ended_2a),
    .comp_y            (comp_y2),//(comp_y)
    .vector_u_prime    (vector_u_prime_2a),
    .vector_e_bar_prime(vector_e_bar_prime_2a),
    .response          (response_2a_mem)//(comp_y)
    );
    
digest_prep#(
    .OFFSET(1)
)comp_res_2a(
    .clk       (clk),
    .rst       (rst),
    .end_matrix(ended_2a),
    .clear     (clear_2a),
    .access    (access_2a),
    .comp_s    (comp_s_2a),
    .comp_v    (comp_v_2a),
    .data_temp1(data_temp1),
    .write_cmt1(write_cmt1),
    .ready     (ready_2a),
    .shift_s   (shift_s_2a),
    .shift_v   (shift_v_2a),
    .sft_tmp1  (sft_tmp1_2a),
    .comp_data (comp_data_2a)
    );
    
arithmetic_unit alu_1b(
    .clk               (clk),//(clk),
    .rst               (rst),//(rst),
    .write_vt          (response_1b),//(write_vt),
    .finished_vt       (finished_vt_1b),//(finished_vt),
    .v_t               (v_t_1b),//(v_t),
    .chall_1           (data_out_first_chall[(2*P_BIT_WIDTH)-1:P_BIT_WIDTH]),//(chall_1),
    .push_v1           (shift_v_1b),//(push_v1),
    .push_s            (shift_s_1b),//(push_s),
    .push_y            (push_y3),//(push_y),
//    .vector_shift      (0),//(vector_shift),
    .write_e_bar       (write_ebar),//(write_e_bar),
    .write_e_bar_prime (write_out_e_inst&&(select_gen_inst == 2)),//(write_e_bar_prime),
    .write_u_prime     (write_out_u_inst&&(select_gen_inst == 2)),//(write_u_prime),
    .place_e_bar       (place_ebar),//(place_e_bar),
    .place_e_bar_prime (place_memory_e_inst),//(place_e_bar_prime),
    .place_u_prime     (place_memory_u_inst),//(place_u_prime),
    .comp_v1           (comp_v_1b),//(comp_v1),
    .comp_s            (comp_s_1b),//(comp_s),
    .ended             (ended_1b),
    .comp_y            (comp_y3),//(comp_y)
    .vector_u_prime    (vector_u_prime_1b),
    .vector_e_bar_prime(vector_e_bar_prime_1b),
    .response          (response_1b_mem)//(comp_y)
    );
    
digest_prep#(
    .OFFSET(2)
)comp_res_1b(
    .clk       (clk),
    .rst       (rst),
    .end_matrix(ended_1b),
    .clear     (clear_1b),
    .access    (access_1b),
    .comp_s    (comp_s_1b),
    .comp_v    (comp_v_1b),
    .data_temp1(data_temp1),
    .write_cmt1(write_cmt1),
    .ready     (ready_1b),
    .shift_s   (shift_s_1b),
    .shift_v   (shift_v_1b),
    .sft_tmp1  (sft_tmp1_1b),
    .comp_data (comp_data_1b)
    );
    
arithmetic_unit alu_2b(
    .clk               (clk),//(clk),
    .rst               (rst),//(rst),
    .write_vt          (response_2b),//(write_vt),
    .finished_vt       (finished_vt_2b),//(finished_vt),
    .v_t               (v_t_2b),//(v_t),
    .chall_1           (data_out_first_chall[P_BIT_WIDTH-1:0]),//(chall_1),
    .push_v1           (shift_v_2b),//(push_v1),
    .push_s            (shift_s_2b),//(push_s),
    .push_y            (push_y4),//(push_y),
//    .vector_shift      (0),//(vector_shift),
    .write_e_bar       (write_ebar),//(write_e_bar),
    .write_e_bar_prime (write_out_e_inst&&(select_gen_inst == 3)),//(write_e_bar_prime),
    .write_u_prime     (write_out_u_inst&&(select_gen_inst == 3)),//(write_u_prime),
    .place_e_bar       (place_ebar),//(place_e_bar),
    .place_e_bar_prime (place_memory_e_inst),//(place_e_bar_prime),
    .place_u_prime     (place_memory_u_inst),//(place_u_prime),
    .comp_v1           (comp_v_2b),//(comp_v1),
    .comp_s            (comp_s_2b),//(comp_s),
    .ended             (ended_2b),
    .comp_y            (comp_y4),//(comp_y)
    .vector_u_prime    (vector_u_prime_2b),
    .vector_e_bar_prime(vector_e_bar_prime_2b),
    .response          (response_2b_mem)//(comp_y)
    );
    
digest_prep#(
    .OFFSET(3)
)comp_res_2b(
    .clk       (clk),
    .rst       (rst),
    .end_matrix(ended_2b),
    .clear     (clear_2b),
    .access    (access_2b),
    .comp_s    (comp_s_2b),
    .comp_v    (comp_v_2b),
    .data_temp1(data_temp1),
    .write_cmt1(write_cmt1),
    .ready     (ready_2b),
    .shift_s   (shift_s_2b),
    .shift_v   (shift_v_2b),
    .sft_tmp1  (sft_tmp1_2b),
    .comp_data (comp_data_2b)
    );

request_matrix req_1a(
    .clk     (clk),
    .rst     (rst),
    .pulse   (finished_u_inst&&(select_gen_inst == 0)),
    .request (request_1a)
    );
    
request_matrix req_2a(
    .clk     (clk),
    .rst     (rst),
    .pulse   (finished_u_inst&&(select_gen_inst == 1)),
    .request (request_2a)
    );
    
request_matrix req_1b(
    .clk     (clk),
    .rst     (rst),
    .pulse   (finished_u_inst&&(select_gen_inst == 2)),
    .request (request_1b)
    );
    
request_matrix req_2b(
    .clk     (clk),
    .rst     (rst),
    .pulse   (finished_u_inst&&(select_gen_inst == 3)),
    .request (request_2b)
    );

vt_memory_control access_matrix_1a(
   .clk          (clk),
   .rst          (rst),
   .write        (write_vt),
   .req          (request_1a),
   .data_in      (place_vt),
   .del_address  (del_address_1),
   .del_write    (del_write_1),
   .del_data_in  (del_data_in_1),
   .rsp          (response_1a),
   .finished_vt  (finished_vt_1a)
);

vt_memory_control access_matrix_2a(
   .clk          (clk),
   .rst          (rst),
   .write        (0),
   .req          (request_2a),
   .data_in      (0),
   .del_address  (del_address_2),
   .del_write    (del_write_2),
   .del_data_in  (del_data_in_2),
   .rsp          (response_2a),
   .finished_vt  (finished_vt_2a)
);

vt_memory_select store_matrix_a(
    .clka (clk),
    .addra(del_address_1),
    .dina (del_data_in_1),
    .wea  (del_write_1),
    .douta(v_t_1a),
    .clkb (clk),
    .addrb(del_address_2),
    .dinb (del_data_in_2),
    .web  (del_write_2),
    .doutb(v_t_2a)
);

vt_memory_control access_matrix_1b(
   .clk          (clk),
   .rst          (rst),
   .write        (write_vt),
   .req          (request_1b),
   .data_in      (place_vt),
   .del_address  (del_address_3),
   .del_write    (del_write_3),
   .del_data_in  (del_data_in_3),
   .rsp          (response_1b),
   .finished_vt  (finished_vt_1b)
);

vt_memory_control access_matrix_2b(
   .clk          (clk),
   .rst          (rst),
   .write        (0),
   .req          (request_2b),
   .data_in      (0),
   .del_address  (del_address_4),
   .del_write    (del_write_4),
   .del_data_in  (del_data_in_4),
   .rsp          (response_2b),
   .finished_vt  (finished_vt_2b)
);

vt_memory_select store_matrix_b(
    .clka (clk),
    .addra(del_address_3),
    .dina (del_data_in_3),
    .wea  (del_write_3),
    .douta(v_t_1b),
    .clkb (clk),
    .addrb(del_address_4),
    .dinb (del_data_in_4),
    .web  (del_write_4),
    .doutb(v_t_2b)
);

pad_generator salt_store(
   .clk      (clk),
   .reset    (rst),
   .shift    (shift_salt),
   .rotate   (rotate_salt_s_tree||rotate_salt_inst_sam||rotate_salt_c),
   .data_in  (salt),
   .data_out (data_salt)
);

pad_generator #(
     .DEPTH(LAMBDA/w)
)seed_lambda_store(
   .clk      (clk),
   .reset    (rst),
   .shift    (shift_seed_lambda),
   .rotate   (rotate_seed_lambda),
   .data_in  (seed_lambda),
   .data_out (data_seed_lambda)
);

occupied_module occ(
   .clk               (clk),
   .rst               (rst),
   .shift_seed_sk     (shift_seed_sk),
   .shift_seed_lambda (shift_seed_lambda),
   .shift_salt        (shift_salt),
   .raise             (raise_occ),
   .finished_vt       (finished_vt||lower_occ||restart_chall_second),
   .occupied          (occupied_reg),
   .start_tree_gen    (start_tree_gen)
    );

pad_generator tmp_st_1(
   .clk      (clk),
   .reset    (rst),
   .shift    ((shift_tmp1||relocate_salt)||(shift_tmp1_c)),
   .rotate   ((sft_tmp1_1a||sft_tmp1_2a)||(sft_tmp1_1b||sft_tmp1_2b)||rotate_tmp1_c),
   .data_in  ((relocate_salt) ? data_salt : data_o),
   .data_out (data_temp1)
);

pad_generator tmp_st_2(
   .clk      (clk),
   .reset    (rst),
   .shift    ((shift_tmp2)||(shift_tmp2_c)||(shift_tmp_2_d)),
   .rotate   ((rotate_tmp2_c)||(push_dig_chall_1)||(rotate_tmp_2_d)),
   .data_in  (data_o),
   .data_out (data_temp2)
);

sig_process_mem_control memory_cmt(
    .clk         (clk),
    .rst         (rst),
    .write_seed  (write_seed),
    .write_cmt0  (write_cmt0_b),
    .write_cmt1  (write_cmt1),
    .write_v     ((shift_v_1a||shift_v_2a)||(shift_v_1b||shift_v_2b)),
    .write_y     (write_y_resp),
    .seed        (data_o),
    .cmt0        (data_o),
    .cmt1        (data_o),
    .v           (compressed_v),
    .y           (y2mem),
    .req         (rq_tmp|req_read_cmt),
    .raddress    ((r_address_cmt)|(raddress_read_cmt)),
    .data_out    (data_out_cmt_mem),
    .rsp         (response_cmt),
    .req_sec     (rq_tmp_b),
    .raddress_sec(r_address_cmt_b),
    .data_out_sec(data_out_sec),
    .rsp_sec     (rsp_sec)
    );

generate_seed_tree s_tree(
   .clk               (clk),
   .rst               (rst),
   .start_tree_gen    (start_tree_gen),
   .seed_lambda       (data_seed_lambda),
   .salt              (data_salt),
   .data_temp1        (data_temp1),
   .data_temp2        (data_temp2),
   .valid_o           (valid_o),
   .data_out          (data_o_stree),
   .clear             (clear_stree),
   .ready_o           (ready_o_stree),
   .valid_i           (valid_i_stree),
   .rotate_seed_lambda(rotate_seed_lambda),
   .rotate_salt       (rotate_salt_s_tree),
   .shift_tmp1        (shift_tmp1),
   .shift_tmp2        (shift_tmp2),
   .finished_tree     (finished_tree),
   .write_seed        (write_seed),
   .initial_writes    (initial_writes)
);

read_process_variables cmt_mem(
    .clk     (clk),
    .rst     (rst),
    .index   (index_next_seed|index_chall_2),
    .req_seed(req_seed_next),
    .req_cmt0(req_cmt0_chall_2),
    .req_cmt1(0),
    .req_v   (req_v_chall_2),
    .req_y   (req_y_chall_2),
    .raddress(r_address_cmt),
    .req     (rq_tmp)
);

read_process_variables cmt_mem_b(
    .clk     (clk),
    .rst     (rst),
    .index   (index_chall_2),
    .req_seed(req_seed_chall_2),
    .req_cmt0(0),
    .req_cmt1(req_cmt1_chall_2),
    .req_v   (0),
    .req_y   (0),
    .raddress(r_address_cmt_b),
    .req     (rq_tmp_b)
);

additional_registers reg_storage(
    .clk      (clk),
    .rst      (rst),
    .port_1   (data_o),
    .port_2   (data_out_cmt_mem),
    .port_3   (data_o),
    .shift_1  (initial_writes||shift_spare_ra),
    .shift_2  ((request_next_seed&&response_cmt)),
    .shift_3  (shift_spare_rb),
    .rotate_a (rotate_a),
    .rotate_b (0),
    .output_a (output_a),
    .output_b (output_b)
    );

double_vector_sampler dvs(
    .clk            (clk),
    .rst            (rst),
    .data_in_module (data_o),
    .valid_in_module(valid_o_inst_sampler&&valid_o),
    .ready_o_system (ready_o_system_inst_gen),
    .ready_o        (ready_o_dvs),
    .finished_e     (),
    .write_out_e    (write_out_e_inst),
    .place_memory_e (place_memory_e_inst),
    .finished_u     (finished_u_inst),
    .write_out_u    (write_out_u_inst),
    .place_memory_u (place_memory_u_inst)
    );
    
generate_instances  gen_inst(
    .clk                 (clk),//
    .rst                 (rst),//
    .finished_tree       (finished_tree),//
    .seed_lambda         (output_a),//
    .salt                (data_salt),//
    .end_pulse_cmp       (0),
    .data_out_cmp        (0),
//    .valid_out_cmp       (0),
    .valid_o             (valid_o),
    .end_instance        (finished_u_inst),//
    .flag                (flag),
    .data_out_b          (data_out_b),
    .clear_b             (clear_b),
    .ready_o_b           (ready_o_b),
    .valid_i_b           (valid_i_b),
    .write_cmt0_b        (write_cmt0_b),
    .lower_flag          (lower_flag),
//    .clear_counter       (clear_counter),
    .valid_o_select      (select_gen_inst),//
    .data_out            (data_o_inst_gen),//
    .clear               (clear_inst_gen),//
    .ready_o             (ready_o_cmt),
    .ready_o_system      (ready_o_system_inst_gen),//
    .valid_i             (valid_i_inst_gen),//
    .rotate_seed_lambda  (rotate_a),//
    .rotate_salt         (rotate_salt_inst_sam),//
    .valid_o_inst_sampler(valid_o_inst_sampler),
    .write_cmt0          (),
    .write_cmt1          (write_cmt1),
    .request_next_seed   (request_next_seed),
    .relocate_salt       (relocate_salt),
    .req_sed_pulse       (req_sed_pulse),
    .fin_gen_inst        (fin_gen_inst)
    );
    
cmt_0_control gen_cmt_0(
    .clk           (clk),
    .rst           (rst),
    .flag          (flag),
    .ready_1a      (ready_1a),
    .ready_2a      (ready_2a),
    .ready_1b      (ready_1b),
    .ready_2b      (ready_2b),
    .comp_data_1a  (comp_data_1a),//
    .comp_data_2a  (comp_data_2a),//
    .comp_data_1b  (comp_data_1b),//
    .comp_data_2b  (comp_data_2b),//
    .valid_o       (valid_o),
    
    .req_seed_pulse(req_sed_pulse),
    
    .clear_1a      (clear_1a),
    .clear_2a      (clear_2a),
    .clear_1b      (clear_1b),
    .clear_2b      (clear_2b),
    
    .access_1a     (access_1a),
    .access_2a     (access_2a),
    .access_1b     (access_1b),
    .access_2b     (access_2b),
    
    .data_out_b    (data_out_b),//
    .clear_b       (clear_b),
    .ready_o_b     (ready_o_b),
    .valid_i_b     (valid_i_b),
    .write_cmt0_b  (write_cmt0_b)
    );
    
keep_track_matrix_operations matrix_op_flag(
    .clk          (clk),
    .rst          (rst),
    .ended_matrix ((clear_1a||clear_2a)||(clear_1b||clear_2b)),
    .lower_flag   (lower_flag),
//    .clear_counter(clear_counter),
    .flag         (flag)
    );
    
read_seeds   next_seed(
    .clk            (clk),
    .rst            (rst),
    .finished_tree  (finished_tree),
    .get_other_seeds(req_sed_pulse),
    .index          (index_next_seed),
    .req_seed       (req_seed_next)
    );
    
read_cmt_unit read_comitments(
    .clk               (clk),
    .rst               (rst),
    .select_branch_cmt0(select_branch_cmt0),//[1:0]
    .req_cmt_0         (req_cmt_0),
    .req_cmt_1         (req_cmt_1),
    .raddress          (raddress_read_cmt),//[14:0]
    .req               (req_read_cmt)
    );
    
input_flow_ctrl input_digest(
    .clk        (clk),
    .rst        (rst),
    .value      (data_out_cmt_mem),//w
    .response   (response_cmt),
    .dd_value   (data_out_cmt_mem_del),//w
    .dd_response(response_cmt_del),
    .resp_sense (rsp_sense)
    );
    
dig_cmt0_to_chall_1  message_processing(
    .clk               (clk),
    .rst               (rst),
    .init              (restart_chall_second),
    .fin_gen_inst      (fin_gen_inst),
    
    .valid_o           (valid_o),
    .data_o            (data_o), //w
    
    .message_in        (shift_message),
    .message           (message), //w
    
    .rsp_sense         (rsp_sense),  
    .rsp               (response_cmt_del),
    .data_memory       (data_out_cmt_mem_del), //w
    
    .data_out_c        (data_out_c), //w
    .clear_c           (clear_c),
    .ready_o_c         (ready_o_c),
    .valid_i_c         (valid_i_c),
    
    .occupied          (occ_mess), 
    .lower_occ         (lower_occ), 
    .raise_occ         (raise_occ),
    
    .select_branch_cmt0(select_branch_cmt0), //2
    .req_cmt_0         (req_cmt_0),
    .req_cmt_1         (req_cmt_1),
    
    .shift_spare_ra    (shift_spare_ra),
    .shift_spare_rb    (shift_spare_rb),
    .output_a          (output_a), //w
    .output_b          (output_b), //w
    
    .rotate_tmp1       (rotate_tmp1_c),
    .rotate_tmp2       (rotate_tmp2_c),
    .shift_tmp1        (shift_tmp1_c),
    .shift_tmp2        (shift_tmp2_c),
    .output_tmp1       (data_temp1), //w
    .output_tmp2       (data_temp2),  //w
    
    .write_dig_cmt     (write_dig_cmt),
    .rotate_salt_c     (rotate_salt_c),
    .salt              (data_salt),
    
    .valid_o_en        (valid_o_en),
    .ready_o_en        (ready_o_en),
    .fin_chall         (fin_chall),
    
    .next_op_c         (),
    
    .data_out_d    (data_out_d),//-->
    .clear_d       (clear_d),//-->
    .ready_o_d     (ready_o_d),//-->
    .valid_i_d     (valid_i_d)
    );
    
first_challenge_generator  ch1_gen(
    .clk            (clk),
    .rst            (rst),
    .valid_o        (valid_o&&valid_o_en),
    .data_in        (data_o),
    .finish_op      (finish_op_dpg),
    .ready_o_system (ready_o_en),
    .ready_o        (ready_o_ch1),
    .finish         (fin_chall),
    .start_op       (start_op_dpg),
    .data_out       (data_out_first_chall)
    );
    
//delayed_pulse_gen dpg(
//   .clk      (clk),
//   .rst      (rst),
//   .start_op (start_op_dpg),
//   .finish_op(finish_op_dpg)
//);
    
////////////////////////////////////////////e_prime_memory_ctrl
vector_memory_control#(
    .INDX(0),
    .DATA_WIDTH(Z_BIT_WIDTH)
)e_bar_prime_memory_control_1a(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_e_inst&&(select_gen_inst == 0)),
    .req        (request_vectors),
    .data_in    (place_memory_e_inst),
    .del_address(del_address_e_bar_prime_1a),
    .del_write  (del_write_e_bar_prime_1a),
    .del_data_in(del_data_in_e_bar_prime_1a),
    .rsp        ()
    );

vector_memory_control#(
    .INDX(1),
    .DATA_WIDTH(Z_BIT_WIDTH)
)e_bar_prime_memory_control_2a(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_e_inst&&(select_gen_inst == 1)),
    .req        (request_vectors),
    .data_in    (place_memory_e_inst),
    .del_address(del_address_e_bar_prime_2a),
    .del_write  (del_write_e_bar_prime_2a),
    .del_data_in(del_data_in_e_bar_prime_2a),
    .rsp        ()
    );

vector_memory_control#(
    .INDX(2),
    .DATA_WIDTH(Z_BIT_WIDTH)
)e_bar_prime_memory_control_1b(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_e_inst&&(select_gen_inst == 2)),
    .req        (request_vectors),
    .data_in    (place_memory_e_inst),
    .del_address(del_address_e_bar_prime_1b),
    .del_write  (del_write_e_bar_prime_1b),
    .del_data_in(del_data_in_e_bar_prime_1b),
    .rsp        ()
    );

vector_memory_control#(
    .INDX(3),
    .DATA_WIDTH(Z_BIT_WIDTH)
)e_bar_prime_memory_control_2b(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_e_inst&&(select_gen_inst == 3)),
    .req        (request_vectors),
    .data_in    (place_memory_e_inst),
    .del_address(del_address_e_bar_prime_2b),
    .del_write  (del_write_e_bar_prime_2b),
    .del_data_in(del_data_in_e_bar_prime_2b),
    .rsp        ()
    );

////////////////////////////////////////////e_prime_main_memory
e_bar_memory_select e_prime_memory_1a(
    .clka (clk),
    .addra(del_address_e_bar_prime_1a),
    .dina (del_data_in_e_bar_prime_1a),
    .wea  (del_write_e_bar_prime_1a),
    .douta(vector_e_bar_prime_1a)
    );
    
e_bar_memory_select e_prime_memory_2a(
    .clka (clk),
    .addra(del_address_e_bar_prime_2a),
    .dina (del_data_in_e_bar_prime_2a),
    .wea  (del_write_e_bar_prime_2a),
    .douta(vector_e_bar_prime_2a)
    );
    
e_bar_memory_select e_prime_memory_1b(
    .clka (clk),
    .addra(del_address_e_bar_prime_1b),
    .dina (del_data_in_e_bar_prime_1b),
    .wea  (del_write_e_bar_prime_1b),
    .douta(vector_e_bar_prime_1b)
    );
   
e_bar_memory_select e_prime_memory_2b(
    .clka (clk),
    .addra(del_address_e_bar_prime_2b),
    .dina (del_data_in_e_bar_prime_2b),
    .wea  (del_write_e_bar_prime_2b),
    .douta(vector_e_bar_prime_2b)
    );  

////////////////////////////////////////////u_prime_memory_ctrl
vector_memory_control#(
    .INDX(0),
    .DATA_WIDTH(P_BIT_WIDTH)
)u_prime_memory_control_1a(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_u_inst&&(select_gen_inst == 0)),
    .req        (request_vectors),
    .data_in    (place_memory_u_inst),
    .del_address(del_address_u_prime_1a),
    .del_write  (del_write_u_prime_1a),
    .del_data_in(del_data_in_u_prime_1a),
    .rsp        (response_1a_mem)
    );

vector_memory_control#(
    .INDX(1),
    .DATA_WIDTH(P_BIT_WIDTH)
)u_prime_memory_control_2a(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_u_inst&&(select_gen_inst == 1)),
    .req        (request_vectors),
    .data_in    (place_memory_u_inst),
    .del_address(del_address_u_prime_2a),
    .del_write  (del_write_u_prime_2a),
    .del_data_in(del_data_in_u_prime_2a),
    .rsp        (response_2a_mem)
    );

vector_memory_control#(
    .INDX(2),
    .DATA_WIDTH(P_BIT_WIDTH)
)u_prime_memory_control_1b(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_u_inst&&(select_gen_inst == 2)),
    .req        (request_vectors),
    .data_in    (place_memory_u_inst),
    .del_address(del_address_u_prime_1b),
    .del_write  (del_write_u_prime_1b),
    .del_data_in(del_data_in_u_prime_1b),
    .rsp        (response_1b_mem)
    );

vector_memory_control#(
    .INDX(3),
    .DATA_WIDTH(P_BIT_WIDTH)
)u_prime_memory_control_2b(
    .clk        (clk),
    .rst        (rst),
    .write      (write_out_u_inst&&(select_gen_inst == 3)),
    .req        (request_vectors),
    .data_in    (place_memory_u_inst),
    .del_address(del_address_u_prime_2b),
    .del_write  (del_write_u_prime_2b),
    .del_data_in(del_data_in_u_prime_2b),
    .rsp        (response_2b_mem)
    );

////////////////////////////////////////////u_prime_main_memory
uprime_memory_select u_prime_memory_1a(
    .clka (clk),
    .addra(del_address_u_prime_1a),
    .dina (del_data_in_u_prime_1a),
    .wea  (del_write_u_prime_1a),
    .douta(vector_u_prime_1a)
    );
    
uprime_memory_select u_prime_memory_2a(
    .clka (clk),
    .addra(del_address_u_prime_2a),
    .dina (del_data_in_u_prime_2a),
    .wea  (del_write_u_prime_2a),
    .douta(vector_u_prime_2a)
    );
    
uprime_memory_select u_prime_memory_1b(
    .clka (clk),
    .addra(del_address_u_prime_1b),
    .dina (del_data_in_u_prime_1b),
    .wea  (del_write_u_prime_1b),
    .douta(vector_u_prime_1b)
    );
    
uprime_memory_select u_prime_memory_2b(
    .clka (clk),
    .addra(del_address_u_prime_2b),
    .dina (del_data_in_u_prime_2b),
    .wea  (del_write_u_prime_2b),
    .douta(vector_u_prime_2b)
    );
///////////////////////////////////////////////////////////////

compress_mux  comp_mux(
    .clk            (clk),
    .rst            (rst),
    .response_vector(response_1a_mem),
    .y1             (comp_y1),//
    .y2             (comp_y2),//
    .y3             (comp_y3),//
    .y4             (comp_y4),//
    .dig_chall_1    (data_temp2),//
    .start_op       (start_op_dpg),
    
    .finish_op       (finish_op_dpg),
    .write_y_resp    (write_y_resp),
    .y2mem           (y2mem),//
    .request_vectors (request_vectors),
    .push_y1         (push_y1),
    .push_y2         (push_y2),
    .push_y3         (push_y3),
    .push_y4         (push_y4),
    .push_dig_chall_1(push_dig_chall_1),
    .shift_in        (shift_in_comp_mux),
    .bytes           (bytes_comp_mux),//
    .data_in         (data_in_comp_mux),//
    .flush           (flush_comp_mux)
    );

comp_unit compress_yt(
    .clk      (clk),
    .reset    (rst),
    .shift_in (shift_in_comp_mux),
    .bytes    (bytes_comp_mux),
    .data_in  (data_in_comp_mux),
    .flush    (flush_comp_mux),
    .data_out (data_in_yt_comp),     //
    .valid_out(write_yt_comp)      //
    );
    
read_y_compressed read_comp_yt( 
    .clk       (clk),
    .rst       (rst),
    .req_pulse (req_pulse_yt),
    .r_address (r_address_yt_comp),//
    .req       (req_yt_comp) //
    );
    
comp_y_ctrl memory_comp_y_ctrl(
    .clk      (clk),
    .rst      (rst),
    .write    (write_yt_comp),
    .data_in  (data_in_yt_comp),
    .req      (req_yt_comp),
    .r_address(r_address_yt_comp),
    .addra    (addra_yt_comp),//
    .dina     (dina_yt_comp),//
    .wea      (wea_yt_comp),//
    .rsp      (rsp_yt_comp)//
    );
    
y_comp_mem_select memory_comp_y(
    .clka  (clk),
    .addra (addra_yt_comp),
    .dina  (dina_yt_comp),
    .wea   (wea_yt_comp),
    .douta (douta_yt)
    );

input_flow_ctrl input_sense_ch2(
    .clk        (clk),
    .rst        (rst),
    .value      (douta_yt),//w
    .response   (rsp_yt_comp),
    
    .dd_value   (dd_value_ch2),//w
    .dd_response(dd_response_ch2),
    .resp_sense (resp_sense_ch2)
    );

gen_sec_chall_fsm control_ch2(
    .clk           (clk),
    .rst           (rst),
    .flush         (flush_comp_mux),
    
    .valid_o       (valid_o),
    .valid_o_active(valid_o_active_d),//-->
    .data_o        (0),
    
    .rotate_tmp_2  (rotate_tmp_2_d),//-->
    .shift_tmp_2   (shift_tmp_2_d),//-->
    .tmp_2_out     (data_temp2),
    
    .rsp_sense     (resp_sense_ch2),
    .rsp           (dd_response_ch2),
    .data_memory   (dd_value_ch2),
    
    .data_out_d    (data_out_d),//-->
    .clear_d       (clear_d),//-->
    .ready_o_d     (ready_o_d),//-->
    .valid_i_d     (valid_i_d),//-->
    
    .req_pulse_yt  (req_pulse_yt),
    .ready_o_system(ready_o_system_d),//-->
    .next_stage    (next_stage_chall_2),//--> build from here ////////////////////////////////////////////////////////////////////
    
    .fin_chall2    (fin_chall2)
    );

second_challenge_sampler sec_chall(
    .clk           (clk),
    .rst           (rst),
    .ready_o_system(ready_o_system_d),
    .valid_o       (valid_o_active_d&&valid_o),
    .data_o        (data_o),
    .increment     (increment_chall_second),
    .restart       (restart_chall_second),
    .challenge     (chall_second),//
    .clr           (fin_chall2),//
    .ready_o       (ready_o_sec_chall)//
    );

assemble_signature final_step(
    .clk         (clk),
    .rst         (rst),
    .next_stage  (next_stage_chall_2),
    .challenge   (chall_second),//0:0
    .response    (response_cmt),
    
    .select_write(select_write_chall_2),//1:0
    .index       (index_chall_2),//8:0
    .req_seed    (req_seed_chall_2),
    .req_cmt0    (req_cmt0_chall_2),
    .req_cmt1    (req_cmt1_chall_2),
    .req_v       (req_v_chall_2),
    .req_y       (req_y_chall_2),
    .increment   (increment_chall_second),
    .restart     (restart_chall_second)
    );

prepare_resp_yv   write_yv_comp(
    .clk           (clk),
    .rst           (rst),
    .data_in       (data_out_cmt_mem), //w
    .write_yv      (write_yv_signature),
    .restart_flush (restart_chall_second),/////get ready for next message & lower occupied
    .data_out      (written_response),//w
    .valid_out     (write_yv_valid)
    );
    
assign write_seed_signature = (rsp_sec && (select_write_chall_2 == 2'b01));
assign write_cmt0_signature = (response_cmt && (select_write_chall_2 == 2'b01));//////second write
assign write_cmt1_signature = (rsp_sec && (select_write_chall_2 == 2'b10));//////third_write
assign write_yv_signature   = (response_cmt && (select_write_chall_2 == 2'b10));/////fourth write

///////////////////////////////////////////////////////////////
assign write_sig = shift_salt|write_dig_cmt|shift_tmp_2_d|write_seed_signature;///////first_write
assign write_sig_group = {shift_salt,write_dig_cmt,shift_tmp_2_d,write_seed_signature};
assign occupied = occ_mess|occupied_reg;

always_comb begin
   signature = 0;
   case(write_sig_group)
      4'b1000: signature = salt;
      4'b0100: signature = data_o;
      4'b0010: signature = data_o;
      4'b0001: signature = data_out_sec;
   endcase
end
//////////////////////////

access_signature  signature_ctrl(
    .clk                 (clk),
    .rst                 (rst),
    .request             (request_signature),
    .write_sig           (write_sig),
    .write_cmt0_signature(write_cmt0_signature),
    .write_cmt1_signature(write_cmt1_signature),
    .write_yv_signature  (write_yv_valid),
    .signature           (signature),//w
    .data_out_sec        (data_out_sec),//w
    .data_out_cmt_mem    (data_out_cmt_mem),//w
    .written_response    (written_response),//w
    
    .write_to_signature_a(write_to_signature_a),
    .address_signature_a (address_signature_a),//14
    .data_in_signature_a (data_in_signature_a),//w
    .write_to_signature_b(write_to_signature_b),
    .address_signature_b (address_signature_b),//14
    .data_in_signature_b (data_in_signature_b),//w
    .response            (unreg_module_response)
    );

signature_memory_select  signature_mem_sel(
    .clka (clk),
    .addra(address_signature_a),//14
    .dina (data_in_signature_a),//w
    .wea  (write_to_signature_a),
    
    .douta(unreg_valid_signature_out),//w
    
    .clkb (clk),
    .addrb(address_signature_b),//14
    .dinb (data_in_signature_b),//w
    .web  (write_to_signature_b),
    
    .doutb()//w
    );
    
regn #(
    .WIDTH(w + 1)
)last_stage_delay(
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({unreg_module_response, unreg_valid_signature_out}),
    .data_o ({module_response,       valid_signature_out      })
);

//////////////////////////
endmodule