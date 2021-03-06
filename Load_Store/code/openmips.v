`include "defines.v"
`include "pc_reg.v"
`include "id.v"
`include "regfile.v"
`include "ex.v"
`include "wb.v"
module openmips(
    input wire          clk,
    input wire          rst,

    input wire[`RegBus]         rom_data_i,
    output wire[`RegBus]        rom_addr_o,
    output wire                 rom_ce_o,
	
	  //连接数据存储器data_ram
	input wire[`RegBus]           ram_data_i,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire[3:0]               ram_ce_o
);
//连接ID模块和EX模块
wire[`AluOpBus] id_aluop;
wire[`AluSelBus] id_alusel;
wire[`RegBus] id_reg1;
wire[`RegBus] id_reg2;
wire          id_wreg;
wire[`RegAddrBus] id_wd;
wire[`RegBus] link_address;	
wire[`RegBus] id_inst;

//连接ID模块和Regfile模块
wire reg1_read;
wire reg2_read;
wire[`RegBus] reg1_data;
wire[`RegBus] reg2_data;
wire[`RegAddrBus] reg1_addr;
wire[`RegAddrBus] reg2_addr;

//连接执行阶段与hilo模块的输出，即读取HI、LO寄存器
wire[`RegBus] 	hi;
wire[`RegBus]   lo;
//连接EX模块和MEM模块
wire ex_wreg;
wire[`RegAddrBus] ex_wd;
wire[`RegBus] ex_wdata;
wire[`RegBus] ex_hi_o;
wire[`RegBus] ex_lo_o;
wire ex_whilo_o;
wire[`AluOpBus] ex_aluop_o;
wire[`RegBus] ex_addr_o;
wire[`RegBus] ex_reg2_o;
//连接MEM模块和WB模块
wire mem_wreg_o;
wire[`RegAddrBus] mem_wd_o;
wire[`RegBus] mem_wdata_o;
wire[`RegBus] mem_hi_o;
wire[`RegBus] mem_lo_o;
wire mem_whilo_o;
//连接WB模块和Regfile模块
wire[`RegAddrBus] wb_wd;
wire wb_wreg;
wire[`RegBus] wb_wdata;
//连接WB模块和hilo_reg模块
wire[`RegBus] wb_hi;
wire[`RegBus] wb_lo;
wire wb_whilo;

wire id_branch_flag_o;
wire[`RegBus] branch_target_address;
//pc_reg real
pc_reg pc_reg0(
    .clk(clk),  .rst(rst),  .pc(rom_addr_o),    .ce(rom_ce_o),
	.branch_flag_i(id_branch_flag_o),
	.branch_target_address_i(branch_target_address)
);
//ID real
id id0(
    .rst(rst),  
    .pc_i(rom_addr_o), 
    .inst_i(rom_data_i),
    //来自Regfile模块的输入
    .reg1_data_i(reg1_data),    .reg2_data_i(reg2_data),
    //送到Regfile模块的信息
    .reg1_read_o(reg1_read),    .reg2_read_o(reg2_read),
    .reg1_addr_o(reg1_addr),    .reg2_addr_o(reg2_addr),
    //送到EX模块的信息
    .aluop_o(id_aluop),   .alusel_o(id_alusel),
    .reg1_o(id_reg1),     .reg2_o(id_reg2),
    .wd_o(id_wd),         .wreg_o(id_wreg),
	.inst_o(id_inst),
	
	.branch_flag_o(id_branch_flag_o),
	.branch_target_address_o(branch_target_address),       
	.link_addr_o(link_address)
);
//Regfile real
regfile regfile1(
    .clk(clk),
    .rst(rst),
    //从WB模块传来信息
    .we(wb_wreg), .waddr(wb_wd),
    .wdata(wb_wdata),
    //ID模块传来的信息
    .re1(reg1_read),    .raddr1(reg1_addr), 
    .rdata1(reg1_data),
    .re2(reg2_read),    .raddr2(reg2_addr),
    .rdata2(reg2_data)
);
//EX real
ex ex0(
    .rst(rst),
    //从ID模块传来的信息
    .aluop_i(id_aluop),   .alusel_i(id_alusel),
    .reg1_i(id_reg1),     .reg2_i(id_reg2),
    .wd_i(id_wd),         .wreg_i(id_wreg),
	.inst_i(id_inst),
    //从hilo_reg模块传来的信息
    .hi_i(hi),
	.lo_i(lo),
    //送到MEM模块的信息
    .wd_o(ex_wd),         .wreg_o(ex_wreg),
    .wdata_o(ex_wdata),
    .hi_o(ex_hi_o),
	.lo_o(ex_lo_o),
	.whilo_o(ex_whilo_o),
	
	.aluop_o(ex_aluop_o),
	.mem_addr_o(ex_addr_o),
	.reg2_o(ex_reg2_o),
	
	.link_address_i(link_address)

);
//MEM real
mem mem0(
	.rst(rst),
	
	//来自EX模块的信息	
	.wd_i(ex_wd),
	.wreg_i(ex_wreg),
	.wdata_i(ex_wdata),
	.hi_i(ex_hi_o),
	.lo_i(ex_lo_o),
	.whilo_i(ex_whilo_o),		

  	.aluop_i(ex_aluop_o),
	.mem_addr_i(ex_addr_o),
	.reg2_i(ex_reg2_o),
	
	//来自memory的信息
	.mem_data_i(ram_data_i),
	  
	//送到MEM/WB模块的信息
	.wd_o(mem_wd_o),
	.wreg_o(mem_wreg_o),
	.wdata_o(mem_wdata_o),
	.hi_o(mem_hi_o),
	.lo_o(mem_lo_o),
	.whilo_o(mem_whilo_o),
		
	//送到memory的信息
	.mem_addr_o(ram_addr_o),
	.mem_we_o(ram_we_o),
	.mem_sel_o(ram_sel_o),
	.mem_data_o(ram_data_o),
	.mem_ce_o(ram_ce_o)		
	);
//WB real
wb wb0(
    .rst(rst),
    .mem_wd(mem_wd_o),         .mem_wreg(mem_wreg_o),
    .mem_wdata(mem_wdata_o),
    .mem_hi(mem_hi_o),
	.mem_lo(mem_lo_o),
	.mem_whilo(mem_whilo_o),
    .wb_wd(wb_wd),  .wb_wreg(wb_wreg),
    .wb_wdata(wb_wdata),
    .wb_hi(wb_hi),
	.wb_lo(wb_lo),
	.wb_whilo(wb_whilo)
);
hilo_reg hilo_reg0(
	.clk(clk),
	.rst(rst),
	
	//写端口
	.we(wb_whilo),
	.hi_i(wb_hi),
	.lo_i(wb_lo),
	
	//读端口1
	.hi_o(hi),
	.lo_o(lo)	
	);
        
endmodule
