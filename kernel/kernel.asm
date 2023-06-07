
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	d8010113          	addi	sp,sp,-640 # 80009d80 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	bee70713          	addi	a4,a4,-1042 # 80009c40 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	c8c78793          	addi	a5,a5,-884 # 80006cf0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdb7497>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	01278793          	addi	a5,a5,18 # 800010c0 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	052080e7          	jalr	82(ra) # 8000317e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	bf450513          	addi	a0,a0,-1036 # 80011d80 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	c82080e7          	jalr	-894(ra) # 80000e16 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	be448493          	addi	s1,s1,-1052 # 80011d80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	c7290913          	addi	s2,s2,-910 # 80011e18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	c3e080e7          	jalr	-962(ra) # 80001e02 <myproc>
    800001cc:	00003097          	auipc	ra,0x3
    800001d0:	f2a080e7          	jalr	-214(ra) # 800030f6 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00003097          	auipc	ra,0x3
    800001de:	96a080e7          	jalr	-1686(ra) # 80002b44 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00003097          	auipc	ra,0x3
    8000021a:	f12080e7          	jalr	-238(ra) # 80003128 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00012517          	auipc	a0,0x12
    8000022e:	b5650513          	addi	a0,a0,-1194 # 80011d80 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	c98080e7          	jalr	-872(ra) # 80000eca <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00012517          	auipc	a0,0x12
    80000244:	b4050513          	addi	a0,a0,-1216 # 80011d80 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	c82080e7          	jalr	-894(ra) # 80000eca <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00012717          	auipc	a4,0x12
    8000027c:	baf72023          	sw	a5,-1120(a4) # 80011e18 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00012517          	auipc	a0,0x12
    800002d6:	aae50513          	addi	a0,a0,-1362 # 80011d80 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	b3c080e7          	jalr	-1220(ra) # 80000e16 <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00003097          	auipc	ra,0x3
    800002fc:	edc080e7          	jalr	-292(ra) # 800031d4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00012517          	auipc	a0,0x12
    80000304:	a8050513          	addi	a0,a0,-1408 # 80011d80 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	bc2080e7          	jalr	-1086(ra) # 80000eca <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00012717          	auipc	a4,0x12
    80000328:	a5c70713          	addi	a4,a4,-1444 # 80011d80 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	a3278793          	addi	a5,a5,-1486 # 80011d80 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00012797          	auipc	a5,0x12
    80000380:	a9c7a783          	lw	a5,-1380(a5) # 80011e18 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00012717          	auipc	a4,0x12
    80000394:	9f070713          	addi	a4,a4,-1552 # 80011d80 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00012497          	auipc	s1,0x12
    800003a4:	9e048493          	addi	s1,s1,-1568 # 80011d80 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00012717          	auipc	a4,0x12
    800003e0:	9a470713          	addi	a4,a4,-1628 # 80011d80 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00012717          	auipc	a4,0x12
    800003f6:	a2f72723          	sw	a5,-1490(a4) # 80011e20 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00012797          	auipc	a5,0x12
    8000041c:	96878793          	addi	a5,a5,-1688 # 80011d80 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00012797          	auipc	a5,0x12
    80000440:	9ec7a023          	sw	a2,-1568(a5) # 80011e1c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00012517          	auipc	a0,0x12
    80000448:	9d450513          	addi	a0,a0,-1580 # 80011e18 <cons+0x98>
    8000044c:	00003097          	auipc	ra,0x3
    80000450:	9d4080e7          	jalr	-1580(ra) # 80002e20 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00009597          	auipc	a1,0x9
    80000462:	bb258593          	addi	a1,a1,-1102 # 80009010 <etext+0x10>
    80000466:	00012517          	auipc	a0,0x12
    8000046a:	91a50513          	addi	a0,a0,-1766 # 80011d80 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	918080e7          	jalr	-1768(ra) # 80000d86 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00246797          	auipc	a5,0x246
    80000482:	d5278793          	addi	a5,a5,-686 # 802461d0 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00009617          	auipc	a2,0x9
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80009040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00012797          	auipc	a5,0x12
    80000554:	8e07a823          	sw	zero,-1808(a5) # 80011e40 <pr+0x18>
  printf("panic: ");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80009018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00009517          	auipc	a0,0x9
    80000576:	d9650513          	addi	a0,a0,-618 # 80009308 <digits+0x2c8>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00009717          	auipc	a4,0x9
    80000588:	66f72e23          	sw	a5,1660(a4) # 80009c00 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00012d97          	auipc	s11,0x12
    800005c4:	880dad83          	lw	s11,-1920(s11) # 80011e40 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00009b97          	auipc	s7,0x9
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80009040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00012517          	auipc	a0,0x12
    80000602:	82a50513          	addi	a0,a0,-2006 # 80011e28 <pr>
    80000606:	00001097          	auipc	ra,0x1
    8000060a:	810080e7          	jalr	-2032(ra) # 80000e16 <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00009517          	auipc	a0,0x9
    80000614:	a1850513          	addi	a0,a0,-1512 # 80009028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00009917          	auipc	s2,0x9
    80000714:	91090913          	addi	s2,s2,-1776 # 80009020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	6c650513          	addi	a0,a0,1734 # 80011e28 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	760080e7          	jalr	1888(ra) # 80000eca <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00011497          	auipc	s1,0x11
    80000782:	6aa48493          	addi	s1,s1,1706 # 80011e28 <pr>
    80000786:	00009597          	auipc	a1,0x9
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80009038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	5f6080e7          	jalr	1526(ra) # 80000d86 <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00009597          	auipc	a1,0x9
    800007da:	88258593          	addi	a1,a1,-1918 # 80009058 <digits+0x18>
    800007de:	00011517          	auipc	a0,0x11
    800007e2:	66a50513          	addi	a0,a0,1642 # 80011e48 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	5a0080e7          	jalr	1440(ra) # 80000d86 <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	5c8080e7          	jalr	1480(ra) # 80000dca <push_off>

  if(panicked){
    8000080a:	00009797          	auipc	a5,0x9
    8000080e:	3f67a783          	lw	a5,1014(a5) # 80009c00 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	636080e7          	jalr	1590(ra) # 80000e6a <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00009717          	auipc	a4,0x9
    8000084a:	3c273703          	ld	a4,962(a4) # 80009c08 <uart_tx_r>
    8000084e:	00009797          	auipc	a5,0x9
    80000852:	3c27b783          	ld	a5,962(a5) # 80009c10 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00011a17          	auipc	s4,0x11
    80000874:	5d8a0a13          	addi	s4,s4,1496 # 80011e48 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00009497          	auipc	s1,0x9
    8000087c:	39048493          	addi	s1,s1,912 # 80009c08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00009997          	auipc	s3,0x9
    80000884:	39098993          	addi	s3,s3,912 # 80009c10 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	57a080e7          	jalr	1402(ra) # 80002e20 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00011517          	auipc	a0,0x11
    800008e6:	56650513          	addi	a0,a0,1382 # 80011e48 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	52c080e7          	jalr	1324(ra) # 80000e16 <acquire>
  if(panicked){
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	30e7a783          	lw	a5,782(a5) # 80009c00 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00009797          	auipc	a5,0x9
    80000900:	3147b783          	ld	a5,788(a5) # 80009c10 <uart_tx_w>
    80000904:	00009717          	auipc	a4,0x9
    80000908:	30473703          	ld	a4,772(a4) # 80009c08 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	538a0a13          	addi	s4,s4,1336 # 80011e48 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	2f048493          	addi	s1,s1,752 # 80009c08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	2f090913          	addi	s2,s2,752 # 80009c10 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	214080e7          	jalr	532(ra) # 80002b44 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00011497          	auipc	s1,0x11
    8000094a:	50248493          	addi	s1,s1,1282 # 80011e48 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00009717          	auipc	a4,0x9
    8000095e:	2af73b23          	sd	a5,694(a4) # 80009c10 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	55e080e7          	jalr	1374(ra) # 80000eca <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00011497          	auipc	s1,0x11
    800009d4:	47848493          	addi	s1,s1,1144 # 80011e48 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	43c080e7          	jalr	1084(ra) # 80000e16 <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	4de080e7          	jalr	1246(ra) # 80000eca <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <initialize_page>:
  struct spinlock lock;
  int arr[PGROUNDUP(PHYSTOP) >> 12];
} pagex;

void initialize_page()
{
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e406                	sd	ra,8(sp)
    80000a02:	e022                	sd	s0,0(sp)
    80000a04:	0800                	addi	s0,sp,16
  initlock(&pagex.lock, "pagex");
    80000a06:	00008597          	auipc	a1,0x8
    80000a0a:	65a58593          	addi	a1,a1,1626 # 80009060 <digits+0x20>
    80000a0e:	00011517          	auipc	a0,0x11
    80000a12:	49250513          	addi	a0,a0,1170 # 80011ea0 <pagex>
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	370080e7          	jalr	880(ra) # 80000d86 <initlock>
  acquire(&pagex.lock);
    80000a1e:	00011517          	auipc	a0,0x11
    80000a22:	48250513          	addi	a0,a0,1154 # 80011ea0 <pagex>
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	3f0080e7          	jalr	1008(ra) # 80000e16 <acquire>
  uint64 val = PGROUNDUP(PHYSTOP) >> 12;
  for (int i = 0; i < val; i++)
    80000a2e:	00011797          	auipc	a5,0x11
    80000a32:	48a78793          	addi	a5,a5,1162 # 80011eb8 <pagex+0x18>
    80000a36:	00231717          	auipc	a4,0x231
    80000a3a:	48270713          	addi	a4,a4,1154 # 80231eb8 <pid_lock>
  {
    pagex.arr[i] = 0;
    80000a3e:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < val; i++)
    80000a42:	0791                	addi	a5,a5,4
    80000a44:	fee79de3          	bne	a5,a4,80000a3e <initialize_page+0x40>
  }
  release(&pagex.lock);
    80000a48:	00011517          	auipc	a0,0x11
    80000a4c:	45850513          	addi	a0,a0,1112 # 80011ea0 <pagex>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	47a080e7          	jalr	1146(ra) # 80000eca <release>
}
    80000a58:	60a2                	ld	ra,8(sp)
    80000a5a:	6402                	ld	s0,0(sp)
    80000a5c:	0141                	addi	sp,sp,16
    80000a5e:	8082                	ret

0000000080000a60 <extract_page>:

int extract_page(void *pa)
{
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	1000                	addi	s0,sp,32
    80000a6a:	84aa                	mv	s1,a0
  acquire(&pagex.lock);
    80000a6c:	00011517          	auipc	a0,0x11
    80000a70:	43450513          	addi	a0,a0,1076 # 80011ea0 <pagex>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	3a2080e7          	jalr	930(ra) # 80000e16 <acquire>
  int res = pagex.arr[(uint64)pa >> 12];
    80000a7c:	80b1                	srli	s1,s1,0xc
    80000a7e:	0491                	addi	s1,s1,4
    80000a80:	048a                	slli	s1,s1,0x2
    80000a82:	00011797          	auipc	a5,0x11
    80000a86:	41e78793          	addi	a5,a5,1054 # 80011ea0 <pagex>
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	4484                	lw	s1,8(s1)
  if (pagex.arr[(uint64)pa >> 12] >= 0)
    80000a8e:	0204c063          	bltz	s1,80000aae <extract_page+0x4e>
  {
    release(&pagex.lock);
    80000a92:	00011517          	auipc	a0,0x11
    80000a96:	40e50513          	addi	a0,a0,1038 # 80011ea0 <pagex>
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	430080e7          	jalr	1072(ra) # 80000eca <release>
  }
  else
  {
    panic("extract_page");
  }
}
    80000aa2:	8526                	mv	a0,s1
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6105                	addi	sp,sp,32
    80000aac:	8082                	ret
    panic("extract_page");
    80000aae:	00008517          	auipc	a0,0x8
    80000ab2:	5ba50513          	addi	a0,a0,1466 # 80009068 <digits+0x28>
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	a8e080e7          	jalr	-1394(ra) # 80000544 <panic>

0000000080000abe <increment_page>:

void increment_page(void *pa)
{
    80000abe:	1101                	addi	sp,sp,-32
    80000ac0:	ec06                	sd	ra,24(sp)
    80000ac2:	e822                	sd	s0,16(sp)
    80000ac4:	e426                	sd	s1,8(sp)
    80000ac6:	1000                	addi	s0,sp,32
    80000ac8:	84aa                	mv	s1,a0
  acquire(&pagex.lock);
    80000aca:	00011517          	auipc	a0,0x11
    80000ace:	3d650513          	addi	a0,a0,982 # 80011ea0 <pagex>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	344080e7          	jalr	836(ra) # 80000e16 <acquire>
  uint64 res = (uint64)pa >> 12;
    80000ada:	00c4d793          	srli	a5,s1,0xc
  if (pagex.arr[res] >= 0)
    80000ade:	00478713          	addi	a4,a5,4
    80000ae2:	00271693          	slli	a3,a4,0x2
    80000ae6:	00011717          	auipc	a4,0x11
    80000aea:	3ba70713          	addi	a4,a4,954 # 80011ea0 <pagex>
    80000aee:	9736                	add	a4,a4,a3
    80000af0:	4718                	lw	a4,8(a4)
    80000af2:	02074363          	bltz	a4,80000b18 <increment_page+0x5a>
  {
    pagex.arr[res] += 1;
    80000af6:	00011517          	auipc	a0,0x11
    80000afa:	3aa50513          	addi	a0,a0,938 # 80011ea0 <pagex>
    80000afe:	00d507b3          	add	a5,a0,a3
    80000b02:	2705                	addiw	a4,a4,1
    80000b04:	c798                	sw	a4,8(a5)
    release(&pagex.lock);
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	3c4080e7          	jalr	964(ra) # 80000eca <release>
  else
  {
    panic("increment_page");
    return;
  }
}
    80000b0e:	60e2                	ld	ra,24(sp)
    80000b10:	6442                	ld	s0,16(sp)
    80000b12:	64a2                	ld	s1,8(sp)
    80000b14:	6105                	addi	sp,sp,32
    80000b16:	8082                	ret
    panic("increment_page");
    80000b18:	00008517          	auipc	a0,0x8
    80000b1c:	56050513          	addi	a0,a0,1376 # 80009078 <digits+0x38>
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	a24080e7          	jalr	-1500(ra) # 80000544 <panic>

0000000080000b28 <decrement_page>:

void decrement_page(void *pa)
{
    80000b28:	1101                	addi	sp,sp,-32
    80000b2a:	ec06                	sd	ra,24(sp)
    80000b2c:	e822                	sd	s0,16(sp)
    80000b2e:	e426                	sd	s1,8(sp)
    80000b30:	1000                	addi	s0,sp,32
    80000b32:	84aa                	mv	s1,a0
  acquire(&pagex.lock);
    80000b34:	00011517          	auipc	a0,0x11
    80000b38:	36c50513          	addi	a0,a0,876 # 80011ea0 <pagex>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	2da080e7          	jalr	730(ra) # 80000e16 <acquire>
  uint64 res = (uint64)pa >> 12;
    80000b44:	00c4d793          	srli	a5,s1,0xc
  if (pagex.arr[res] > 0)
    80000b48:	00478713          	addi	a4,a5,4
    80000b4c:	00271693          	slli	a3,a4,0x2
    80000b50:	00011717          	auipc	a4,0x11
    80000b54:	35070713          	addi	a4,a4,848 # 80011ea0 <pagex>
    80000b58:	9736                	add	a4,a4,a3
    80000b5a:	4718                	lw	a4,8(a4)
    80000b5c:	02e05363          	blez	a4,80000b82 <decrement_page+0x5a>
  {
    pagex.arr[res] -= 1;
    80000b60:	00011517          	auipc	a0,0x11
    80000b64:	34050513          	addi	a0,a0,832 # 80011ea0 <pagex>
    80000b68:	00d507b3          	add	a5,a0,a3
    80000b6c:	377d                	addiw	a4,a4,-1
    80000b6e:	c798                	sw	a4,8(a5)
    release(&pagex.lock);
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	35a080e7          	jalr	858(ra) # 80000eca <release>
  else
  {
    panic("decrement_page");
    return;
  }
}
    80000b78:	60e2                	ld	ra,24(sp)
    80000b7a:	6442                	ld	s0,16(sp)
    80000b7c:	64a2                	ld	s1,8(sp)
    80000b7e:	6105                	addi	sp,sp,32
    80000b80:	8082                	ret
    panic("decrement_page");
    80000b82:	00008517          	auipc	a0,0x8
    80000b86:	50650513          	addi	a0,a0,1286 # 80009088 <digits+0x48>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	9ba080e7          	jalr	-1606(ra) # 80000544 <panic>

0000000080000b92 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000b92:	1101                	addi	sp,sp,-32
    80000b94:	ec06                	sd	ra,24(sp)
    80000b96:	e822                	sd	s0,16(sp)
    80000b98:	e426                	sd	s1,8(sp)
    80000b9a:	e04a                	sd	s2,0(sp)
    80000b9c:	1000                	addi	s0,sp,32
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000b9e:	03451793          	slli	a5,a0,0x34
    80000ba2:	e7dd                	bnez	a5,80000c50 <kfree+0xbe>
    80000ba4:	84aa                	mv	s1,a0
    80000ba6:	00246797          	auipc	a5,0x246
    80000baa:	7c278793          	addi	a5,a5,1986 # 80247368 <end>
    80000bae:	0af56163          	bltu	a0,a5,80000c50 <kfree+0xbe>
    80000bb2:	47c5                	li	a5,17
    80000bb4:	07ee                	slli	a5,a5,0x1b
    80000bb6:	08f57d63          	bgeu	a0,a5,80000c50 <kfree+0xbe>
    panic("kfree");
  acquire(&pagex.lock);
    80000bba:	00011517          	auipc	a0,0x11
    80000bbe:	2e650513          	addi	a0,a0,742 # 80011ea0 <pagex>
    80000bc2:	00000097          	auipc	ra,0x0
    80000bc6:	254080e7          	jalr	596(ra) # 80000e16 <acquire>
  if (pagex.arr[(uint64)pa >> 12] <= 0)
    80000bca:	00c4d793          	srli	a5,s1,0xc
    80000bce:	00478713          	addi	a4,a5,4
    80000bd2:	00271693          	slli	a3,a4,0x2
    80000bd6:	00011717          	auipc	a4,0x11
    80000bda:	2ca70713          	addi	a4,a4,714 # 80011ea0 <pagex>
    80000bde:	9736                	add	a4,a4,a3
    80000be0:	4718                	lw	a4,8(a4)
    80000be2:	06e05f63          	blez	a4,80000c60 <kfree+0xce>
  {
    panic("decrement_page");
  }
  pagex.arr[(uint64)pa >> 12] = pagex.arr[(uint64)pa >> 12] - 1;
    80000be6:	377d                	addiw	a4,a4,-1
    80000be8:	0007061b          	sext.w	a2,a4
    80000bec:	0791                	addi	a5,a5,4
    80000bee:	078a                	slli	a5,a5,0x2
    80000bf0:	00011697          	auipc	a3,0x11
    80000bf4:	2b068693          	addi	a3,a3,688 # 80011ea0 <pagex>
    80000bf8:	97b6                	add	a5,a5,a3
    80000bfa:	c798                	sw	a4,8(a5)
  if (pagex.arr[(uint64)pa >> 12] > 0)
    80000bfc:	06c04a63          	bgtz	a2,80000c70 <kfree+0xde>
    release(&pagex.lock);
    return;
  }
  else
  {
    release(&pagex.lock);
    80000c00:	00011517          	auipc	a0,0x11
    80000c04:	2a050513          	addi	a0,a0,672 # 80011ea0 <pagex>
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	2c2080e7          	jalr	706(ra) # 80000eca <release>

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000c10:	6605                	lui	a2,0x1
    80000c12:	4585                	li	a1,1
    80000c14:	8526                	mv	a0,s1
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	2fc080e7          	jalr	764(ra) # 80000f12 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000c1e:	00011917          	auipc	s2,0x11
    80000c22:	26290913          	addi	s2,s2,610 # 80011e80 <kmem>
    80000c26:	854a                	mv	a0,s2
    80000c28:	00000097          	auipc	ra,0x0
    80000c2c:	1ee080e7          	jalr	494(ra) # 80000e16 <acquire>
    r->next = kmem.freelist;
    80000c30:	01893783          	ld	a5,24(s2)
    80000c34:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000c36:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000c3a:	854a                	mv	a0,s2
    80000c3c:	00000097          	auipc	ra,0x0
    80000c40:	28e080e7          	jalr	654(ra) # 80000eca <release>
  }
  return;
}
    80000c44:	60e2                	ld	ra,24(sp)
    80000c46:	6442                	ld	s0,16(sp)
    80000c48:	64a2                	ld	s1,8(sp)
    80000c4a:	6902                	ld	s2,0(sp)
    80000c4c:	6105                	addi	sp,sp,32
    80000c4e:	8082                	ret
    panic("kfree");
    80000c50:	00008517          	auipc	a0,0x8
    80000c54:	44850513          	addi	a0,a0,1096 # 80009098 <digits+0x58>
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	8ec080e7          	jalr	-1812(ra) # 80000544 <panic>
    panic("decrement_page");
    80000c60:	00008517          	auipc	a0,0x8
    80000c64:	42850513          	addi	a0,a0,1064 # 80009088 <digits+0x48>
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	8dc080e7          	jalr	-1828(ra) # 80000544 <panic>
    release(&pagex.lock);
    80000c70:	8536                	mv	a0,a3
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	258080e7          	jalr	600(ra) # 80000eca <release>
    return;
    80000c7a:	b7e9                	j	80000c44 <kfree+0xb2>

0000000080000c7c <freerange>:
{
    80000c7c:	7139                	addi	sp,sp,-64
    80000c7e:	fc06                	sd	ra,56(sp)
    80000c80:	f822                	sd	s0,48(sp)
    80000c82:	f426                	sd	s1,40(sp)
    80000c84:	f04a                	sd	s2,32(sp)
    80000c86:	ec4e                	sd	s3,24(sp)
    80000c88:	e852                	sd	s4,16(sp)
    80000c8a:	e456                	sd	s5,8(sp)
    80000c8c:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000c8e:	6785                	lui	a5,0x1
    80000c90:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000c94:	94aa                	add	s1,s1,a0
    80000c96:	757d                	lui	a0,0xfffff
    80000c98:	8ce9                	and	s1,s1,a0
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000c9a:	94be                	add	s1,s1,a5
    80000c9c:	0295e463          	bltu	a1,s1,80000cc4 <freerange+0x48>
    80000ca0:	89ae                	mv	s3,a1
    80000ca2:	7afd                	lui	s5,0xfffff
    80000ca4:	6a05                	lui	s4,0x1
    80000ca6:	01548933          	add	s2,s1,s5
    increment_page(p);
    80000caa:	854a                	mv	a0,s2
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	e12080e7          	jalr	-494(ra) # 80000abe <increment_page>
    kfree(p);
    80000cb4:	854a                	mv	a0,s2
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	edc080e7          	jalr	-292(ra) # 80000b92 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000cbe:	94d2                	add	s1,s1,s4
    80000cc0:	fe99f3e3          	bgeu	s3,s1,80000ca6 <freerange+0x2a>
}
    80000cc4:	70e2                	ld	ra,56(sp)
    80000cc6:	7442                	ld	s0,48(sp)
    80000cc8:	74a2                	ld	s1,40(sp)
    80000cca:	7902                	ld	s2,32(sp)
    80000ccc:	69e2                	ld	s3,24(sp)
    80000cce:	6a42                	ld	s4,16(sp)
    80000cd0:	6aa2                	ld	s5,8(sp)
    80000cd2:	6121                	addi	sp,sp,64
    80000cd4:	8082                	ret

0000000080000cd6 <kinit>:
{
    80000cd6:	1141                	addi	sp,sp,-16
    80000cd8:	e406                	sd	ra,8(sp)
    80000cda:	e022                	sd	s0,0(sp)
    80000cdc:	0800                	addi	s0,sp,16
  initialize_page();
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	d20080e7          	jalr	-736(ra) # 800009fe <initialize_page>
  initlock(&kmem.lock, "kmem");
    80000ce6:	00008597          	auipc	a1,0x8
    80000cea:	3ba58593          	addi	a1,a1,954 # 800090a0 <digits+0x60>
    80000cee:	00011517          	auipc	a0,0x11
    80000cf2:	19250513          	addi	a0,a0,402 # 80011e80 <kmem>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	090080e7          	jalr	144(ra) # 80000d86 <initlock>
  freerange(end, (void *)PHYSTOP);
    80000cfe:	45c5                	li	a1,17
    80000d00:	05ee                	slli	a1,a1,0x1b
    80000d02:	00246517          	auipc	a0,0x246
    80000d06:	66650513          	addi	a0,a0,1638 # 80247368 <end>
    80000d0a:	00000097          	auipc	ra,0x0
    80000d0e:	f72080e7          	jalr	-142(ra) # 80000c7c <freerange>
}
    80000d12:	60a2                	ld	ra,8(sp)
    80000d14:	6402                	ld	s0,0(sp)
    80000d16:	0141                	addi	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000d1a:	1101                	addi	sp,sp,-32
    80000d1c:	ec06                	sd	ra,24(sp)
    80000d1e:	e822                	sd	s0,16(sp)
    80000d20:	e426                	sd	s1,8(sp)
    80000d22:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000d24:	00011497          	auipc	s1,0x11
    80000d28:	15c48493          	addi	s1,s1,348 # 80011e80 <kmem>
    80000d2c:	8526                	mv	a0,s1
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	0e8080e7          	jalr	232(ra) # 80000e16 <acquire>
  r = kmem.freelist;
    80000d36:	6c84                	ld	s1,24(s1)
  if (r)
    80000d38:	cc95                	beqz	s1,80000d74 <kalloc+0x5a>
    kmem.freelist = r->next;
    80000d3a:	609c                	ld	a5,0(s1)
    80000d3c:	00011517          	auipc	a0,0x11
    80000d40:	14450513          	addi	a0,a0,324 # 80011e80 <kmem>
    80000d44:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000d46:	00000097          	auipc	ra,0x0
    80000d4a:	184080e7          	jalr	388(ra) # 80000eca <release>

  if (r)
  {
    memset((char *)r, 100, PGSIZE); // fill with junk
    80000d4e:	6605                	lui	a2,0x1
    80000d50:	06400593          	li	a1,100
    80000d54:	8526                	mv	a0,s1
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	1bc080e7          	jalr	444(ra) # 80000f12 <memset>
    increment_page((void *)r);
    80000d5e:	8526                	mv	a0,s1
    80000d60:	00000097          	auipc	ra,0x0
    80000d64:	d5e080e7          	jalr	-674(ra) # 80000abe <increment_page>
  }
  return (void *)r;
}
    80000d68:	8526                	mv	a0,s1
    80000d6a:	60e2                	ld	ra,24(sp)
    80000d6c:	6442                	ld	s0,16(sp)
    80000d6e:	64a2                	ld	s1,8(sp)
    80000d70:	6105                	addi	sp,sp,32
    80000d72:	8082                	ret
  release(&kmem.lock);
    80000d74:	00011517          	auipc	a0,0x11
    80000d78:	10c50513          	addi	a0,a0,268 # 80011e80 <kmem>
    80000d7c:	00000097          	auipc	ra,0x0
    80000d80:	14e080e7          	jalr	334(ra) # 80000eca <release>
  if (r)
    80000d84:	b7d5                	j	80000d68 <kalloc+0x4e>

0000000080000d86 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e422                	sd	s0,8(sp)
    80000d8a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d8c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d8e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d92:	00053823          	sd	zero,16(a0)
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d9c:	411c                	lw	a5,0(a0)
    80000d9e:	e399                	bnez	a5,80000da4 <holding+0x8>
    80000da0:	4501                	li	a0,0
  return r;
}
    80000da2:	8082                	ret
{
    80000da4:	1101                	addi	sp,sp,-32
    80000da6:	ec06                	sd	ra,24(sp)
    80000da8:	e822                	sd	s0,16(sp)
    80000daa:	e426                	sd	s1,8(sp)
    80000dac:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000dae:	6904                	ld	s1,16(a0)
    80000db0:	00001097          	auipc	ra,0x1
    80000db4:	036080e7          	jalr	54(ra) # 80001de6 <mycpu>
    80000db8:	40a48533          	sub	a0,s1,a0
    80000dbc:	00153513          	seqz	a0,a0
}
    80000dc0:	60e2                	ld	ra,24(sp)
    80000dc2:	6442                	ld	s0,16(sp)
    80000dc4:	64a2                	ld	s1,8(sp)
    80000dc6:	6105                	addi	sp,sp,32
    80000dc8:	8082                	ret

0000000080000dca <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000dca:	1101                	addi	sp,sp,-32
    80000dcc:	ec06                	sd	ra,24(sp)
    80000dce:	e822                	sd	s0,16(sp)
    80000dd0:	e426                	sd	s1,8(sp)
    80000dd2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dd4:	100024f3          	csrr	s1,sstatus
    80000dd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ddc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dde:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000de2:	00001097          	auipc	ra,0x1
    80000de6:	004080e7          	jalr	4(ra) # 80001de6 <mycpu>
    80000dea:	5d3c                	lw	a5,120(a0)
    80000dec:	cf89                	beqz	a5,80000e06 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000dee:	00001097          	auipc	ra,0x1
    80000df2:	ff8080e7          	jalr	-8(ra) # 80001de6 <mycpu>
    80000df6:	5d3c                	lw	a5,120(a0)
    80000df8:	2785                	addiw	a5,a5,1
    80000dfa:	dd3c                	sw	a5,120(a0)
}
    80000dfc:	60e2                	ld	ra,24(sp)
    80000dfe:	6442                	ld	s0,16(sp)
    80000e00:	64a2                	ld	s1,8(sp)
    80000e02:	6105                	addi	sp,sp,32
    80000e04:	8082                	ret
    mycpu()->intena = old;
    80000e06:	00001097          	auipc	ra,0x1
    80000e0a:	fe0080e7          	jalr	-32(ra) # 80001de6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000e0e:	8085                	srli	s1,s1,0x1
    80000e10:	8885                	andi	s1,s1,1
    80000e12:	dd64                	sw	s1,124(a0)
    80000e14:	bfe9                	j	80000dee <push_off+0x24>

0000000080000e16 <acquire>:
{
    80000e16:	1101                	addi	sp,sp,-32
    80000e18:	ec06                	sd	ra,24(sp)
    80000e1a:	e822                	sd	s0,16(sp)
    80000e1c:	e426                	sd	s1,8(sp)
    80000e1e:	1000                	addi	s0,sp,32
    80000e20:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	fa8080e7          	jalr	-88(ra) # 80000dca <push_off>
  if(holding(lk))
    80000e2a:	8526                	mv	a0,s1
    80000e2c:	00000097          	auipc	ra,0x0
    80000e30:	f70080e7          	jalr	-144(ra) # 80000d9c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e34:	4705                	li	a4,1
  if(holding(lk))
    80000e36:	e115                	bnez	a0,80000e5a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e38:	87ba                	mv	a5,a4
    80000e3a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000e3e:	2781                	sext.w	a5,a5
    80000e40:	ffe5                	bnez	a5,80000e38 <acquire+0x22>
  __sync_synchronize();
    80000e42:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000e46:	00001097          	auipc	ra,0x1
    80000e4a:	fa0080e7          	jalr	-96(ra) # 80001de6 <mycpu>
    80000e4e:	e888                	sd	a0,16(s1)
}
    80000e50:	60e2                	ld	ra,24(sp)
    80000e52:	6442                	ld	s0,16(sp)
    80000e54:	64a2                	ld	s1,8(sp)
    80000e56:	6105                	addi	sp,sp,32
    80000e58:	8082                	ret
    panic("acquire");
    80000e5a:	00008517          	auipc	a0,0x8
    80000e5e:	24e50513          	addi	a0,a0,590 # 800090a8 <digits+0x68>
    80000e62:	fffff097          	auipc	ra,0xfffff
    80000e66:	6e2080e7          	jalr	1762(ra) # 80000544 <panic>

0000000080000e6a <pop_off>:

void
pop_off(void)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e406                	sd	ra,8(sp)
    80000e6e:	e022                	sd	s0,0(sp)
    80000e70:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e72:	00001097          	auipc	ra,0x1
    80000e76:	f74080e7          	jalr	-140(ra) # 80001de6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e7a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e7e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e80:	e78d                	bnez	a5,80000eaa <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e82:	5d3c                	lw	a5,120(a0)
    80000e84:	02f05b63          	blez	a5,80000eba <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e88:	37fd                	addiw	a5,a5,-1
    80000e8a:	0007871b          	sext.w	a4,a5
    80000e8e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e90:	eb09                	bnez	a4,80000ea2 <pop_off+0x38>
    80000e92:	5d7c                	lw	a5,124(a0)
    80000e94:	c799                	beqz	a5,80000ea2 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e9e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ea2:	60a2                	ld	ra,8(sp)
    80000ea4:	6402                	ld	s0,0(sp)
    80000ea6:	0141                	addi	sp,sp,16
    80000ea8:	8082                	ret
    panic("pop_off - interruptible");
    80000eaa:	00008517          	auipc	a0,0x8
    80000eae:	20650513          	addi	a0,a0,518 # 800090b0 <digits+0x70>
    80000eb2:	fffff097          	auipc	ra,0xfffff
    80000eb6:	692080e7          	jalr	1682(ra) # 80000544 <panic>
    panic("pop_off");
    80000eba:	00008517          	auipc	a0,0x8
    80000ebe:	20e50513          	addi	a0,a0,526 # 800090c8 <digits+0x88>
    80000ec2:	fffff097          	auipc	ra,0xfffff
    80000ec6:	682080e7          	jalr	1666(ra) # 80000544 <panic>

0000000080000eca <release>:
{
    80000eca:	1101                	addi	sp,sp,-32
    80000ecc:	ec06                	sd	ra,24(sp)
    80000ece:	e822                	sd	s0,16(sp)
    80000ed0:	e426                	sd	s1,8(sp)
    80000ed2:	1000                	addi	s0,sp,32
    80000ed4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	ec6080e7          	jalr	-314(ra) # 80000d9c <holding>
    80000ede:	c115                	beqz	a0,80000f02 <release+0x38>
  lk->cpu = 0;
    80000ee0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ee4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ee8:	0f50000f          	fence	iorw,ow
    80000eec:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	f7a080e7          	jalr	-134(ra) # 80000e6a <pop_off>
}
    80000ef8:	60e2                	ld	ra,24(sp)
    80000efa:	6442                	ld	s0,16(sp)
    80000efc:	64a2                	ld	s1,8(sp)
    80000efe:	6105                	addi	sp,sp,32
    80000f00:	8082                	ret
    panic("release");
    80000f02:	00008517          	auipc	a0,0x8
    80000f06:	1ce50513          	addi	a0,a0,462 # 800090d0 <digits+0x90>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	63a080e7          	jalr	1594(ra) # 80000544 <panic>

0000000080000f12 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000f12:	1141                	addi	sp,sp,-16
    80000f14:	e422                	sd	s0,8(sp)
    80000f16:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000f18:	ce09                	beqz	a2,80000f32 <memset+0x20>
    80000f1a:	87aa                	mv	a5,a0
    80000f1c:	fff6071b          	addiw	a4,a2,-1
    80000f20:	1702                	slli	a4,a4,0x20
    80000f22:	9301                	srli	a4,a4,0x20
    80000f24:	0705                	addi	a4,a4,1
    80000f26:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000f28:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000f2c:	0785                	addi	a5,a5,1
    80000f2e:	fee79de3          	bne	a5,a4,80000f28 <memset+0x16>
  }
  return dst;
}
    80000f32:	6422                	ld	s0,8(sp)
    80000f34:	0141                	addi	sp,sp,16
    80000f36:	8082                	ret

0000000080000f38 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000f38:	1141                	addi	sp,sp,-16
    80000f3a:	e422                	sd	s0,8(sp)
    80000f3c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000f3e:	ca05                	beqz	a2,80000f6e <memcmp+0x36>
    80000f40:	fff6069b          	addiw	a3,a2,-1
    80000f44:	1682                	slli	a3,a3,0x20
    80000f46:	9281                	srli	a3,a3,0x20
    80000f48:	0685                	addi	a3,a3,1
    80000f4a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000f4c:	00054783          	lbu	a5,0(a0)
    80000f50:	0005c703          	lbu	a4,0(a1)
    80000f54:	00e79863          	bne	a5,a4,80000f64 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f58:	0505                	addi	a0,a0,1
    80000f5a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000f5c:	fed518e3          	bne	a0,a3,80000f4c <memcmp+0x14>
  }

  return 0;
    80000f60:	4501                	li	a0,0
    80000f62:	a019                	j	80000f68 <memcmp+0x30>
      return *s1 - *s2;
    80000f64:	40e7853b          	subw	a0,a5,a4
}
    80000f68:	6422                	ld	s0,8(sp)
    80000f6a:	0141                	addi	sp,sp,16
    80000f6c:	8082                	ret
  return 0;
    80000f6e:	4501                	li	a0,0
    80000f70:	bfe5                	j	80000f68 <memcmp+0x30>

0000000080000f72 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f72:	1141                	addi	sp,sp,-16
    80000f74:	e422                	sd	s0,8(sp)
    80000f76:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f78:	ca0d                	beqz	a2,80000faa <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f7a:	00a5f963          	bgeu	a1,a0,80000f8c <memmove+0x1a>
    80000f7e:	02061693          	slli	a3,a2,0x20
    80000f82:	9281                	srli	a3,a3,0x20
    80000f84:	00d58733          	add	a4,a1,a3
    80000f88:	02e56463          	bltu	a0,a4,80000fb0 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f8c:	fff6079b          	addiw	a5,a2,-1
    80000f90:	1782                	slli	a5,a5,0x20
    80000f92:	9381                	srli	a5,a5,0x20
    80000f94:	0785                	addi	a5,a5,1
    80000f96:	97ae                	add	a5,a5,a1
    80000f98:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f9a:	0585                	addi	a1,a1,1
    80000f9c:	0705                	addi	a4,a4,1
    80000f9e:	fff5c683          	lbu	a3,-1(a1)
    80000fa2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000fa6:	fef59ae3          	bne	a1,a5,80000f9a <memmove+0x28>

  return dst;
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret
    d += n;
    80000fb0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000fb2:	fff6079b          	addiw	a5,a2,-1
    80000fb6:	1782                	slli	a5,a5,0x20
    80000fb8:	9381                	srli	a5,a5,0x20
    80000fba:	fff7c793          	not	a5,a5
    80000fbe:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000fc0:	177d                	addi	a4,a4,-1
    80000fc2:	16fd                	addi	a3,a3,-1
    80000fc4:	00074603          	lbu	a2,0(a4)
    80000fc8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000fcc:	fef71ae3          	bne	a4,a5,80000fc0 <memmove+0x4e>
    80000fd0:	bfe9                	j	80000faa <memmove+0x38>

0000000080000fd2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000fd2:	1141                	addi	sp,sp,-16
    80000fd4:	e406                	sd	ra,8(sp)
    80000fd6:	e022                	sd	s0,0(sp)
    80000fd8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	f98080e7          	jalr	-104(ra) # 80000f72 <memmove>
}
    80000fe2:	60a2                	ld	ra,8(sp)
    80000fe4:	6402                	ld	s0,0(sp)
    80000fe6:	0141                	addi	sp,sp,16
    80000fe8:	8082                	ret

0000000080000fea <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000fea:	1141                	addi	sp,sp,-16
    80000fec:	e422                	sd	s0,8(sp)
    80000fee:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ff0:	ce11                	beqz	a2,8000100c <strncmp+0x22>
    80000ff2:	00054783          	lbu	a5,0(a0)
    80000ff6:	cf89                	beqz	a5,80001010 <strncmp+0x26>
    80000ff8:	0005c703          	lbu	a4,0(a1)
    80000ffc:	00f71a63          	bne	a4,a5,80001010 <strncmp+0x26>
    n--, p++, q++;
    80001000:	367d                	addiw	a2,a2,-1
    80001002:	0505                	addi	a0,a0,1
    80001004:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001006:	f675                	bnez	a2,80000ff2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80001008:	4501                	li	a0,0
    8000100a:	a809                	j	8000101c <strncmp+0x32>
    8000100c:	4501                	li	a0,0
    8000100e:	a039                	j	8000101c <strncmp+0x32>
  if(n == 0)
    80001010:	ca09                	beqz	a2,80001022 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001012:	00054503          	lbu	a0,0(a0)
    80001016:	0005c783          	lbu	a5,0(a1)
    8000101a:	9d1d                	subw	a0,a0,a5
}
    8000101c:	6422                	ld	s0,8(sp)
    8000101e:	0141                	addi	sp,sp,16
    80001020:	8082                	ret
    return 0;
    80001022:	4501                	li	a0,0
    80001024:	bfe5                	j	8000101c <strncmp+0x32>

0000000080001026 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001026:	1141                	addi	sp,sp,-16
    80001028:	e422                	sd	s0,8(sp)
    8000102a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000102c:	872a                	mv	a4,a0
    8000102e:	8832                	mv	a6,a2
    80001030:	367d                	addiw	a2,a2,-1
    80001032:	01005963          	blez	a6,80001044 <strncpy+0x1e>
    80001036:	0705                	addi	a4,a4,1
    80001038:	0005c783          	lbu	a5,0(a1)
    8000103c:	fef70fa3          	sb	a5,-1(a4)
    80001040:	0585                	addi	a1,a1,1
    80001042:	f7f5                	bnez	a5,8000102e <strncpy+0x8>
    ;
  while(n-- > 0)
    80001044:	00c05d63          	blez	a2,8000105e <strncpy+0x38>
    80001048:	86ba                	mv	a3,a4
    *s++ = 0;
    8000104a:	0685                	addi	a3,a3,1
    8000104c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001050:	fff6c793          	not	a5,a3
    80001054:	9fb9                	addw	a5,a5,a4
    80001056:	010787bb          	addw	a5,a5,a6
    8000105a:	fef048e3          	bgtz	a5,8000104a <strncpy+0x24>
  return os;
}
    8000105e:	6422                	ld	s0,8(sp)
    80001060:	0141                	addi	sp,sp,16
    80001062:	8082                	ret

0000000080001064 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001064:	1141                	addi	sp,sp,-16
    80001066:	e422                	sd	s0,8(sp)
    80001068:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000106a:	02c05363          	blez	a2,80001090 <safestrcpy+0x2c>
    8000106e:	fff6069b          	addiw	a3,a2,-1
    80001072:	1682                	slli	a3,a3,0x20
    80001074:	9281                	srli	a3,a3,0x20
    80001076:	96ae                	add	a3,a3,a1
    80001078:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000107a:	00d58963          	beq	a1,a3,8000108c <safestrcpy+0x28>
    8000107e:	0585                	addi	a1,a1,1
    80001080:	0785                	addi	a5,a5,1
    80001082:	fff5c703          	lbu	a4,-1(a1)
    80001086:	fee78fa3          	sb	a4,-1(a5)
    8000108a:	fb65                	bnez	a4,8000107a <safestrcpy+0x16>
    ;
  *s = 0;
    8000108c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001090:	6422                	ld	s0,8(sp)
    80001092:	0141                	addi	sp,sp,16
    80001094:	8082                	ret

0000000080001096 <strlen>:

int
strlen(const char *s)
{
    80001096:	1141                	addi	sp,sp,-16
    80001098:	e422                	sd	s0,8(sp)
    8000109a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000109c:	00054783          	lbu	a5,0(a0)
    800010a0:	cf91                	beqz	a5,800010bc <strlen+0x26>
    800010a2:	0505                	addi	a0,a0,1
    800010a4:	87aa                	mv	a5,a0
    800010a6:	4685                	li	a3,1
    800010a8:	9e89                	subw	a3,a3,a0
    800010aa:	00f6853b          	addw	a0,a3,a5
    800010ae:	0785                	addi	a5,a5,1
    800010b0:	fff7c703          	lbu	a4,-1(a5)
    800010b4:	fb7d                	bnez	a4,800010aa <strlen+0x14>
    ;
  return n;
}
    800010b6:	6422                	ld	s0,8(sp)
    800010b8:	0141                	addi	sp,sp,16
    800010ba:	8082                	ret
  for(n = 0; s[n]; n++)
    800010bc:	4501                	li	a0,0
    800010be:	bfe5                	j	800010b6 <strlen+0x20>

00000000800010c0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800010c0:	1141                	addi	sp,sp,-16
    800010c2:	e406                	sd	ra,8(sp)
    800010c4:	e022                	sd	s0,0(sp)
    800010c6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    800010c8:	00001097          	auipc	ra,0x1
    800010cc:	d0e080e7          	jalr	-754(ra) # 80001dd6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    800010d0:	00009717          	auipc	a4,0x9
    800010d4:	b4870713          	addi	a4,a4,-1208 # 80009c18 <started>
  if(cpuid() == 0){
    800010d8:	c139                	beqz	a0,8000111e <main+0x5e>
    while(started == 0)
    800010da:	431c                	lw	a5,0(a4)
    800010dc:	2781                	sext.w	a5,a5
    800010de:	dff5                	beqz	a5,800010da <main+0x1a>
      ;
    __sync_synchronize();
    800010e0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800010e4:	00001097          	auipc	ra,0x1
    800010e8:	cf2080e7          	jalr	-782(ra) # 80001dd6 <cpuid>
    800010ec:	85aa                	mv	a1,a0
    800010ee:	00008517          	auipc	a0,0x8
    800010f2:	00250513          	addi	a0,a0,2 # 800090f0 <digits+0xb0>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	498080e7          	jalr	1176(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	0d8080e7          	jalr	216(ra) # 800011d6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001106:	00002097          	auipc	ra,0x2
    8000110a:	234080e7          	jalr	564(ra) # 8000333a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000110e:	00006097          	auipc	ra,0x6
    80001112:	c22080e7          	jalr	-990(ra) # 80006d30 <plicinithart>
  }

  scheduler();        
    80001116:	00001097          	auipc	ra,0x1
    8000111a:	4aa080e7          	jalr	1194(ra) # 800025c0 <scheduler>
    consoleinit();
    8000111e:	fffff097          	auipc	ra,0xfffff
    80001122:	338080e7          	jalr	824(ra) # 80000456 <consoleinit>
    printfinit();
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	64e080e7          	jalr	1614(ra) # 80000774 <printfinit>
    printf("\n");
    8000112e:	00008517          	auipc	a0,0x8
    80001132:	1da50513          	addi	a0,a0,474 # 80009308 <digits+0x2c8>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	458080e7          	jalr	1112(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	f9a50513          	addi	a0,a0,-102 # 800090d8 <digits+0x98>
    80001146:	fffff097          	auipc	ra,0xfffff
    8000114a:	448080e7          	jalr	1096(ra) # 8000058e <printf>
    printf("\n");
    8000114e:	00008517          	auipc	a0,0x8
    80001152:	1ba50513          	addi	a0,a0,442 # 80009308 <digits+0x2c8>
    80001156:	fffff097          	auipc	ra,0xfffff
    8000115a:	438080e7          	jalr	1080(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	b78080e7          	jalr	-1160(ra) # 80000cd6 <kinit>
    kvminit();       // create kernel page table
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	326080e7          	jalr	806(ra) # 8000148c <kvminit>
    kvminithart();   // turn on paging
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	068080e7          	jalr	104(ra) # 800011d6 <kvminithart>
    procinit();      // process table
    80001176:	00001097          	auipc	ra,0x1
    8000117a:	bac080e7          	jalr	-1108(ra) # 80001d22 <procinit>
    trapinit();      // trap vectors
    8000117e:	00002097          	auipc	ra,0x2
    80001182:	194080e7          	jalr	404(ra) # 80003312 <trapinit>
    trapinithart();  // install kernel trap vector
    80001186:	00002097          	auipc	ra,0x2
    8000118a:	1b4080e7          	jalr	436(ra) # 8000333a <trapinithart>
    plicinit();      // set up interrupt controller
    8000118e:	00006097          	auipc	ra,0x6
    80001192:	b8c080e7          	jalr	-1140(ra) # 80006d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001196:	00006097          	auipc	ra,0x6
    8000119a:	b9a080e7          	jalr	-1126(ra) # 80006d30 <plicinithart>
    binit();         // buffer cache
    8000119e:	00003097          	auipc	ra,0x3
    800011a2:	d54080e7          	jalr	-684(ra) # 80003ef2 <binit>
    iinit();         // inode table
    800011a6:	00003097          	auipc	ra,0x3
    800011aa:	3f8080e7          	jalr	1016(ra) # 8000459e <iinit>
    fileinit();      // file table
    800011ae:	00004097          	auipc	ra,0x4
    800011b2:	396080e7          	jalr	918(ra) # 80005544 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800011b6:	00006097          	auipc	ra,0x6
    800011ba:	c82080e7          	jalr	-894(ra) # 80006e38 <virtio_disk_init>
    userinit();      // first user process
    800011be:	00001097          	auipc	ra,0x1
    800011c2:	0e8080e7          	jalr	232(ra) # 800022a6 <userinit>
    __sync_synchronize();
    800011c6:	0ff0000f          	fence
    started = 1;
    800011ca:	4785                	li	a5,1
    800011cc:	00009717          	auipc	a4,0x9
    800011d0:	a4f72623          	sw	a5,-1460(a4) # 80009c18 <started>
    800011d4:	b789                	j	80001116 <main+0x56>

00000000800011d6 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    800011d6:	1141                	addi	sp,sp,-16
    800011d8:	e422                	sd	s0,8(sp)
    800011da:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800011dc:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800011e0:	00009797          	auipc	a5,0x9
    800011e4:	a407b783          	ld	a5,-1472(a5) # 80009c20 <kernel_pagetable>
    800011e8:	83b1                	srli	a5,a5,0xc
    800011ea:	577d                	li	a4,-1
    800011ec:	177e                	slli	a4,a4,0x3f
    800011ee:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800011f0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800011f4:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800011f8:	6422                	ld	s0,8(sp)
    800011fa:	0141                	addi	sp,sp,16
    800011fc:	8082                	ret

00000000800011fe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011fe:	7139                	addi	sp,sp,-64
    80001200:	fc06                	sd	ra,56(sp)
    80001202:	f822                	sd	s0,48(sp)
    80001204:	f426                	sd	s1,40(sp)
    80001206:	f04a                	sd	s2,32(sp)
    80001208:	ec4e                	sd	s3,24(sp)
    8000120a:	e852                	sd	s4,16(sp)
    8000120c:	e456                	sd	s5,8(sp)
    8000120e:	e05a                	sd	s6,0(sp)
    80001210:	0080                	addi	s0,sp,64
    80001212:	84aa                	mv	s1,a0
    80001214:	89ae                	mv	s3,a1
    80001216:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80001218:	57fd                	li	a5,-1
    8000121a:	83e9                	srli	a5,a5,0x1a
    8000121c:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    8000121e:	4b31                	li	s6,12
  if (va >= MAXVA)
    80001220:	04b7f263          	bgeu	a5,a1,80001264 <walk+0x66>
    panic("walk");
    80001224:	00008517          	auipc	a0,0x8
    80001228:	ee450513          	addi	a0,a0,-284 # 80009108 <digits+0xc8>
    8000122c:	fffff097          	auipc	ra,0xfffff
    80001230:	318080e7          	jalr	792(ra) # 80000544 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001234:	060a8663          	beqz	s5,800012a0 <walk+0xa2>
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	ae2080e7          	jalr	-1310(ra) # 80000d1a <kalloc>
    80001240:	84aa                	mv	s1,a0
    80001242:	c529                	beqz	a0,8000128c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001244:	6605                	lui	a2,0x1
    80001246:	4581                	li	a1,0
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	cca080e7          	jalr	-822(ra) # 80000f12 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001250:	00c4d793          	srli	a5,s1,0xc
    80001254:	07aa                	slli	a5,a5,0xa
    80001256:	0017e793          	ori	a5,a5,1
    8000125a:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    8000125e:	3a5d                	addiw	s4,s4,-9
    80001260:	036a0063          	beq	s4,s6,80001280 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001264:	0149d933          	srl	s2,s3,s4
    80001268:	1ff97913          	andi	s2,s2,511
    8000126c:	090e                	slli	s2,s2,0x3
    8000126e:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001270:	00093483          	ld	s1,0(s2)
    80001274:	0014f793          	andi	a5,s1,1
    80001278:	dfd5                	beqz	a5,80001234 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000127a:	80a9                	srli	s1,s1,0xa
    8000127c:	04b2                	slli	s1,s1,0xc
    8000127e:	b7c5                	j	8000125e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001280:	00c9d513          	srli	a0,s3,0xc
    80001284:	1ff57513          	andi	a0,a0,511
    80001288:	050e                	slli	a0,a0,0x3
    8000128a:	9526                	add	a0,a0,s1
}
    8000128c:	70e2                	ld	ra,56(sp)
    8000128e:	7442                	ld	s0,48(sp)
    80001290:	74a2                	ld	s1,40(sp)
    80001292:	7902                	ld	s2,32(sp)
    80001294:	69e2                	ld	s3,24(sp)
    80001296:	6a42                	ld	s4,16(sp)
    80001298:	6aa2                	ld	s5,8(sp)
    8000129a:	6b02                	ld	s6,0(sp)
    8000129c:	6121                	addi	sp,sp,64
    8000129e:	8082                	ret
        return 0;
    800012a0:	4501                	li	a0,0
    800012a2:	b7ed                	j	8000128c <walk+0x8e>

00000000800012a4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800012a4:	57fd                	li	a5,-1
    800012a6:	83e9                	srli	a5,a5,0x1a
    800012a8:	00b7f463          	bgeu	a5,a1,800012b0 <walkaddr+0xc>
    return 0;
    800012ac:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800012ae:	8082                	ret
{
    800012b0:	1141                	addi	sp,sp,-16
    800012b2:	e406                	sd	ra,8(sp)
    800012b4:	e022                	sd	s0,0(sp)
    800012b6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800012b8:	4601                	li	a2,0
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f44080e7          	jalr	-188(ra) # 800011fe <walk>
  if (pte == 0)
    800012c2:	c105                	beqz	a0,800012e2 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    800012c4:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    800012c6:	0117f693          	andi	a3,a5,17
    800012ca:	4745                	li	a4,17
    return 0;
    800012cc:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800012ce:	00e68663          	beq	a3,a4,800012da <walkaddr+0x36>
}
    800012d2:	60a2                	ld	ra,8(sp)
    800012d4:	6402                	ld	s0,0(sp)
    800012d6:	0141                	addi	sp,sp,16
    800012d8:	8082                	ret
  pa = PTE2PA(*pte);
    800012da:	00a7d513          	srli	a0,a5,0xa
    800012de:	0532                	slli	a0,a0,0xc
  return pa;
    800012e0:	bfcd                	j	800012d2 <walkaddr+0x2e>
    return 0;
    800012e2:	4501                	li	a0,0
    800012e4:	b7fd                	j	800012d2 <walkaddr+0x2e>

00000000800012e6 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012e6:	715d                	addi	sp,sp,-80
    800012e8:	e486                	sd	ra,72(sp)
    800012ea:	e0a2                	sd	s0,64(sp)
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	f84a                	sd	s2,48(sp)
    800012f0:	f44e                	sd	s3,40(sp)
    800012f2:	f052                	sd	s4,32(sp)
    800012f4:	ec56                	sd	s5,24(sp)
    800012f6:	e85a                	sd	s6,16(sp)
    800012f8:	e45e                	sd	s7,8(sp)
    800012fa:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    800012fc:	c205                	beqz	a2,8000131c <mappages+0x36>
    800012fe:	8aaa                	mv	s5,a0
    80001300:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001302:	77fd                	lui	a5,0xfffff
    80001304:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001308:	15fd                	addi	a1,a1,-1
    8000130a:	00c589b3          	add	s3,a1,a2
    8000130e:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001312:	8952                	mv	s2,s4
    80001314:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001318:	6b85                	lui	s7,0x1
    8000131a:	a015                	j	8000133e <mappages+0x58>
    panic("mappages: size");
    8000131c:	00008517          	auipc	a0,0x8
    80001320:	df450513          	addi	a0,a0,-524 # 80009110 <digits+0xd0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	220080e7          	jalr	544(ra) # 80000544 <panic>
      panic("mappages: remap");
    8000132c:	00008517          	auipc	a0,0x8
    80001330:	df450513          	addi	a0,a0,-524 # 80009120 <digits+0xe0>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	210080e7          	jalr	528(ra) # 80000544 <panic>
    a += PGSIZE;
    8000133c:	995e                	add	s2,s2,s7
  for (;;)
    8000133e:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001342:	4605                	li	a2,1
    80001344:	85ca                	mv	a1,s2
    80001346:	8556                	mv	a0,s5
    80001348:	00000097          	auipc	ra,0x0
    8000134c:	eb6080e7          	jalr	-330(ra) # 800011fe <walk>
    80001350:	cd19                	beqz	a0,8000136e <mappages+0x88>
    if (*pte & PTE_V)
    80001352:	611c                	ld	a5,0(a0)
    80001354:	8b85                	andi	a5,a5,1
    80001356:	fbf9                	bnez	a5,8000132c <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001358:	80b1                	srli	s1,s1,0xc
    8000135a:	04aa                	slli	s1,s1,0xa
    8000135c:	0164e4b3          	or	s1,s1,s6
    80001360:	0014e493          	ori	s1,s1,1
    80001364:	e104                	sd	s1,0(a0)
    if (a == last)
    80001366:	fd391be3          	bne	s2,s3,8000133c <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000136a:	4501                	li	a0,0
    8000136c:	a011                	j	80001370 <mappages+0x8a>
      return -1;
    8000136e:	557d                	li	a0,-1
}
    80001370:	60a6                	ld	ra,72(sp)
    80001372:	6406                	ld	s0,64(sp)
    80001374:	74e2                	ld	s1,56(sp)
    80001376:	7942                	ld	s2,48(sp)
    80001378:	79a2                	ld	s3,40(sp)
    8000137a:	7a02                	ld	s4,32(sp)
    8000137c:	6ae2                	ld	s5,24(sp)
    8000137e:	6b42                	ld	s6,16(sp)
    80001380:	6ba2                	ld	s7,8(sp)
    80001382:	6161                	addi	sp,sp,80
    80001384:	8082                	ret

0000000080001386 <kvmmap>:
{
    80001386:	1141                	addi	sp,sp,-16
    80001388:	e406                	sd	ra,8(sp)
    8000138a:	e022                	sd	s0,0(sp)
    8000138c:	0800                	addi	s0,sp,16
    8000138e:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001390:	86b2                	mv	a3,a2
    80001392:	863e                	mv	a2,a5
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f52080e7          	jalr	-174(ra) # 800012e6 <mappages>
    8000139c:	e509                	bnez	a0,800013a6 <kvmmap+0x20>
}
    8000139e:	60a2                	ld	ra,8(sp)
    800013a0:	6402                	ld	s0,0(sp)
    800013a2:	0141                	addi	sp,sp,16
    800013a4:	8082                	ret
    panic("kvmmap");
    800013a6:	00008517          	auipc	a0,0x8
    800013aa:	d8a50513          	addi	a0,a0,-630 # 80009130 <digits+0xf0>
    800013ae:	fffff097          	auipc	ra,0xfffff
    800013b2:	196080e7          	jalr	406(ra) # 80000544 <panic>

00000000800013b6 <kvmmake>:
{
    800013b6:	1101                	addi	sp,sp,-32
    800013b8:	ec06                	sd	ra,24(sp)
    800013ba:	e822                	sd	s0,16(sp)
    800013bc:	e426                	sd	s1,8(sp)
    800013be:	e04a                	sd	s2,0(sp)
    800013c0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	958080e7          	jalr	-1704(ra) # 80000d1a <kalloc>
    800013ca:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800013cc:	6605                	lui	a2,0x1
    800013ce:	4581                	li	a1,0
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	b42080e7          	jalr	-1214(ra) # 80000f12 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013d8:	4719                	li	a4,6
    800013da:	6685                	lui	a3,0x1
    800013dc:	10000637          	lui	a2,0x10000
    800013e0:	100005b7          	lui	a1,0x10000
    800013e4:	8526                	mv	a0,s1
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	fa0080e7          	jalr	-96(ra) # 80001386 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013ee:	4719                	li	a4,6
    800013f0:	6685                	lui	a3,0x1
    800013f2:	10001637          	lui	a2,0x10001
    800013f6:	100015b7          	lui	a1,0x10001
    800013fa:	8526                	mv	a0,s1
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	f8a080e7          	jalr	-118(ra) # 80001386 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001404:	4719                	li	a4,6
    80001406:	004006b7          	lui	a3,0x400
    8000140a:	0c000637          	lui	a2,0xc000
    8000140e:	0c0005b7          	lui	a1,0xc000
    80001412:	8526                	mv	a0,s1
    80001414:	00000097          	auipc	ra,0x0
    80001418:	f72080e7          	jalr	-142(ra) # 80001386 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    8000141c:	00008917          	auipc	s2,0x8
    80001420:	be490913          	addi	s2,s2,-1052 # 80009000 <etext>
    80001424:	4729                	li	a4,10
    80001426:	80008697          	auipc	a3,0x80008
    8000142a:	bda68693          	addi	a3,a3,-1062 # 9000 <_entry-0x7fff7000>
    8000142e:	4605                	li	a2,1
    80001430:	067e                	slli	a2,a2,0x1f
    80001432:	85b2                	mv	a1,a2
    80001434:	8526                	mv	a0,s1
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	f50080e7          	jalr	-176(ra) # 80001386 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000143e:	4719                	li	a4,6
    80001440:	46c5                	li	a3,17
    80001442:	06ee                	slli	a3,a3,0x1b
    80001444:	412686b3          	sub	a3,a3,s2
    80001448:	864a                	mv	a2,s2
    8000144a:	85ca                	mv	a1,s2
    8000144c:	8526                	mv	a0,s1
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	f38080e7          	jalr	-200(ra) # 80001386 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001456:	4729                	li	a4,10
    80001458:	6685                	lui	a3,0x1
    8000145a:	00007617          	auipc	a2,0x7
    8000145e:	ba660613          	addi	a2,a2,-1114 # 80008000 <_trampoline>
    80001462:	040005b7          	lui	a1,0x4000
    80001466:	15fd                	addi	a1,a1,-1
    80001468:	05b2                	slli	a1,a1,0xc
    8000146a:	8526                	mv	a0,s1
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	f1a080e7          	jalr	-230(ra) # 80001386 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001474:	8526                	mv	a0,s1
    80001476:	00001097          	auipc	ra,0x1
    8000147a:	816080e7          	jalr	-2026(ra) # 80001c8c <proc_mapstacks>
}
    8000147e:	8526                	mv	a0,s1
    80001480:	60e2                	ld	ra,24(sp)
    80001482:	6442                	ld	s0,16(sp)
    80001484:	64a2                	ld	s1,8(sp)
    80001486:	6902                	ld	s2,0(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret

000000008000148c <kvminit>:
{
    8000148c:	1141                	addi	sp,sp,-16
    8000148e:	e406                	sd	ra,8(sp)
    80001490:	e022                	sd	s0,0(sp)
    80001492:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f22080e7          	jalr	-222(ra) # 800013b6 <kvmmake>
    8000149c:	00008797          	auipc	a5,0x8
    800014a0:	78a7b223          	sd	a0,1924(a5) # 80009c20 <kernel_pagetable>
}
    800014a4:	60a2                	ld	ra,8(sp)
    800014a6:	6402                	ld	s0,0(sp)
    800014a8:	0141                	addi	sp,sp,16
    800014aa:	8082                	ret

00000000800014ac <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014ac:	715d                	addi	sp,sp,-80
    800014ae:	e486                	sd	ra,72(sp)
    800014b0:	e0a2                	sd	s0,64(sp)
    800014b2:	fc26                	sd	s1,56(sp)
    800014b4:	f84a                	sd	s2,48(sp)
    800014b6:	f44e                	sd	s3,40(sp)
    800014b8:	f052                	sd	s4,32(sp)
    800014ba:	ec56                	sd	s5,24(sp)
    800014bc:	e85a                	sd	s6,16(sp)
    800014be:	e45e                	sd	s7,8(sp)
    800014c0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    800014c2:	03459793          	slli	a5,a1,0x34
    800014c6:	e795                	bnez	a5,800014f2 <uvmunmap+0x46>
    800014c8:	8a2a                	mv	s4,a0
    800014ca:	892e                	mv	s2,a1
    800014cc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800014ce:	0632                	slli	a2,a2,0xc
    800014d0:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800014d4:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800014d6:	6b05                	lui	s6,0x1
    800014d8:	0735e863          	bltu	a1,s3,80001548 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800014dc:	60a6                	ld	ra,72(sp)
    800014de:	6406                	ld	s0,64(sp)
    800014e0:	74e2                	ld	s1,56(sp)
    800014e2:	7942                	ld	s2,48(sp)
    800014e4:	79a2                	ld	s3,40(sp)
    800014e6:	7a02                	ld	s4,32(sp)
    800014e8:	6ae2                	ld	s5,24(sp)
    800014ea:	6b42                	ld	s6,16(sp)
    800014ec:	6ba2                	ld	s7,8(sp)
    800014ee:	6161                	addi	sp,sp,80
    800014f0:	8082                	ret
    panic("uvmunmap: not aligned");
    800014f2:	00008517          	auipc	a0,0x8
    800014f6:	c4650513          	addi	a0,a0,-954 # 80009138 <digits+0xf8>
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	04a080e7          	jalr	74(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    80001502:	00008517          	auipc	a0,0x8
    80001506:	c4e50513          	addi	a0,a0,-946 # 80009150 <digits+0x110>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	03a080e7          	jalr	58(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    80001512:	00008517          	auipc	a0,0x8
    80001516:	c4e50513          	addi	a0,a0,-946 # 80009160 <digits+0x120>
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	02a080e7          	jalr	42(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    80001522:	00008517          	auipc	a0,0x8
    80001526:	c5650513          	addi	a0,a0,-938 # 80009178 <digits+0x138>
    8000152a:	fffff097          	auipc	ra,0xfffff
    8000152e:	01a080e7          	jalr	26(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001532:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001534:	0532                	slli	a0,a0,0xc
    80001536:	fffff097          	auipc	ra,0xfffff
    8000153a:	65c080e7          	jalr	1628(ra) # 80000b92 <kfree>
    *pte = 0;
    8000153e:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001542:	995a                	add	s2,s2,s6
    80001544:	f9397ce3          	bgeu	s2,s3,800014dc <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    80001548:	4601                	li	a2,0
    8000154a:	85ca                	mv	a1,s2
    8000154c:	8552                	mv	a0,s4
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	cb0080e7          	jalr	-848(ra) # 800011fe <walk>
    80001556:	84aa                	mv	s1,a0
    80001558:	d54d                	beqz	a0,80001502 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000155a:	6108                	ld	a0,0(a0)
    8000155c:	00157793          	andi	a5,a0,1
    80001560:	dbcd                	beqz	a5,80001512 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001562:	3ff57793          	andi	a5,a0,1023
    80001566:	fb778ee3          	beq	a5,s7,80001522 <uvmunmap+0x76>
    if (do_free)
    8000156a:	fc0a8ae3          	beqz	s5,8000153e <uvmunmap+0x92>
    8000156e:	b7d1                	j	80001532 <uvmunmap+0x86>

0000000080001570 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001570:	1101                	addi	sp,sp,-32
    80001572:	ec06                	sd	ra,24(sp)
    80001574:	e822                	sd	s0,16(sp)
    80001576:	e426                	sd	s1,8(sp)
    80001578:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	7a0080e7          	jalr	1952(ra) # 80000d1a <kalloc>
    80001582:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001584:	c519                	beqz	a0,80001592 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001586:	6605                	lui	a2,0x1
    80001588:	4581                	li	a1,0
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	988080e7          	jalr	-1656(ra) # 80000f12 <memset>
  return pagetable;
}
    80001592:	8526                	mv	a0,s1
    80001594:	60e2                	ld	ra,24(sp)
    80001596:	6442                	ld	s0,16(sp)
    80001598:	64a2                	ld	s1,8(sp)
    8000159a:	6105                	addi	sp,sp,32
    8000159c:	8082                	ret

000000008000159e <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000159e:	7179                	addi	sp,sp,-48
    800015a0:	f406                	sd	ra,40(sp)
    800015a2:	f022                	sd	s0,32(sp)
    800015a4:	ec26                	sd	s1,24(sp)
    800015a6:	e84a                	sd	s2,16(sp)
    800015a8:	e44e                	sd	s3,8(sp)
    800015aa:	e052                	sd	s4,0(sp)
    800015ac:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800015ae:	6785                	lui	a5,0x1
    800015b0:	04f67863          	bgeu	a2,a5,80001600 <uvmfirst+0x62>
    800015b4:	8a2a                	mv	s4,a0
    800015b6:	89ae                	mv	s3,a1
    800015b8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	760080e7          	jalr	1888(ra) # 80000d1a <kalloc>
    800015c2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015c4:	6605                	lui	a2,0x1
    800015c6:	4581                	li	a1,0
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	94a080e7          	jalr	-1718(ra) # 80000f12 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800015d0:	4779                	li	a4,30
    800015d2:	86ca                	mv	a3,s2
    800015d4:	6605                	lui	a2,0x1
    800015d6:	4581                	li	a1,0
    800015d8:	8552                	mv	a0,s4
    800015da:	00000097          	auipc	ra,0x0
    800015de:	d0c080e7          	jalr	-756(ra) # 800012e6 <mappages>
  memmove(mem, src, sz);
    800015e2:	8626                	mv	a2,s1
    800015e4:	85ce                	mv	a1,s3
    800015e6:	854a                	mv	a0,s2
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	98a080e7          	jalr	-1654(ra) # 80000f72 <memmove>
}
    800015f0:	70a2                	ld	ra,40(sp)
    800015f2:	7402                	ld	s0,32(sp)
    800015f4:	64e2                	ld	s1,24(sp)
    800015f6:	6942                	ld	s2,16(sp)
    800015f8:	69a2                	ld	s3,8(sp)
    800015fa:	6a02                	ld	s4,0(sp)
    800015fc:	6145                	addi	sp,sp,48
    800015fe:	8082                	ret
    panic("uvmfirst: more than a page");
    80001600:	00008517          	auipc	a0,0x8
    80001604:	b9050513          	addi	a0,a0,-1136 # 80009190 <digits+0x150>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f3c080e7          	jalr	-196(ra) # 80000544 <panic>

0000000080001610 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001610:	1101                	addi	sp,sp,-32
    80001612:	ec06                	sd	ra,24(sp)
    80001614:	e822                	sd	s0,16(sp)
    80001616:	e426                	sd	s1,8(sp)
    80001618:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000161a:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000161c:	00b67d63          	bgeu	a2,a1,80001636 <uvmdealloc+0x26>
    80001620:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001622:	6785                	lui	a5,0x1
    80001624:	17fd                	addi	a5,a5,-1
    80001626:	00f60733          	add	a4,a2,a5
    8000162a:	767d                	lui	a2,0xfffff
    8000162c:	8f71                	and	a4,a4,a2
    8000162e:	97ae                	add	a5,a5,a1
    80001630:	8ff1                	and	a5,a5,a2
    80001632:	00f76863          	bltu	a4,a5,80001642 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001636:	8526                	mv	a0,s1
    80001638:	60e2                	ld	ra,24(sp)
    8000163a:	6442                	ld	s0,16(sp)
    8000163c:	64a2                	ld	s1,8(sp)
    8000163e:	6105                	addi	sp,sp,32
    80001640:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001642:	8f99                	sub	a5,a5,a4
    80001644:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001646:	4685                	li	a3,1
    80001648:	0007861b          	sext.w	a2,a5
    8000164c:	85ba                	mv	a1,a4
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	e5e080e7          	jalr	-418(ra) # 800014ac <uvmunmap>
    80001656:	b7c5                	j	80001636 <uvmdealloc+0x26>

0000000080001658 <uvmalloc>:
  if (newsz < oldsz)
    80001658:	0ab66563          	bltu	a2,a1,80001702 <uvmalloc+0xaa>
{
    8000165c:	7139                	addi	sp,sp,-64
    8000165e:	fc06                	sd	ra,56(sp)
    80001660:	f822                	sd	s0,48(sp)
    80001662:	f426                	sd	s1,40(sp)
    80001664:	f04a                	sd	s2,32(sp)
    80001666:	ec4e                	sd	s3,24(sp)
    80001668:	e852                	sd	s4,16(sp)
    8000166a:	e456                	sd	s5,8(sp)
    8000166c:	e05a                	sd	s6,0(sp)
    8000166e:	0080                	addi	s0,sp,64
    80001670:	8aaa                	mv	s5,a0
    80001672:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001674:	6985                	lui	s3,0x1
    80001676:	19fd                	addi	s3,s3,-1
    80001678:	95ce                	add	a1,a1,s3
    8000167a:	79fd                	lui	s3,0xfffff
    8000167c:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001680:	08c9f363          	bgeu	s3,a2,80001706 <uvmalloc+0xae>
    80001684:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001686:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	690080e7          	jalr	1680(ra) # 80000d1a <kalloc>
    80001692:	84aa                	mv	s1,a0
    if (mem == 0)
    80001694:	c51d                	beqz	a0,800016c2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001696:	6605                	lui	a2,0x1
    80001698:	4581                	li	a1,0
    8000169a:	00000097          	auipc	ra,0x0
    8000169e:	878080e7          	jalr	-1928(ra) # 80000f12 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800016a2:	875a                	mv	a4,s6
    800016a4:	86a6                	mv	a3,s1
    800016a6:	6605                	lui	a2,0x1
    800016a8:	85ca                	mv	a1,s2
    800016aa:	8556                	mv	a0,s5
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	c3a080e7          	jalr	-966(ra) # 800012e6 <mappages>
    800016b4:	e90d                	bnez	a0,800016e6 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800016b6:	6785                	lui	a5,0x1
    800016b8:	993e                	add	s2,s2,a5
    800016ba:	fd4968e3          	bltu	s2,s4,8000168a <uvmalloc+0x32>
  return newsz;
    800016be:	8552                	mv	a0,s4
    800016c0:	a809                	j	800016d2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800016c2:	864e                	mv	a2,s3
    800016c4:	85ca                	mv	a1,s2
    800016c6:	8556                	mv	a0,s5
    800016c8:	00000097          	auipc	ra,0x0
    800016cc:	f48080e7          	jalr	-184(ra) # 80001610 <uvmdealloc>
      return 0;
    800016d0:	4501                	li	a0,0
}
    800016d2:	70e2                	ld	ra,56(sp)
    800016d4:	7442                	ld	s0,48(sp)
    800016d6:	74a2                	ld	s1,40(sp)
    800016d8:	7902                	ld	s2,32(sp)
    800016da:	69e2                	ld	s3,24(sp)
    800016dc:	6a42                	ld	s4,16(sp)
    800016de:	6aa2                	ld	s5,8(sp)
    800016e0:	6b02                	ld	s6,0(sp)
    800016e2:	6121                	addi	sp,sp,64
    800016e4:	8082                	ret
      kfree(mem);
    800016e6:	8526                	mv	a0,s1
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	4aa080e7          	jalr	1194(ra) # 80000b92 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016f0:	864e                	mv	a2,s3
    800016f2:	85ca                	mv	a1,s2
    800016f4:	8556                	mv	a0,s5
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	f1a080e7          	jalr	-230(ra) # 80001610 <uvmdealloc>
      return 0;
    800016fe:	4501                	li	a0,0
    80001700:	bfc9                	j	800016d2 <uvmalloc+0x7a>
    return oldsz;
    80001702:	852e                	mv	a0,a1
}
    80001704:	8082                	ret
  return newsz;
    80001706:	8532                	mv	a0,a2
    80001708:	b7e9                	j	800016d2 <uvmalloc+0x7a>

000000008000170a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    8000170a:	7179                	addi	sp,sp,-48
    8000170c:	f406                	sd	ra,40(sp)
    8000170e:	f022                	sd	s0,32(sp)
    80001710:	ec26                	sd	s1,24(sp)
    80001712:	e84a                	sd	s2,16(sp)
    80001714:	e44e                	sd	s3,8(sp)
    80001716:	e052                	sd	s4,0(sp)
    80001718:	1800                	addi	s0,sp,48
    8000171a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    8000171c:	84aa                	mv	s1,a0
    8000171e:	6905                	lui	s2,0x1
    80001720:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001722:	4985                	li	s3,1
    80001724:	a821                	j	8000173c <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001726:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001728:	0532                	slli	a0,a0,0xc
    8000172a:	00000097          	auipc	ra,0x0
    8000172e:	fe0080e7          	jalr	-32(ra) # 8000170a <freewalk>
      pagetable[i] = 0;
    80001732:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001736:	04a1                	addi	s1,s1,8
    80001738:	03248163          	beq	s1,s2,8000175a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000173c:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    8000173e:	00f57793          	andi	a5,a0,15
    80001742:	ff3782e3          	beq	a5,s3,80001726 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001746:	8905                	andi	a0,a0,1
    80001748:	d57d                	beqz	a0,80001736 <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    8000174a:	00008517          	auipc	a0,0x8
    8000174e:	a6650513          	addi	a0,a0,-1434 # 800091b0 <digits+0x170>
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	df2080e7          	jalr	-526(ra) # 80000544 <panic>
    }
  }
  kfree((void *)pagetable);
    8000175a:	8552                	mv	a0,s4
    8000175c:	fffff097          	auipc	ra,0xfffff
    80001760:	436080e7          	jalr	1078(ra) # 80000b92 <kfree>
}
    80001764:	70a2                	ld	ra,40(sp)
    80001766:	7402                	ld	s0,32(sp)
    80001768:	64e2                	ld	s1,24(sp)
    8000176a:	6942                	ld	s2,16(sp)
    8000176c:	69a2                	ld	s3,8(sp)
    8000176e:	6a02                	ld	s4,0(sp)
    80001770:	6145                	addi	sp,sp,48
    80001772:	8082                	ret

0000000080001774 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001774:	1101                	addi	sp,sp,-32
    80001776:	ec06                	sd	ra,24(sp)
    80001778:	e822                	sd	s0,16(sp)
    8000177a:	e426                	sd	s1,8(sp)
    8000177c:	1000                	addi	s0,sp,32
    8000177e:	84aa                	mv	s1,a0
  if (sz > 0)
    80001780:	e999                	bnez	a1,80001796 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001782:	8526                	mv	a0,s1
    80001784:	00000097          	auipc	ra,0x0
    80001788:	f86080e7          	jalr	-122(ra) # 8000170a <freewalk>
}
    8000178c:	60e2                	ld	ra,24(sp)
    8000178e:	6442                	ld	s0,16(sp)
    80001790:	64a2                	ld	s1,8(sp)
    80001792:	6105                	addi	sp,sp,32
    80001794:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    80001796:	6605                	lui	a2,0x1
    80001798:	167d                	addi	a2,a2,-1
    8000179a:	962e                	add	a2,a2,a1
    8000179c:	4685                	li	a3,1
    8000179e:	8231                	srli	a2,a2,0xc
    800017a0:	4581                	li	a1,0
    800017a2:	00000097          	auipc	ra,0x0
    800017a6:	d0a080e7          	jalr	-758(ra) # 800014ac <uvmunmap>
    800017aa:	bfe1                	j	80001782 <uvmfree+0xe>

00000000800017ac <uvmcopy>:
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800017ac:	715d                	addi	sp,sp,-80
    800017ae:	e486                	sd	ra,72(sp)
    800017b0:	e0a2                	sd	s0,64(sp)
    800017b2:	fc26                	sd	s1,56(sp)
    800017b4:	f84a                	sd	s2,48(sp)
    800017b6:	f44e                	sd	s3,40(sp)
    800017b8:	f052                	sd	s4,32(sp)
    800017ba:	ec56                	sd	s5,24(sp)
    800017bc:	e85a                	sd	s6,16(sp)
    800017be:	e45e                	sd	s7,8(sp)
    800017c0:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE)
    800017c2:	c271                	beqz	a2,80001886 <uvmcopy+0xda>
    800017c4:	8aaa                	mv	s5,a0
    800017c6:	8a2e                	mv	s4,a1
    800017c8:	89b2                	mv	s3,a2
    800017ca:	4901                	li	s2,0
      panic("uvmcopy: page not present");
    flags = PTE_FLAGS(*pte);
    if (flags & PTE_W)
    {
      flags = PTE_C | (flags & (~PTE_W));
      *pte = PA2PTE(PTE2PA(*pte)) | flags;
    800017cc:	7b7d                	lui	s6,0xfffff
    800017ce:	002b5b13          	srli	s6,s6,0x2
    800017d2:	a881                	j	80001822 <uvmcopy+0x76>
      panic("uvmcopy: pte should exist");
    800017d4:	00008517          	auipc	a0,0x8
    800017d8:	9ec50513          	addi	a0,a0,-1556 # 800091c0 <digits+0x180>
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	d68080e7          	jalr	-664(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    800017e4:	00008517          	auipc	a0,0x8
    800017e8:	9fc50513          	addi	a0,a0,-1540 # 800091e0 <digits+0x1a0>
    800017ec:	fffff097          	auipc	ra,0xfffff
    800017f0:	d58080e7          	jalr	-680(ra) # 80000544 <panic>
    }
    if (mappages(new, i, PGSIZE, PTE2PA(*pte), flags) != 0)
    800017f4:	6094                	ld	a3,0(s1)
    800017f6:	82a9                	srli	a3,a3,0xa
    800017f8:	06b2                	slli	a3,a3,0xc
    800017fa:	6605                	lui	a2,0x1
    800017fc:	85ca                	mv	a1,s2
    800017fe:	8552                	mv	a0,s4
    80001800:	00000097          	auipc	ra,0x0
    80001804:	ae6080e7          	jalr	-1306(ra) # 800012e6 <mappages>
    80001808:	8baa                	mv	s7,a0
    8000180a:	e921                	bnez	a0,8000185a <uvmcopy+0xae>
    {
      goto err;
    }
    increment_page((void *)PTE2PA(*pte));
    8000180c:	6088                	ld	a0,0(s1)
    8000180e:	8129                	srli	a0,a0,0xa
    80001810:	0532                	slli	a0,a0,0xc
    80001812:	fffff097          	auipc	ra,0xfffff
    80001816:	2ac080e7          	jalr	684(ra) # 80000abe <increment_page>
  for (i = 0; i < sz; i += PGSIZE)
    8000181a:	6785                	lui	a5,0x1
    8000181c:	993e                	add	s2,s2,a5
    8000181e:	05397863          	bgeu	s2,s3,8000186e <uvmcopy+0xc2>
    if ((pte = walk(old, i, 0)) == 0)
    80001822:	4601                	li	a2,0
    80001824:	85ca                	mv	a1,s2
    80001826:	8556                	mv	a0,s5
    80001828:	00000097          	auipc	ra,0x0
    8000182c:	9d6080e7          	jalr	-1578(ra) # 800011fe <walk>
    80001830:	84aa                	mv	s1,a0
    80001832:	d14d                	beqz	a0,800017d4 <uvmcopy+0x28>
    if ((*pte & PTE_V) == 0)
    80001834:	611c                	ld	a5,0(a0)
    80001836:	0017f713          	andi	a4,a5,1
    8000183a:	d74d                	beqz	a4,800017e4 <uvmcopy+0x38>
    flags = PTE_FLAGS(*pte);
    8000183c:	0007869b          	sext.w	a3,a5
    80001840:	3ff7f713          	andi	a4,a5,1023
    if (flags & PTE_W)
    80001844:	8a91                	andi	a3,a3,4
    80001846:	d6dd                	beqz	a3,800017f4 <uvmcopy+0x48>
      flags = PTE_C | (flags & (~PTE_W));
    80001848:	efb77693          	andi	a3,a4,-261
    8000184c:	1006e713          	ori	a4,a3,256
      *pte = PA2PTE(PTE2PA(*pte)) | flags;
    80001850:	0167f7b3          	and	a5,a5,s6
    80001854:	8fd9                	or	a5,a5,a4
    80001856:	e11c                	sd	a5,0(a0)
    80001858:	bf71                	j	800017f4 <uvmcopy+0x48>
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000185a:	4685                	li	a3,1
    8000185c:	00c95613          	srli	a2,s2,0xc
    80001860:	4581                	li	a1,0
    80001862:	8552                	mv	a0,s4
    80001864:	00000097          	auipc	ra,0x0
    80001868:	c48080e7          	jalr	-952(ra) # 800014ac <uvmunmap>
  return -1;
    8000186c:	5bfd                	li	s7,-1
}
    8000186e:	855e                	mv	a0,s7
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6161                	addi	sp,sp,80
    80001884:	8082                	ret
  return 0;
    80001886:	4b81                	li	s7,0
    80001888:	b7dd                	j	8000186e <uvmcopy+0xc2>

000000008000188a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    8000188a:	1141                	addi	sp,sp,-16
    8000188c:	e406                	sd	ra,8(sp)
    8000188e:	e022                	sd	s0,0(sp)
    80001890:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001892:	4601                	li	a2,0
    80001894:	00000097          	auipc	ra,0x0
    80001898:	96a080e7          	jalr	-1686(ra) # 800011fe <walk>
  if (pte == 0)
    8000189c:	c901                	beqz	a0,800018ac <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000189e:	611c                	ld	a5,0(a0)
    800018a0:	9bbd                	andi	a5,a5,-17
    800018a2:	e11c                	sd	a5,0(a0)
}
    800018a4:	60a2                	ld	ra,8(sp)
    800018a6:	6402                	ld	s0,0(sp)
    800018a8:	0141                	addi	sp,sp,16
    800018aa:	8082                	ret
    panic("uvmclear");
    800018ac:	00008517          	auipc	a0,0x8
    800018b0:	95450513          	addi	a0,a0,-1708 # 80009200 <digits+0x1c0>
    800018b4:	fffff097          	auipc	ra,0xfffff
    800018b8:	c90080e7          	jalr	-880(ra) # 80000544 <panic>

00000000800018bc <copyout>:
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0, flags;
  pte_t *pte;

  while (len > 0)
    800018bc:	c2d5                	beqz	a3,80001960 <copyout+0xa4>
{
    800018be:	711d                	addi	sp,sp,-96
    800018c0:	ec86                	sd	ra,88(sp)
    800018c2:	e8a2                	sd	s0,80(sp)
    800018c4:	e4a6                	sd	s1,72(sp)
    800018c6:	e0ca                	sd	s2,64(sp)
    800018c8:	fc4e                	sd	s3,56(sp)
    800018ca:	f852                	sd	s4,48(sp)
    800018cc:	f456                	sd	s5,40(sp)
    800018ce:	f05a                	sd	s6,32(sp)
    800018d0:	ec5e                	sd	s7,24(sp)
    800018d2:	e862                	sd	s8,16(sp)
    800018d4:	e466                	sd	s9,8(sp)
    800018d6:	1080                	addi	s0,sp,96
    800018d8:	8baa                	mv	s7,a0
    800018da:	89ae                	mv	s3,a1
    800018dc:	8b32                	mv	s6,a2
    800018de:	8ab6                	mv	s5,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800018e0:	7cfd                	lui	s9,0xfffff
      if (flags & PTE_C)
      {
        handle_page((void *)va0, pagetable);
        pa0 = walkaddr(pagetable, va0);
      }
      n = PGSIZE + va0 - dstva;
    800018e2:	6c05                	lui	s8,0x1
    800018e4:	a081                	j	80001924 <copyout+0x68>
        handle_page((void *)va0, pagetable);
    800018e6:	85de                	mv	a1,s7
    800018e8:	854a                	mv	a0,s2
    800018ea:	00002097          	auipc	ra,0x2
    800018ee:	a68080e7          	jalr	-1432(ra) # 80003352 <handle_page>
        pa0 = walkaddr(pagetable, va0);
    800018f2:	85ca                	mv	a1,s2
    800018f4:	855e                	mv	a0,s7
    800018f6:	00000097          	auipc	ra,0x0
    800018fa:	9ae080e7          	jalr	-1618(ra) # 800012a4 <walkaddr>
    800018fe:	8a2a                	mv	s4,a0
    80001900:	a0b9                	j	8000194e <copyout+0x92>
      if (n >= len)
      {
        n = len;
      }
      memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001902:	41298533          	sub	a0,s3,s2
    80001906:	0004861b          	sext.w	a2,s1
    8000190a:	85da                	mv	a1,s6
    8000190c:	9552                	add	a0,a0,s4
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	664080e7          	jalr	1636(ra) # 80000f72 <memmove>
      src += n;
    80001916:	9b26                	add	s6,s6,s1
      len -= n;
    80001918:	409a8ab3          	sub	s5,s5,s1
      dstva = va0 + PGSIZE;
    8000191c:	018909b3          	add	s3,s2,s8
  while (len > 0)
    80001920:	020a8e63          	beqz	s5,8000195c <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    80001924:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001928:	85ca                	mv	a1,s2
    8000192a:	855e                	mv	a0,s7
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	978080e7          	jalr	-1672(ra) # 800012a4 <walkaddr>
    80001934:	8a2a                	mv	s4,a0
    if (pa0)
    80001936:	c51d                	beqz	a0,80001964 <copyout+0xa8>
      pte = walk(pagetable, va0, 0);
    80001938:	4601                	li	a2,0
    8000193a:	85ca                	mv	a1,s2
    8000193c:	855e                	mv	a0,s7
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	8c0080e7          	jalr	-1856(ra) # 800011fe <walk>
      if (flags & PTE_C)
    80001946:	611c                	ld	a5,0(a0)
    80001948:	1007f793          	andi	a5,a5,256
    8000194c:	ffc9                	bnez	a5,800018e6 <copyout+0x2a>
      n = PGSIZE + va0 - dstva;
    8000194e:	413904b3          	sub	s1,s2,s3
    80001952:	94e2                	add	s1,s1,s8
      if (n >= len)
    80001954:	fa9af7e3          	bgeu	s5,s1,80001902 <copyout+0x46>
    80001958:	84d6                	mv	s1,s5
    8000195a:	b765                	j	80001902 <copyout+0x46>
    else
    {
      return -1;
    }
  }
  return 0;
    8000195c:	4501                	li	a0,0
    8000195e:	a021                	j	80001966 <copyout+0xaa>
    80001960:	4501                	li	a0,0
}
    80001962:	8082                	ret
      return -1;
    80001964:	557d                	li	a0,-1
}
    80001966:	60e6                	ld	ra,88(sp)
    80001968:	6446                	ld	s0,80(sp)
    8000196a:	64a6                	ld	s1,72(sp)
    8000196c:	6906                	ld	s2,64(sp)
    8000196e:	79e2                	ld	s3,56(sp)
    80001970:	7a42                	ld	s4,48(sp)
    80001972:	7aa2                	ld	s5,40(sp)
    80001974:	7b02                	ld	s6,32(sp)
    80001976:	6be2                	ld	s7,24(sp)
    80001978:	6c42                	ld	s8,16(sp)
    8000197a:	6ca2                	ld	s9,8(sp)
    8000197c:	6125                	addi	sp,sp,96
    8000197e:	8082                	ret

0000000080001980 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001980:	c6bd                	beqz	a3,800019ee <copyin+0x6e>
{
    80001982:	715d                	addi	sp,sp,-80
    80001984:	e486                	sd	ra,72(sp)
    80001986:	e0a2                	sd	s0,64(sp)
    80001988:	fc26                	sd	s1,56(sp)
    8000198a:	f84a                	sd	s2,48(sp)
    8000198c:	f44e                	sd	s3,40(sp)
    8000198e:	f052                	sd	s4,32(sp)
    80001990:	ec56                	sd	s5,24(sp)
    80001992:	e85a                	sd	s6,16(sp)
    80001994:	e45e                	sd	s7,8(sp)
    80001996:	e062                	sd	s8,0(sp)
    80001998:	0880                	addi	s0,sp,80
    8000199a:	8b2a                	mv	s6,a0
    8000199c:	8a2e                	mv	s4,a1
    8000199e:	8c32                	mv	s8,a2
    800019a0:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800019a2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019a4:	6a85                	lui	s5,0x1
    800019a6:	a015                	j	800019ca <copyin+0x4a>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800019a8:	9562                	add	a0,a0,s8
    800019aa:	0004861b          	sext.w	a2,s1
    800019ae:	412505b3          	sub	a1,a0,s2
    800019b2:	8552                	mv	a0,s4
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	5be080e7          	jalr	1470(ra) # 80000f72 <memmove>

    len -= n;
    800019bc:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019c0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019c2:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800019c6:	02098263          	beqz	s3,800019ea <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800019ca:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019ce:	85ca                	mv	a1,s2
    800019d0:	855a                	mv	a0,s6
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	8d2080e7          	jalr	-1838(ra) # 800012a4 <walkaddr>
    if (pa0 == 0)
    800019da:	cd01                	beqz	a0,800019f2 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800019dc:	418904b3          	sub	s1,s2,s8
    800019e0:	94d6                	add	s1,s1,s5
    if (n > len)
    800019e2:	fc99f3e3          	bgeu	s3,s1,800019a8 <copyin+0x28>
    800019e6:	84ce                	mv	s1,s3
    800019e8:	b7c1                	j	800019a8 <copyin+0x28>
  }
  return 0;
    800019ea:	4501                	li	a0,0
    800019ec:	a021                	j	800019f4 <copyin+0x74>
    800019ee:	4501                	li	a0,0
}
    800019f0:	8082                	ret
      return -1;
    800019f2:	557d                	li	a0,-1
}
    800019f4:	60a6                	ld	ra,72(sp)
    800019f6:	6406                	ld	s0,64(sp)
    800019f8:	74e2                	ld	s1,56(sp)
    800019fa:	7942                	ld	s2,48(sp)
    800019fc:	79a2                	ld	s3,40(sp)
    800019fe:	7a02                	ld	s4,32(sp)
    80001a00:	6ae2                	ld	s5,24(sp)
    80001a02:	6b42                	ld	s6,16(sp)
    80001a04:	6ba2                	ld	s7,8(sp)
    80001a06:	6c02                	ld	s8,0(sp)
    80001a08:	6161                	addi	sp,sp,80
    80001a0a:	8082                	ret

0000000080001a0c <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001a0c:	c6c5                	beqz	a3,80001ab4 <copyinstr+0xa8>
{
    80001a0e:	715d                	addi	sp,sp,-80
    80001a10:	e486                	sd	ra,72(sp)
    80001a12:	e0a2                	sd	s0,64(sp)
    80001a14:	fc26                	sd	s1,56(sp)
    80001a16:	f84a                	sd	s2,48(sp)
    80001a18:	f44e                	sd	s3,40(sp)
    80001a1a:	f052                	sd	s4,32(sp)
    80001a1c:	ec56                	sd	s5,24(sp)
    80001a1e:	e85a                	sd	s6,16(sp)
    80001a20:	e45e                	sd	s7,8(sp)
    80001a22:	0880                	addi	s0,sp,80
    80001a24:	8a2a                	mv	s4,a0
    80001a26:	8b2e                	mv	s6,a1
    80001a28:	8bb2                	mv	s7,a2
    80001a2a:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001a2c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a2e:	6985                	lui	s3,0x1
    80001a30:	a035                	j	80001a5c <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001a32:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a36:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001a38:	0017b793          	seqz	a5,a5
    80001a3c:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001a40:	60a6                	ld	ra,72(sp)
    80001a42:	6406                	ld	s0,64(sp)
    80001a44:	74e2                	ld	s1,56(sp)
    80001a46:	7942                	ld	s2,48(sp)
    80001a48:	79a2                	ld	s3,40(sp)
    80001a4a:	7a02                	ld	s4,32(sp)
    80001a4c:	6ae2                	ld	s5,24(sp)
    80001a4e:	6b42                	ld	s6,16(sp)
    80001a50:	6ba2                	ld	s7,8(sp)
    80001a52:	6161                	addi	sp,sp,80
    80001a54:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a56:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001a5a:	c8a9                	beqz	s1,80001aac <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001a5c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a60:	85ca                	mv	a1,s2
    80001a62:	8552                	mv	a0,s4
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	840080e7          	jalr	-1984(ra) # 800012a4 <walkaddr>
    if (pa0 == 0)
    80001a6c:	c131                	beqz	a0,80001ab0 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001a6e:	41790833          	sub	a6,s2,s7
    80001a72:	984e                	add	a6,a6,s3
    if (n > max)
    80001a74:	0104f363          	bgeu	s1,a6,80001a7a <copyinstr+0x6e>
    80001a78:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001a7a:	955e                	add	a0,a0,s7
    80001a7c:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001a80:	fc080be3          	beqz	a6,80001a56 <copyinstr+0x4a>
    80001a84:	985a                	add	a6,a6,s6
    80001a86:	87da                	mv	a5,s6
      if (*p == '\0')
    80001a88:	41650633          	sub	a2,a0,s6
    80001a8c:	14fd                	addi	s1,s1,-1
    80001a8e:	9b26                	add	s6,s6,s1
    80001a90:	00f60733          	add	a4,a2,a5
    80001a94:	00074703          	lbu	a4,0(a4)
    80001a98:	df49                	beqz	a4,80001a32 <copyinstr+0x26>
        *dst = *p;
    80001a9a:	00e78023          	sb	a4,0(a5)
      --max;
    80001a9e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001aa2:	0785                	addi	a5,a5,1
    while (n > 0)
    80001aa4:	ff0796e3          	bne	a5,a6,80001a90 <copyinstr+0x84>
      dst++;
    80001aa8:	8b42                	mv	s6,a6
    80001aaa:	b775                	j	80001a56 <copyinstr+0x4a>
    80001aac:	4781                	li	a5,0
    80001aae:	b769                	j	80001a38 <copyinstr+0x2c>
      return -1;
    80001ab0:	557d                	li	a0,-1
    80001ab2:	b779                	j	80001a40 <copyinstr+0x34>
  int got_null = 0;
    80001ab4:	4781                	li	a5,0
  if (got_null)
    80001ab6:	0017b793          	seqz	a5,a5
    80001aba:	40f00533          	neg	a0,a5
}
    80001abe:	8082                	ret

0000000080001ac0 <Create_Queue>:
#include "proc.h"
#include "defs.h"
#include <stddef.h>

queue Create_Queue()
{
    80001ac0:	1141                	addi	sp,sp,-16
    80001ac2:	e422                	sd	s0,8(sp)
    80001ac4:	0800                	addi	s0,sp,16
  queue qu;
  qu.front = 0;
  qu.rear = 0;
  qu.numitems = 0;
  return qu;
    80001ac6:	00052223          	sw	zero,4(a0)
    80001aca:	00052423          	sw	zero,8(a0)
    80001ace:	20052c23          	sw	zero,536(a0)
}
    80001ad2:	6422                	ld	s0,8(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret

0000000080001ad8 <enqueue>:

void enqueue(queue *qu, queue_element el)
{
    80001ad8:	1141                	addi	sp,sp,-16
    80001ada:	e406                	sd	ra,8(sp)
    80001adc:	e022                	sd	s0,0(sp)
    80001ade:	0800                	addi	s0,sp,16
  qu->arr[qu->rear] = el;
    80001ae0:	451c                	lw	a5,8(a0)
    80001ae2:	00278713          	addi	a4,a5,2
    80001ae6:	070e                	slli	a4,a4,0x3
    80001ae8:	972a                	add	a4,a4,a0
    80001aea:	e30c                	sd	a1,0(a4)
  qu->rear = (qu->rear + 1) % 64;
    80001aec:	2785                	addiw	a5,a5,1
    80001aee:	41f7d71b          	sraiw	a4,a5,0x1f
    80001af2:	01a7571b          	srliw	a4,a4,0x1a
    80001af6:	9fb9                	addw	a5,a5,a4
    80001af8:	03f7f793          	andi	a5,a5,63
    80001afc:	9f99                	subw	a5,a5,a4
    80001afe:	c51c                	sw	a5,8(a0)
  qu->numitems++;
    80001b00:	21852783          	lw	a5,536(a0)
    80001b04:	2785                	addiw	a5,a5,1
    80001b06:	20f52c23          	sw	a5,536(a0)
  // if (el->pid > 9)
    printf("%d %d %d\n", ticks, el->pid, el->mlfq_priority);
    80001b0a:	1d05b683          	ld	a3,464(a1) # 40001d0 <_entry-0x7bfffe30>
    80001b0e:	5990                	lw	a2,48(a1)
    80001b10:	00008597          	auipc	a1,0x8
    80001b14:	1205a583          	lw	a1,288(a1) # 80009c30 <ticks>
    80001b18:	00007517          	auipc	a0,0x7
    80001b1c:	7e850513          	addi	a0,a0,2024 # 80009300 <digits+0x2c0>
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	a6e080e7          	jalr	-1426(ra) # 8000058e <printf>
  return;
}
    80001b28:	60a2                	ld	ra,8(sp)
    80001b2a:	6402                	ld	s0,0(sp)
    80001b2c:	0141                	addi	sp,sp,16
    80001b2e:	8082                	ret

0000000080001b30 <dequeue>:

void dequeue(queue *qu)
{
    80001b30:	1141                	addi	sp,sp,-16
    80001b32:	e422                	sd	s0,8(sp)
    80001b34:	0800                	addi	s0,sp,16
  if (!qu->numitems)
    80001b36:	21852783          	lw	a5,536(a0)
    80001b3a:	cf99                	beqz	a5,80001b58 <dequeue+0x28>
    return;
  qu->numitems--;
    80001b3c:	37fd                	addiw	a5,a5,-1
    80001b3e:	20f52c23          	sw	a5,536(a0)
  qu->front = (qu->front + 1) % 64;
    80001b42:	415c                	lw	a5,4(a0)
    80001b44:	2785                	addiw	a5,a5,1
    80001b46:	41f7d71b          	sraiw	a4,a5,0x1f
    80001b4a:	01a7571b          	srliw	a4,a4,0x1a
    80001b4e:	9fb9                	addw	a5,a5,a4
    80001b50:	03f7f793          	andi	a5,a5,63
    80001b54:	9f99                	subw	a5,a5,a4
    80001b56:	c15c                	sw	a5,4(a0)
}
    80001b58:	6422                	ld	s0,8(sp)
    80001b5a:	0141                	addi	sp,sp,16
    80001b5c:	8082                	ret

0000000080001b5e <isempty>:

int isempty(queue qu)
{
    80001b5e:	1141                	addi	sp,sp,-16
    80001b60:	e422                	sd	s0,8(sp)
    80001b62:	0800                	addi	s0,sp,16
  return (qu.numitems == 0);
    80001b64:	21852503          	lw	a0,536(a0)
}
    80001b68:	00153513          	seqz	a0,a0
    80001b6c:	6422                	ld	s0,8(sp)
    80001b6e:	0141                	addi	sp,sp,16
    80001b70:	8082                	ret

0000000080001b72 <front>:

queue_element front(queue qu)
{
    80001b72:	1141                	addi	sp,sp,-16
    80001b74:	e422                	sd	s0,8(sp)
    80001b76:	0800                	addi	s0,sp,16
  return qu.arr[qu.front];
    80001b78:	415c                	lw	a5,4(a0)
    80001b7a:	0789                	addi	a5,a5,2
    80001b7c:	078e                	slli	a5,a5,0x3
    80001b7e:	953e                	add	a0,a0,a5
}
    80001b80:	6108                	ld	a0,0(a0)
    80001b82:	6422                	ld	s0,8(sp)
    80001b84:	0141                	addi	sp,sp,16
    80001b86:	8082                	ret

0000000080001b88 <max>:

int max(int a, int b)
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  return a > b ? a : b;
    80001b8e:	87ae                	mv	a5,a1
    80001b90:	00a5d363          	bge	a1,a0,80001b96 <max+0xe>
    80001b94:	87aa                	mv	a5,a0
}
    80001b96:	0007851b          	sext.w	a0,a5
    80001b9a:	6422                	ld	s0,8(sp)
    80001b9c:	0141                	addi	sp,sp,16
    80001b9e:	8082                	ret

0000000080001ba0 <min>:

int min(int a, int b)
{
    80001ba0:	1141                	addi	sp,sp,-16
    80001ba2:	e422                	sd	s0,8(sp)
    80001ba4:	0800                	addi	s0,sp,16
  return a < b ? a : b;
    80001ba6:	87ae                	mv	a5,a1
    80001ba8:	00b55363          	bge	a0,a1,80001bae <min+0xe>
    80001bac:	87aa                	mv	a5,a0
}
    80001bae:	0007851b          	sext.w	a0,a5
    80001bb2:	6422                	ld	s0,8(sp)
    80001bb4:	0141                	addi	sp,sp,16
    80001bb6:	8082                	ret

0000000080001bb8 <random>:

queue mlfq[5];

uint random(void)
{
    80001bb8:	1141                	addi	sp,sp,-16
    80001bba:	e422                	sd	s0,8(sp)
    80001bbc:	0800                	addi	s0,sp,16
  // Take from http://stackoverflow.com/questions/1167253/implementation-of-rand
  static unsigned int z1 = 12345, z2 = 12345, z3 = 12345, z4 = 12345;
  unsigned int b;
  b = ((z1 << 6) ^ z1) >> 13;
    80001bbe:	00008717          	auipc	a4,0x8
    80001bc2:	ea270713          	addi	a4,a4,-350 # 80009a60 <z1.1642>
    80001bc6:	431c                	lw	a5,0(a4)
    80001bc8:	0067961b          	slliw	a2,a5,0x6
    80001bcc:	8e3d                	xor	a2,a2,a5
    80001bce:	00d6569b          	srliw	a3,a2,0xd
  z1 = ((z1 & 4294967294U) << 18) ^ b;
    80001bd2:	0127961b          	slliw	a2,a5,0x12
    80001bd6:	fff807b7          	lui	a5,0xfff80
    80001bda:	8e7d                	and	a2,a2,a5
    80001bdc:	8e35                	xor	a2,a2,a3
    80001bde:	2601                	sext.w	a2,a2
    80001be0:	c310                	sw	a2,0(a4)
  b = ((z2 << 2) ^ z2) >> 27;
    80001be2:	00008597          	auipc	a1,0x8
    80001be6:	e7a58593          	addi	a1,a1,-390 # 80009a5c <z2.1643>
    80001bea:	4194                	lw	a3,0(a1)
    80001bec:	0026979b          	slliw	a5,a3,0x2
    80001bf0:	8ebd                	xor	a3,a3,a5
    80001bf2:	01b6d71b          	srliw	a4,a3,0x1b
  z2 = ((z2 & 4294967288U) << 2) ^ b;
    80001bf6:	fe07f693          	andi	a3,a5,-32
    80001bfa:	8eb9                	xor	a3,a3,a4
    80001bfc:	2681                	sext.w	a3,a3
    80001bfe:	c194                	sw	a3,0(a1)
  b = ((z3 << 13) ^ z3) >> 21;
    80001c00:	00008597          	auipc	a1,0x8
    80001c04:	e5858593          	addi	a1,a1,-424 # 80009a58 <z3.1644>
    80001c08:	419c                	lw	a5,0(a1)
    80001c0a:	00d7971b          	slliw	a4,a5,0xd
    80001c0e:	8f3d                	xor	a4,a4,a5
    80001c10:	0157551b          	srliw	a0,a4,0x15
  z3 = ((z3 & 4294967280U) << 7) ^ b;
    80001c14:	0077971b          	slliw	a4,a5,0x7
    80001c18:	80077713          	andi	a4,a4,-2048
    80001c1c:	8f29                	xor	a4,a4,a0
    80001c1e:	2701                	sext.w	a4,a4
    80001c20:	c198                	sw	a4,0(a1)
  b = ((z4 << 3) ^ z4) >> 12;
    80001c22:	00008817          	auipc	a6,0x8
    80001c26:	e3280813          	addi	a6,a6,-462 # 80009a54 <z4.1645>
    80001c2a:	00082783          	lw	a5,0(a6)
    80001c2e:	0037951b          	slliw	a0,a5,0x3
    80001c32:	8d3d                	xor	a0,a0,a5
    80001c34:	00c5559b          	srliw	a1,a0,0xc
  z4 = ((z4 & 4294967168U) << 13) ^ b;
    80001c38:	00d7951b          	slliw	a0,a5,0xd
    80001c3c:	fff007b7          	lui	a5,0xfff00
    80001c40:	8d7d                	and	a0,a0,a5
    80001c42:	8d2d                	xor	a0,a0,a1
    80001c44:	2501                	sext.w	a0,a0
    80001c46:	00a82023          	sw	a0,0(a6)

  return (z1 ^ z2 ^ z3 ^ z4) / 2;
    80001c4a:	8eb1                	xor	a3,a3,a2
    80001c4c:	8f35                	xor	a4,a4,a3
    80001c4e:	8d39                	xor	a0,a0,a4
}
    80001c50:	0015551b          	srliw	a0,a0,0x1
    80001c54:	6422                	ld	s0,8(sp)
    80001c56:	0141                	addi	sp,sp,16
    80001c58:	8082                	ret

0000000080001c5a <randomrange>:

int randomrange(int lo, int hi)
{
    80001c5a:	1101                	addi	sp,sp,-32
    80001c5c:	ec06                	sd	ra,24(sp)
    80001c5e:	e822                	sd	s0,16(sp)
    80001c60:	e426                	sd	s1,8(sp)
    80001c62:	e04a                	sd	s2,0(sp)
    80001c64:	1000                	addi	s0,sp,32
    80001c66:	892a                	mv	s2,a0
    80001c68:	84ae                	mv	s1,a1
  int range = hi - lo + 1;
  return random() % (range) + lo;
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f4e080e7          	jalr	-178(ra) # 80001bb8 <random>
  int range = hi - lo + 1;
    80001c72:	412484bb          	subw	s1,s1,s2
    80001c76:	2485                	addiw	s1,s1,1
  return random() % (range) + lo;
    80001c78:	0295753b          	remuw	a0,a0,s1
}
    80001c7c:	0125053b          	addw	a0,a0,s2
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret

0000000080001c8c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001c8c:	7139                	addi	sp,sp,-64
    80001c8e:	fc06                	sd	ra,56(sp)
    80001c90:	f822                	sd	s0,48(sp)
    80001c92:	f426                	sd	s1,40(sp)
    80001c94:	f04a                	sd	s2,32(sp)
    80001c96:	ec4e                	sd	s3,24(sp)
    80001c98:	e852                	sd	s4,16(sp)
    80001c9a:	e456                	sd	s5,8(sp)
    80001c9c:	e05a                	sd	s6,0(sp)
    80001c9e:	0080                	addi	s0,sp,64
    80001ca0:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001ca2:	00230497          	auipc	s1,0x230
    80001ca6:	64648493          	addi	s1,s1,1606 # 802322e8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001caa:	8b26                	mv	s6,s1
    80001cac:	00007a97          	auipc	s5,0x7
    80001cb0:	354a8a93          	addi	s5,s5,852 # 80009000 <etext>
    80001cb4:	04000937          	lui	s2,0x4000
    80001cb8:	197d                	addi	s2,s2,-1
    80001cba:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001cbc:	0023aa17          	auipc	s4,0x23a
    80001cc0:	82ca0a13          	addi	s4,s4,-2004 # 8023b4e8 <mlfq>
    char *pa = kalloc();
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	056080e7          	jalr	86(ra) # 80000d1a <kalloc>
    80001ccc:	862a                	mv	a2,a0
    if (pa == 0)
    80001cce:	c131                	beqz	a0,80001d12 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001cd0:	416485b3          	sub	a1,s1,s6
    80001cd4:	858d                	srai	a1,a1,0x3
    80001cd6:	000ab783          	ld	a5,0(s5)
    80001cda:	02f585b3          	mul	a1,a1,a5
    80001cde:	2585                	addiw	a1,a1,1
    80001ce0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ce4:	4719                	li	a4,6
    80001ce6:	6685                	lui	a3,0x1
    80001ce8:	40b905b3          	sub	a1,s2,a1
    80001cec:	854e                	mv	a0,s3
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	698080e7          	jalr	1688(ra) # 80001386 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cf6:	24848493          	addi	s1,s1,584
    80001cfa:	fd4495e3          	bne	s1,s4,80001cc4 <proc_mapstacks+0x38>
  }
}
    80001cfe:	70e2                	ld	ra,56(sp)
    80001d00:	7442                	ld	s0,48(sp)
    80001d02:	74a2                	ld	s1,40(sp)
    80001d04:	7902                	ld	s2,32(sp)
    80001d06:	69e2                	ld	s3,24(sp)
    80001d08:	6a42                	ld	s4,16(sp)
    80001d0a:	6aa2                	ld	s5,8(sp)
    80001d0c:	6b02                	ld	s6,0(sp)
    80001d0e:	6121                	addi	sp,sp,64
    80001d10:	8082                	ret
      panic("kalloc");
    80001d12:	00007517          	auipc	a0,0x7
    80001d16:	4fe50513          	addi	a0,a0,1278 # 80009210 <digits+0x1d0>
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	82a080e7          	jalr	-2006(ra) # 80000544 <panic>

0000000080001d22 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001d22:	7139                	addi	sp,sp,-64
    80001d24:	fc06                	sd	ra,56(sp)
    80001d26:	f822                	sd	s0,48(sp)
    80001d28:	f426                	sd	s1,40(sp)
    80001d2a:	f04a                	sd	s2,32(sp)
    80001d2c:	ec4e                	sd	s3,24(sp)
    80001d2e:	e852                	sd	s4,16(sp)
    80001d30:	e456                	sd	s5,8(sp)
    80001d32:	e05a                	sd	s6,0(sp)
    80001d34:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001d36:	00007597          	auipc	a1,0x7
    80001d3a:	4e258593          	addi	a1,a1,1250 # 80009218 <digits+0x1d8>
    80001d3e:	00230517          	auipc	a0,0x230
    80001d42:	17a50513          	addi	a0,a0,378 # 80231eb8 <pid_lock>
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	040080e7          	jalr	64(ra) # 80000d86 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d4e:	00007597          	auipc	a1,0x7
    80001d52:	4d258593          	addi	a1,a1,1234 # 80009220 <digits+0x1e0>
    80001d56:	00230517          	auipc	a0,0x230
    80001d5a:	17a50513          	addi	a0,a0,378 # 80231ed0 <wait_lock>
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	028080e7          	jalr	40(ra) # 80000d86 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d66:	00230497          	auipc	s1,0x230
    80001d6a:	58248493          	addi	s1,s1,1410 # 802322e8 <proc>
  {
    initlock(&p->lock, "proc");
    80001d6e:	00007b17          	auipc	s6,0x7
    80001d72:	4c2b0b13          	addi	s6,s6,1218 # 80009230 <digits+0x1f0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001d76:	8aa6                	mv	s5,s1
    80001d78:	00007a17          	auipc	s4,0x7
    80001d7c:	288a0a13          	addi	s4,s4,648 # 80009000 <etext>
    80001d80:	04000937          	lui	s2,0x4000
    80001d84:	197d                	addi	s2,s2,-1
    80001d86:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001d88:	00239997          	auipc	s3,0x239
    80001d8c:	76098993          	addi	s3,s3,1888 # 8023b4e8 <mlfq>
    initlock(&p->lock, "proc");
    80001d90:	85da                	mv	a1,s6
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	ff2080e7          	jalr	-14(ra) # 80000d86 <initlock>
    p->state = UNUSED;
    80001d9c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001da0:	415487b3          	sub	a5,s1,s5
    80001da4:	878d                	srai	a5,a5,0x3
    80001da6:	000a3703          	ld	a4,0(s4)
    80001daa:	02e787b3          	mul	a5,a5,a4
    80001dae:	2785                	addiw	a5,a5,1
    80001db0:	00d7979b          	slliw	a5,a5,0xd
    80001db4:	40f907b3          	sub	a5,s2,a5
    80001db8:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001dba:	24848493          	addi	s1,s1,584
    80001dbe:	fd3499e3          	bne	s1,s3,80001d90 <procinit+0x6e>
  }
}
    80001dc2:	70e2                	ld	ra,56(sp)
    80001dc4:	7442                	ld	s0,48(sp)
    80001dc6:	74a2                	ld	s1,40(sp)
    80001dc8:	7902                	ld	s2,32(sp)
    80001dca:	69e2                	ld	s3,24(sp)
    80001dcc:	6a42                	ld	s4,16(sp)
    80001dce:	6aa2                	ld	s5,8(sp)
    80001dd0:	6b02                	ld	s6,0(sp)
    80001dd2:	6121                	addi	sp,sp,64
    80001dd4:	8082                	ret

0000000080001dd6 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001dd6:	1141                	addi	sp,sp,-16
    80001dd8:	e422                	sd	s0,8(sp)
    80001dda:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ddc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001dde:	2501                	sext.w	a0,a0
    80001de0:	6422                	ld	s0,8(sp)
    80001de2:	0141                	addi	sp,sp,16
    80001de4:	8082                	ret

0000000080001de6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001de6:	1141                	addi	sp,sp,-16
    80001de8:	e422                	sd	s0,8(sp)
    80001dea:	0800                	addi	s0,sp,16
    80001dec:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001dee:	2781                	sext.w	a5,a5
    80001df0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001df2:	00230517          	auipc	a0,0x230
    80001df6:	0f650513          	addi	a0,a0,246 # 80231ee8 <cpus>
    80001dfa:	953e                	add	a0,a0,a5
    80001dfc:	6422                	ld	s0,8(sp)
    80001dfe:	0141                	addi	sp,sp,16
    80001e00:	8082                	ret

0000000080001e02 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001e02:	1101                	addi	sp,sp,-32
    80001e04:	ec06                	sd	ra,24(sp)
    80001e06:	e822                	sd	s0,16(sp)
    80001e08:	e426                	sd	s1,8(sp)
    80001e0a:	1000                	addi	s0,sp,32
  push_off();
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	fbe080e7          	jalr	-66(ra) # 80000dca <push_off>
    80001e14:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e16:	2781                	sext.w	a5,a5
    80001e18:	079e                	slli	a5,a5,0x7
    80001e1a:	00230717          	auipc	a4,0x230
    80001e1e:	09e70713          	addi	a4,a4,158 # 80231eb8 <pid_lock>
    80001e22:	97ba                	add	a5,a5,a4
    80001e24:	7b84                	ld	s1,48(a5)
  pop_off();
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	044080e7          	jalr	68(ra) # 80000e6a <pop_off>
  return p;
}
    80001e2e:	8526                	mv	a0,s1
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret

0000000080001e3a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001e3a:	1141                	addi	sp,sp,-16
    80001e3c:	e406                	sd	ra,8(sp)
    80001e3e:	e022                	sd	s0,0(sp)
    80001e40:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	fc0080e7          	jalr	-64(ra) # 80001e02 <myproc>
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	080080e7          	jalr	128(ra) # 80000eca <release>

  if (first)
    80001e52:	00008797          	auipc	a5,0x8
    80001e56:	bfe7a783          	lw	a5,-1026(a5) # 80009a50 <first.1858>
    80001e5a:	eb89                	bnez	a5,80001e6c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e5c:	00001097          	auipc	ra,0x1
    80001e60:	5ba080e7          	jalr	1466(ra) # 80003416 <usertrapret>
}
    80001e64:	60a2                	ld	ra,8(sp)
    80001e66:	6402                	ld	s0,0(sp)
    80001e68:	0141                	addi	sp,sp,16
    80001e6a:	8082                	ret
    first = 0;
    80001e6c:	00008797          	auipc	a5,0x8
    80001e70:	be07a223          	sw	zero,-1052(a5) # 80009a50 <first.1858>
    fsinit(ROOTDEV);
    80001e74:	4505                	li	a0,1
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	6a8080e7          	jalr	1704(ra) # 8000451e <fsinit>
    80001e7e:	bff9                	j	80001e5c <forkret+0x22>

0000000080001e80 <priority>:
{
    80001e80:	1141                	addi	sp,sp,-16
    80001e82:	e422                	sd	s0,8(sp)
    80001e84:	0800                	addi	s0,sp,16
  p->niceness = 5;
    80001e86:	4795                	li	a5,5
    80001e88:	18f52a23          	sw	a5,404(a0)
  if (p->run_time + p->sleep_time)
    80001e8c:	1b853683          	ld	a3,440(a0)
    80001e90:	1a853783          	ld	a5,424(a0)
    80001e94:	97b6                	add	a5,a5,a3
    80001e96:	cb89                	beqz	a5,80001ea8 <priority+0x28>
    p->niceness = (p->sleep_time * 10 / (p->run_time + p->sleep_time));
    80001e98:	00269713          	slli	a4,a3,0x2
    80001e9c:	9736                	add	a4,a4,a3
    80001e9e:	0706                	slli	a4,a4,0x1
    80001ea0:	02f757b3          	divu	a5,a4,a5
    80001ea4:	18f52a23          	sw	a5,404(a0)
  uint64 DP = max(0, min(p->stat_priority - p->niceness + 5, 100));
    80001ea8:	19052783          	lw	a5,400(a0)
    80001eac:	19452503          	lw	a0,404(a0)
    80001eb0:	40a7853b          	subw	a0,a5,a0
    80001eb4:	2515                	addiw	a0,a0,5
  return a < b ? a : b;
    80001eb6:	0005071b          	sext.w	a4,a0
    80001eba:	06400793          	li	a5,100
    80001ebe:	00e7d463          	bge	a5,a4,80001ec6 <priority+0x46>
    80001ec2:	06400513          	li	a0,100
  return a > b ? a : b;
    80001ec6:	0005079b          	sext.w	a5,a0
    80001eca:	fff7c793          	not	a5,a5
    80001ece:	97fd                	srai	a5,a5,0x3f
    80001ed0:	8d7d                	and	a0,a0,a5
}
    80001ed2:	2501                	sext.w	a0,a0
    80001ed4:	6422                	ld	s0,8(sp)
    80001ed6:	0141                	addi	sp,sp,16
    80001ed8:	8082                	ret

0000000080001eda <allocpid>:
{
    80001eda:	1101                	addi	sp,sp,-32
    80001edc:	ec06                	sd	ra,24(sp)
    80001ede:	e822                	sd	s0,16(sp)
    80001ee0:	e426                	sd	s1,8(sp)
    80001ee2:	e04a                	sd	s2,0(sp)
    80001ee4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ee6:	00230917          	auipc	s2,0x230
    80001eea:	fd290913          	addi	s2,s2,-46 # 80231eb8 <pid_lock>
    80001eee:	854a                	mv	a0,s2
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	f26080e7          	jalr	-218(ra) # 80000e16 <acquire>
  pid = nextpid;
    80001ef8:	00008797          	auipc	a5,0x8
    80001efc:	b6c78793          	addi	a5,a5,-1172 # 80009a64 <nextpid>
    80001f00:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001f02:	0014871b          	addiw	a4,s1,1
    80001f06:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001f08:	854a                	mv	a0,s2
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	fc0080e7          	jalr	-64(ra) # 80000eca <release>
}
    80001f12:	8526                	mv	a0,s1
    80001f14:	60e2                	ld	ra,24(sp)
    80001f16:	6442                	ld	s0,16(sp)
    80001f18:	64a2                	ld	s1,8(sp)
    80001f1a:	6902                	ld	s2,0(sp)
    80001f1c:	6105                	addi	sp,sp,32
    80001f1e:	8082                	ret

0000000080001f20 <queue_swap>:
{
    80001f20:	1141                	addi	sp,sp,-16
    80001f22:	e422                	sd	s0,8(sp)
    80001f24:	0800                	addi	s0,sp,16
  for (int curr = q->front; curr != q->rear; curr = (curr + 1) % (NPROC + 1))
    80001f26:	415c                	lw	a5,4(a0)
    80001f28:	4510                	lw	a2,8(a0)
    80001f2a:	02c78b63          	beq	a5,a2,80001f60 <queue_swap+0x40>
      q->arr[curr] = q->arr[(curr + 1) % (NPROC + 1)];
    80001f2e:	04100813          	li	a6,65
    80001f32:	a031                	j	80001f3e <queue_swap+0x1e>
  for (int curr = q->front; curr != q->rear; curr = (curr + 1) % (NPROC + 1))
    80001f34:	2785                	addiw	a5,a5,1
    80001f36:	0307e7bb          	remw	a5,a5,a6
    80001f3a:	02c78363          	beq	a5,a2,80001f60 <queue_swap+0x40>
    if (q->arr[curr]->pid == pid)
    80001f3e:	00379713          	slli	a4,a5,0x3
    80001f42:	972a                	add	a4,a4,a0
    80001f44:	6b14                	ld	a3,16(a4)
    80001f46:	5a94                	lw	a3,48(a3)
    80001f48:	feb696e3          	bne	a3,a1,80001f34 <queue_swap+0x14>
      q->arr[curr] = q->arr[(curr + 1) % (NPROC + 1)];
    80001f4c:	0017869b          	addiw	a3,a5,1
    80001f50:	0306e6bb          	remw	a3,a3,a6
    80001f54:	0689                	addi	a3,a3,2
    80001f56:	068e                	slli	a3,a3,0x3
    80001f58:	96aa                	add	a3,a3,a0
    80001f5a:	6294                	ld	a3,0(a3)
    80001f5c:	eb14                	sd	a3,16(a4)
    80001f5e:	bfd9                	j	80001f34 <queue_swap+0x14>
  q->rear--;
    80001f60:	367d                	addiw	a2,a2,-1
  if (q->rear < 0)
    80001f62:	02061793          	slli	a5,a2,0x20
    80001f66:	0007cb63          	bltz	a5,80001f7c <queue_swap+0x5c>
  q->rear--;
    80001f6a:	c510                	sw	a2,8(a0)
  q->numitems--;
    80001f6c:	21852783          	lw	a5,536(a0)
    80001f70:	37fd                	addiw	a5,a5,-1
    80001f72:	20f52c23          	sw	a5,536(a0)
}
    80001f76:	6422                	ld	s0,8(sp)
    80001f78:	0141                	addi	sp,sp,16
    80001f7a:	8082                	ret
    q->rear = NPROC;
    80001f7c:	04000793          	li	a5,64
    80001f80:	c51c                	sw	a5,8(a0)
    80001f82:	b7ed                	j	80001f6c <queue_swap+0x4c>

0000000080001f84 <proc_pagetable>:
{
    80001f84:	1101                	addi	sp,sp,-32
    80001f86:	ec06                	sd	ra,24(sp)
    80001f88:	e822                	sd	s0,16(sp)
    80001f8a:	e426                	sd	s1,8(sp)
    80001f8c:	e04a                	sd	s2,0(sp)
    80001f8e:	1000                	addi	s0,sp,32
    80001f90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	5de080e7          	jalr	1502(ra) # 80001570 <uvmcreate>
    80001f9a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f9c:	c121                	beqz	a0,80001fdc <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f9e:	4729                	li	a4,10
    80001fa0:	00006697          	auipc	a3,0x6
    80001fa4:	06068693          	addi	a3,a3,96 # 80008000 <_trampoline>
    80001fa8:	6605                	lui	a2,0x1
    80001faa:	040005b7          	lui	a1,0x4000
    80001fae:	15fd                	addi	a1,a1,-1
    80001fb0:	05b2                	slli	a1,a1,0xc
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	334080e7          	jalr	820(ra) # 800012e6 <mappages>
    80001fba:	02054863          	bltz	a0,80001fea <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001fbe:	4719                	li	a4,6
    80001fc0:	05893683          	ld	a3,88(s2)
    80001fc4:	6605                	lui	a2,0x1
    80001fc6:	020005b7          	lui	a1,0x2000
    80001fca:	15fd                	addi	a1,a1,-1
    80001fcc:	05b6                	slli	a1,a1,0xd
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	316080e7          	jalr	790(ra) # 800012e6 <mappages>
    80001fd8:	02054163          	bltz	a0,80001ffa <proc_pagetable+0x76>
}
    80001fdc:	8526                	mv	a0,s1
    80001fde:	60e2                	ld	ra,24(sp)
    80001fe0:	6442                	ld	s0,16(sp)
    80001fe2:	64a2                	ld	s1,8(sp)
    80001fe4:	6902                	ld	s2,0(sp)
    80001fe6:	6105                	addi	sp,sp,32
    80001fe8:	8082                	ret
    uvmfree(pagetable, 0);
    80001fea:	4581                	li	a1,0
    80001fec:	8526                	mv	a0,s1
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	786080e7          	jalr	1926(ra) # 80001774 <uvmfree>
    return 0;
    80001ff6:	4481                	li	s1,0
    80001ff8:	b7d5                	j	80001fdc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ffa:	4681                	li	a3,0
    80001ffc:	4605                	li	a2,1
    80001ffe:	040005b7          	lui	a1,0x4000
    80002002:	15fd                	addi	a1,a1,-1
    80002004:	05b2                	slli	a1,a1,0xc
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	4a4080e7          	jalr	1188(ra) # 800014ac <uvmunmap>
    uvmfree(pagetable, 0);
    80002010:	4581                	li	a1,0
    80002012:	8526                	mv	a0,s1
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	760080e7          	jalr	1888(ra) # 80001774 <uvmfree>
    return 0;
    8000201c:	4481                	li	s1,0
    8000201e:	bf7d                	j	80001fdc <proc_pagetable+0x58>

0000000080002020 <proc_freepagetable>:
{
    80002020:	1101                	addi	sp,sp,-32
    80002022:	ec06                	sd	ra,24(sp)
    80002024:	e822                	sd	s0,16(sp)
    80002026:	e426                	sd	s1,8(sp)
    80002028:	e04a                	sd	s2,0(sp)
    8000202a:	1000                	addi	s0,sp,32
    8000202c:	84aa                	mv	s1,a0
    8000202e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002030:	4681                	li	a3,0
    80002032:	4605                	li	a2,1
    80002034:	040005b7          	lui	a1,0x4000
    80002038:	15fd                	addi	a1,a1,-1
    8000203a:	05b2                	slli	a1,a1,0xc
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	470080e7          	jalr	1136(ra) # 800014ac <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002044:	4681                	li	a3,0
    80002046:	4605                	li	a2,1
    80002048:	020005b7          	lui	a1,0x2000
    8000204c:	15fd                	addi	a1,a1,-1
    8000204e:	05b6                	slli	a1,a1,0xd
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	45a080e7          	jalr	1114(ra) # 800014ac <uvmunmap>
  uvmfree(pagetable, sz);
    8000205a:	85ca                	mv	a1,s2
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	716080e7          	jalr	1814(ra) # 80001774 <uvmfree>
}
    80002066:	60e2                	ld	ra,24(sp)
    80002068:	6442                	ld	s0,16(sp)
    8000206a:	64a2                	ld	s1,8(sp)
    8000206c:	6902                	ld	s2,0(sp)
    8000206e:	6105                	addi	sp,sp,32
    80002070:	8082                	ret

0000000080002072 <freeproc>:
  if (p)
    80002072:	c525                	beqz	a0,800020da <freeproc+0x68>
{
    80002074:	1101                	addi	sp,sp,-32
    80002076:	ec06                	sd	ra,24(sp)
    80002078:	e822                	sd	s0,16(sp)
    8000207a:	e426                	sd	s1,8(sp)
    8000207c:	1000                	addi	s0,sp,32
    8000207e:	84aa                	mv	s1,a0
    if (p->trapframe)
    80002080:	6d28                	ld	a0,88(a0)
    80002082:	c509                	beqz	a0,8000208c <freeproc+0x1a>
      kfree((void *)p->trapframe);
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b0e080e7          	jalr	-1266(ra) # 80000b92 <kfree>
    if (p->cpy_trapframe)
    8000208c:	1884b503          	ld	a0,392(s1)
    80002090:	c509                	beqz	a0,8000209a <freeproc+0x28>
      kfree((void *)p->cpy_trapframe);
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b00080e7          	jalr	-1280(ra) # 80000b92 <kfree>
    p->trapframe = 0;
    8000209a:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    8000209e:	68a8                	ld	a0,80(s1)
    800020a0:	c511                	beqz	a0,800020ac <freeproc+0x3a>
      proc_freepagetable(p->pagetable, p->sz);
    800020a2:	64ac                	ld	a1,72(s1)
    800020a4:	00000097          	auipc	ra,0x0
    800020a8:	f7c080e7          	jalr	-132(ra) # 80002020 <proc_freepagetable>
    p->pagetable = 0;
    800020ac:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    800020b0:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    800020b4:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    800020b8:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    800020bc:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    800020c0:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    800020c4:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    800020c8:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    800020cc:	0004ac23          	sw	zero,24(s1)
}
    800020d0:	60e2                	ld	ra,24(sp)
    800020d2:	6442                	ld	s0,16(sp)
    800020d4:	64a2                	ld	s1,8(sp)
    800020d6:	6105                	addi	sp,sp,32
    800020d8:	8082                	ret
    800020da:	8082                	ret

00000000800020dc <allocproc>:
{
    800020dc:	1101                	addi	sp,sp,-32
    800020de:	ec06                	sd	ra,24(sp)
    800020e0:	e822                	sd	s0,16(sp)
    800020e2:	e426                	sd	s1,8(sp)
    800020e4:	e04a                	sd	s2,0(sp)
    800020e6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    800020e8:	00230497          	auipc	s1,0x230
    800020ec:	20048493          	addi	s1,s1,512 # 802322e8 <proc>
    800020f0:	00239917          	auipc	s2,0x239
    800020f4:	3f890913          	addi	s2,s2,1016 # 8023b4e8 <mlfq>
    acquire(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	d1c080e7          	jalr	-740(ra) # 80000e16 <acquire>
    if (p->state == UNUSED)
    80002102:	4c9c                	lw	a5,24(s1)
    80002104:	cf81                	beqz	a5,8000211c <allocproc+0x40>
      release(&p->lock);
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	dc2080e7          	jalr	-574(ra) # 80000eca <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002110:	24848493          	addi	s1,s1,584
    80002114:	ff2492e3          	bne	s1,s2,800020f8 <allocproc+0x1c>
  return 0;
    80002118:	4481                	li	s1,0
    8000211a:	a281                	j	8000225a <allocproc+0x17e>
  p->pid = allocpid();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	dbe080e7          	jalr	-578(ra) # 80001eda <allocpid>
    80002124:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002126:	4785                	li	a5,1
    80002128:	cc9c                	sw	a5,24(s1)
  p->init_time = ticks;
    8000212a:	00008797          	auipc	a5,0x8
    8000212e:	b067e783          	lwu	a5,-1274(a5) # 80009c30 <ticks>
    80002132:	18f4bc23          	sd	a5,408(s1)
  p->run_time = 0;
    80002136:	1a04b423          	sd	zero,424(s1)
  p->end_time = 0;
    8000213a:	1a04b823          	sd	zero,432(s1)
  p->sleep_time = 0;
    8000213e:	1a04bc23          	sd	zero,440(s1)
  p->runs_till_now = 0;
    80002142:	1e04b423          	sd	zero,488(s1)
  p->tickets = 1;
    80002146:	4785                	li	a5,1
    80002148:	18f4b023          	sd	a5,384(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	bce080e7          	jalr	-1074(ra) # 80000d1a <kalloc>
    80002154:	892a                	mv	s2,a0
    80002156:	eca8                	sd	a0,88(s1)
    80002158:	10050863          	beqz	a0,80002268 <allocproc+0x18c>
  if ((p->cpy_trapframe = (struct trapframe *)kalloc()) == 0)
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	bbe080e7          	jalr	-1090(ra) # 80000d1a <kalloc>
    80002164:	892a                	mv	s2,a0
    80002166:	18a4b423          	sd	a0,392(s1)
    8000216a:	10050b63          	beqz	a0,80002280 <allocproc+0x1a4>
  p->mlfq_priority = 0;
    8000216e:	1c04b823          	sd	zero,464(s1)
  p->queue_in_time = 0;
    80002172:	1e04b823          	sd	zero,496(s1)
  p->runs_till_now = 0;
    80002176:	1e04b423          	sd	zero,488(s1)
    p->queue_run_time[i] = 0;
    8000217a:	1e04bc23          	sd	zero,504(s1)
    8000217e:	2004b023          	sd	zero,512(s1)
    80002182:	2004b423          	sd	zero,520(s1)
    80002186:	2004b823          	sd	zero,528(s1)
    8000218a:	2004bc23          	sd	zero,536(s1)
  p->queued = 0;
    8000218e:	1c04bc23          	sd	zero,472(s1)
  p->quantums_left = 1;
    80002192:	4785                	li	a5,1
    80002194:	1ef4b023          	sd	a5,480(s1)
  p->stat_priority = 60;
    80002198:	03c00793          	li	a5,60
    8000219c:	18f4a823          	sw	a5,400(s1)
  p->niceness = 5;
    800021a0:	4795                	li	a5,5
    800021a2:	18f4aa23          	sw	a5,404(s1)
  p->is_sigalarm = 0;
    800021a6:	1604a623          	sw	zero,364(s1)
  p->clockval = 0;
    800021aa:	1604a823          	sw	zero,368(s1)
  p->completed_clockval = 0;
    800021ae:	1604aa23          	sw	zero,372(s1)
  p->handler = 0;
    800021b2:	1604bc23          	sd	zero,376(s1)
  p->age_queue[0] = -10;
    800021b6:	57d9                	li	a5,-10
    800021b8:	22f4b023          	sd	a5,544(s1)
  p->age_queue[1] = 10;
    800021bc:	47a9                	li	a5,10
    800021be:	22f4b423          	sd	a5,552(s1)
  p->age_queue[2] = 20;
    800021c2:	47d1                	li	a5,20
    800021c4:	22f4b823          	sd	a5,560(s1)
  p->age_queue[3] = 30;
    800021c8:	47f9                	li	a5,30
    800021ca:	22f4bc23          	sd	a5,568(s1)
  p->age_queue[4] = 40;
    800021ce:	02800793          	li	a5,40
    800021d2:	24f4b023          	sd	a5,576(s1)
  p->wait_time = 0;
    800021d6:	1a04b023          	sd	zero,416(s1)
    mlfq[i] = Create_Queue();
    800021da:	00239797          	auipc	a5,0x239
    800021de:	30e78793          	addi	a5,a5,782 # 8023b4e8 <mlfq>
    800021e2:	0007a223          	sw	zero,4(a5)
    800021e6:	0007a423          	sw	zero,8(a5)
    800021ea:	2007ac23          	sw	zero,536(a5)
    800021ee:	2207a223          	sw	zero,548(a5)
    800021f2:	2207a423          	sw	zero,552(a5)
    800021f6:	4207ac23          	sw	zero,1080(a5)
    800021fa:	4407a223          	sw	zero,1092(a5)
    800021fe:	4407a423          	sw	zero,1096(a5)
    80002202:	6407ac23          	sw	zero,1624(a5)
    80002206:	6607a223          	sw	zero,1636(a5)
    8000220a:	6607a423          	sw	zero,1640(a5)
    8000220e:	0023a797          	auipc	a5,0x23a
    80002212:	2da78793          	addi	a5,a5,730 # 8023c4e8 <bcache+0x548>
    80002216:	8607ac23          	sw	zero,-1928(a5)
    8000221a:	8807a223          	sw	zero,-1916(a5)
    8000221e:	8807a423          	sw	zero,-1912(a5)
    80002222:	a807ac23          	sw	zero,-1384(a5)
  p->pagetable = proc_pagetable(p);
    80002226:	8526                	mv	a0,s1
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	d5c080e7          	jalr	-676(ra) # 80001f84 <proc_pagetable>
    80002230:	892a                	mv	s2,a0
    80002232:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80002234:	cd29                	beqz	a0,8000228e <allocproc+0x1b2>
  memset(&p->context, 0, sizeof(p->context));
    80002236:	07000613          	li	a2,112
    8000223a:	4581                	li	a1,0
    8000223c:	06048513          	addi	a0,s1,96
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	cd2080e7          	jalr	-814(ra) # 80000f12 <memset>
  p->context.ra = (uint64)forkret;
    80002248:	00000797          	auipc	a5,0x0
    8000224c:	bf278793          	addi	a5,a5,-1038 # 80001e3a <forkret>
    80002250:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002252:	60bc                	ld	a5,64(s1)
    80002254:	6705                	lui	a4,0x1
    80002256:	97ba                	add	a5,a5,a4
    80002258:	f4bc                	sd	a5,104(s1)
}
    8000225a:	8526                	mv	a0,s1
    8000225c:	60e2                	ld	ra,24(sp)
    8000225e:	6442                	ld	s0,16(sp)
    80002260:	64a2                	ld	s1,8(sp)
    80002262:	6902                	ld	s2,0(sp)
    80002264:	6105                	addi	sp,sp,32
    80002266:	8082                	ret
    freeproc(p);
    80002268:	8526                	mv	a0,s1
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	e08080e7          	jalr	-504(ra) # 80002072 <freeproc>
    release(&p->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	c56080e7          	jalr	-938(ra) # 80000eca <release>
    return 0;
    8000227c:	84ca                	mv	s1,s2
    8000227e:	bff1                	j	8000225a <allocproc+0x17e>
    release(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	c48080e7          	jalr	-952(ra) # 80000eca <release>
    return 0;
    8000228a:	84ca                	mv	s1,s2
    8000228c:	b7f9                	j	8000225a <allocproc+0x17e>
    freeproc(p);
    8000228e:	8526                	mv	a0,s1
    80002290:	00000097          	auipc	ra,0x0
    80002294:	de2080e7          	jalr	-542(ra) # 80002072 <freeproc>
    release(&p->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	c30080e7          	jalr	-976(ra) # 80000eca <release>
    return 0;
    800022a2:	84ca                	mv	s1,s2
    800022a4:	bf5d                	j	8000225a <allocproc+0x17e>

00000000800022a6 <userinit>:
{
    800022a6:	1101                	addi	sp,sp,-32
    800022a8:	ec06                	sd	ra,24(sp)
    800022aa:	e822                	sd	s0,16(sp)
    800022ac:	e426                	sd	s1,8(sp)
    800022ae:	1000                	addi	s0,sp,32
  p = allocproc();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	e2c080e7          	jalr	-468(ra) # 800020dc <allocproc>
    800022b8:	84aa                	mv	s1,a0
  initproc = p;
    800022ba:	00008797          	auipc	a5,0x8
    800022be:	96a7b723          	sd	a0,-1682(a5) # 80009c28 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    800022c2:	03400613          	li	a2,52
    800022c6:	00007597          	auipc	a1,0x7
    800022ca:	7aa58593          	addi	a1,a1,1962 # 80009a70 <initcode>
    800022ce:	6928                	ld	a0,80(a0)
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	2ce080e7          	jalr	718(ra) # 8000159e <uvmfirst>
  p->sz = PGSIZE;
    800022d8:	6785                	lui	a5,0x1
    800022da:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    800022dc:	6cb8                	ld	a4,88(s1)
    800022de:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    800022e2:	6cb8                	ld	a4,88(s1)
    800022e4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800022e6:	4641                	li	a2,16
    800022e8:	00007597          	auipc	a1,0x7
    800022ec:	f5058593          	addi	a1,a1,-176 # 80009238 <digits+0x1f8>
    800022f0:	15848513          	addi	a0,s1,344
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	d70080e7          	jalr	-656(ra) # 80001064 <safestrcpy>
  p->cwd = namei("/");
    800022fc:	00007517          	auipc	a0,0x7
    80002300:	f4c50513          	addi	a0,a0,-180 # 80009248 <digits+0x208>
    80002304:	00003097          	auipc	ra,0x3
    80002308:	c3c080e7          	jalr	-964(ra) # 80004f40 <namei>
    8000230c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002310:	478d                	li	a5,3
    80002312:	cc9c                	sw	a5,24(s1)
  if (p && !p->queued)
    80002314:	1d84b783          	ld	a5,472(s1)
    80002318:	cb99                	beqz	a5,8000232e <userinit+0x88>
  release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	bae080e7          	jalr	-1106(ra) # 80000eca <release>
}
    80002324:	60e2                	ld	ra,24(sp)
    80002326:	6442                	ld	s0,16(sp)
    80002328:	64a2                	ld	s1,8(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret
    enqueue(&mlfq[0], p);
    8000232e:	85a6                	mv	a1,s1
    80002330:	00239517          	auipc	a0,0x239
    80002334:	1b850513          	addi	a0,a0,440 # 8023b4e8 <mlfq>
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	7a0080e7          	jalr	1952(ra) # 80001ad8 <enqueue>
    p->queue_in_time = ticks;
    80002340:	00008797          	auipc	a5,0x8
    80002344:	8f07e783          	lwu	a5,-1808(a5) # 80009c30 <ticks>
    80002348:	1ef4b823          	sd	a5,496(s1)
    p->queued = 1;
    8000234c:	4785                	li	a5,1
    8000234e:	1cf4bc23          	sd	a5,472(s1)
    p->mlfq_priority = 0;
    80002352:	1c04b823          	sd	zero,464(s1)
    p->wait_time = 0;
    80002356:	1a04b023          	sd	zero,416(s1)
    8000235a:	b7c1                	j	8000231a <userinit+0x74>

000000008000235c <growproc>:
{
    8000235c:	1101                	addi	sp,sp,-32
    8000235e:	ec06                	sd	ra,24(sp)
    80002360:	e822                	sd	s0,16(sp)
    80002362:	e426                	sd	s1,8(sp)
    80002364:	e04a                	sd	s2,0(sp)
    80002366:	1000                	addi	s0,sp,32
    80002368:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	a98080e7          	jalr	-1384(ra) # 80001e02 <myproc>
    80002372:	84aa                	mv	s1,a0
  sz = p->sz;
    80002374:	652c                	ld	a1,72(a0)
  if (n > 0)
    80002376:	01204c63          	bgtz	s2,8000238e <growproc+0x32>
  else if (n < 0)
    8000237a:	02094663          	bltz	s2,800023a6 <growproc+0x4a>
  p->sz = sz;
    8000237e:	e4ac                	sd	a1,72(s1)
  return 0;
    80002380:	4501                	li	a0,0
}
    80002382:	60e2                	ld	ra,24(sp)
    80002384:	6442                	ld	s0,16(sp)
    80002386:	64a2                	ld	s1,8(sp)
    80002388:	6902                	ld	s2,0(sp)
    8000238a:	6105                	addi	sp,sp,32
    8000238c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    8000238e:	4691                	li	a3,4
    80002390:	00b90633          	add	a2,s2,a1
    80002394:	6928                	ld	a0,80(a0)
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	2c2080e7          	jalr	706(ra) # 80001658 <uvmalloc>
    8000239e:	85aa                	mv	a1,a0
    800023a0:	fd79                	bnez	a0,8000237e <growproc+0x22>
      return -1;
    800023a2:	557d                	li	a0,-1
    800023a4:	bff9                	j	80002382 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800023a6:	00b90633          	add	a2,s2,a1
    800023aa:	6928                	ld	a0,80(a0)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	264080e7          	jalr	612(ra) # 80001610 <uvmdealloc>
    800023b4:	85aa                	mv	a1,a0
    800023b6:	b7e1                	j	8000237e <growproc+0x22>

00000000800023b8 <fork>:
{
    800023b8:	7179                	addi	sp,sp,-48
    800023ba:	f406                	sd	ra,40(sp)
    800023bc:	f022                	sd	s0,32(sp)
    800023be:	ec26                	sd	s1,24(sp)
    800023c0:	e84a                	sd	s2,16(sp)
    800023c2:	e44e                	sd	s3,8(sp)
    800023c4:	e052                	sd	s4,0(sp)
    800023c6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	a3a080e7          	jalr	-1478(ra) # 80001e02 <myproc>
    800023d0:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	d0a080e7          	jalr	-758(ra) # 800020dc <allocproc>
    800023da:	16050063          	beqz	a0,8000253a <fork+0x182>
    800023de:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800023e0:	04893603          	ld	a2,72(s2)
    800023e4:	692c                	ld	a1,80(a0)
    800023e6:	05093503          	ld	a0,80(s2)
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	3c2080e7          	jalr	962(ra) # 800017ac <uvmcopy>
    800023f2:	04054e63          	bltz	a0,8000244e <fork+0x96>
  np->sz = p->sz;
    800023f6:	04893783          	ld	a5,72(s2)
    800023fa:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800023fe:	05893683          	ld	a3,88(s2)
    80002402:	87b6                	mv	a5,a3
    80002404:	0589b703          	ld	a4,88(s3)
    80002408:	12068693          	addi	a3,a3,288
    8000240c:	0007b803          	ld	a6,0(a5)
    80002410:	6788                	ld	a0,8(a5)
    80002412:	6b8c                	ld	a1,16(a5)
    80002414:	6f90                	ld	a2,24(a5)
    80002416:	01073023          	sd	a6,0(a4)
    8000241a:	e708                	sd	a0,8(a4)
    8000241c:	eb0c                	sd	a1,16(a4)
    8000241e:	ef10                	sd	a2,24(a4)
    80002420:	02078793          	addi	a5,a5,32
    80002424:	02070713          	addi	a4,a4,32
    80002428:	fed792e3          	bne	a5,a3,8000240c <fork+0x54>
  np->trapframe->a0 = 0;
    8000242c:	0589b783          	ld	a5,88(s3)
    80002430:	0607b823          	sd	zero,112(a5)
  np->bitmask = p->bitmask;
    80002434:	16892783          	lw	a5,360(s2)
    80002438:	16f9a423          	sw	a5,360(s3)
  np->tickets = p->tickets;
    8000243c:	18093783          	ld	a5,384(s2)
    80002440:	18f9b023          	sd	a5,384(s3)
    80002444:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80002448:	15000a13          	li	s4,336
    8000244c:	a03d                	j	8000247a <fork+0xc2>
    freeproc(np);
    8000244e:	854e                	mv	a0,s3
    80002450:	00000097          	auipc	ra,0x0
    80002454:	c22080e7          	jalr	-990(ra) # 80002072 <freeproc>
    release(&np->lock);
    80002458:	854e                	mv	a0,s3
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	a70080e7          	jalr	-1424(ra) # 80000eca <release>
    return -1;
    80002462:	5a7d                	li	s4,-1
    80002464:	a859                	j	800024fa <fork+0x142>
      np->ofile[i] = filedup(p->ofile[i]);
    80002466:	00003097          	auipc	ra,0x3
    8000246a:	170080e7          	jalr	368(ra) # 800055d6 <filedup>
    8000246e:	009987b3          	add	a5,s3,s1
    80002472:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002474:	04a1                	addi	s1,s1,8
    80002476:	01448763          	beq	s1,s4,80002484 <fork+0xcc>
    if (p->ofile[i])
    8000247a:	009907b3          	add	a5,s2,s1
    8000247e:	6388                	ld	a0,0(a5)
    80002480:	f17d                	bnez	a0,80002466 <fork+0xae>
    80002482:	bfcd                	j	80002474 <fork+0xbc>
  np->cwd = idup(p->cwd);
    80002484:	15093503          	ld	a0,336(s2)
    80002488:	00002097          	auipc	ra,0x2
    8000248c:	2d4080e7          	jalr	724(ra) # 8000475c <idup>
    80002490:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002494:	4641                	li	a2,16
    80002496:	15890593          	addi	a1,s2,344
    8000249a:	15898513          	addi	a0,s3,344
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	bc6080e7          	jalr	-1082(ra) # 80001064 <safestrcpy>
  pid = np->pid;
    800024a6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800024aa:	854e                	mv	a0,s3
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	a1e080e7          	jalr	-1506(ra) # 80000eca <release>
  acquire(&wait_lock);
    800024b4:	00230497          	auipc	s1,0x230
    800024b8:	a1c48493          	addi	s1,s1,-1508 # 80231ed0 <wait_lock>
    800024bc:	8526                	mv	a0,s1
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	958080e7          	jalr	-1704(ra) # 80000e16 <acquire>
  np->parent = p;
    800024c6:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	9fe080e7          	jalr	-1538(ra) # 80000eca <release>
  acquire(&np->lock);
    800024d4:	854e                	mv	a0,s3
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	940080e7          	jalr	-1728(ra) # 80000e16 <acquire>
  np->state = RUNNABLE;
    800024de:	478d                	li	a5,3
    800024e0:	00f9ac23          	sw	a5,24(s3)
  if (np && !np->queued && p->queued)
    800024e4:	1d89b783          	ld	a5,472(s3)
    800024e8:	e781                	bnez	a5,800024f0 <fork+0x138>
    800024ea:	1d893783          	ld	a5,472(s2)
    800024ee:	ef99                	bnez	a5,8000250c <fork+0x154>
  release(&np->lock);
    800024f0:	854e                	mv	a0,s3
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	9d8080e7          	jalr	-1576(ra) # 80000eca <release>
}
    800024fa:	8552                	mv	a0,s4
    800024fc:	70a2                	ld	ra,40(sp)
    800024fe:	7402                	ld	s0,32(sp)
    80002500:	64e2                	ld	s1,24(sp)
    80002502:	6942                	ld	s2,16(sp)
    80002504:	69a2                	ld	s3,8(sp)
    80002506:	6a02                	ld	s4,0(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret
    enqueue(&mlfq[0], np);
    8000250c:	85ce                	mv	a1,s3
    8000250e:	00239517          	auipc	a0,0x239
    80002512:	fda50513          	addi	a0,a0,-38 # 8023b4e8 <mlfq>
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	5c2080e7          	jalr	1474(ra) # 80001ad8 <enqueue>
    np->queued = 1;
    8000251e:	4785                	li	a5,1
    80002520:	1cf9bc23          	sd	a5,472(s3)
    np->queue_in_time = ticks;
    80002524:	00007797          	auipc	a5,0x7
    80002528:	70c7e783          	lwu	a5,1804(a5) # 80009c30 <ticks>
    8000252c:	1ef9b823          	sd	a5,496(s3)
    np->mlfq_priority = 0;
    80002530:	1c09b823          	sd	zero,464(s3)
    np->wait_time = 0;
    80002534:	1a09b023          	sd	zero,416(s3)
    80002538:	bf65                	j	800024f0 <fork+0x138>
    return -1;
    8000253a:	5a7d                	li	s4,-1
    8000253c:	bf7d                	j	800024fa <fork+0x142>

000000008000253e <lock_ptable>:
{
    8000253e:	1101                	addi	sp,sp,-32
    80002540:	ec06                	sd	ra,24(sp)
    80002542:	e822                	sd	s0,16(sp)
    80002544:	e426                	sd	s1,8(sp)
    80002546:	e04a                	sd	s2,0(sp)
    80002548:	1000                	addi	s0,sp,32
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000254a:	00230497          	auipc	s1,0x230
    8000254e:	d9e48493          	addi	s1,s1,-610 # 802322e8 <proc>
    80002552:	00239917          	auipc	s2,0x239
    80002556:	f9690913          	addi	s2,s2,-106 # 8023b4e8 <mlfq>
    acquire(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	8ba080e7          	jalr	-1862(ra) # 80000e16 <acquire>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002564:	24848493          	addi	s1,s1,584
    80002568:	ff2499e3          	bne	s1,s2,8000255a <lock_ptable+0x1c>
}
    8000256c:	60e2                	ld	ra,24(sp)
    8000256e:	6442                	ld	s0,16(sp)
    80002570:	64a2                	ld	s1,8(sp)
    80002572:	6902                	ld	s2,0(sp)
    80002574:	6105                	addi	sp,sp,32
    80002576:	8082                	ret

0000000080002578 <release_ptable>:
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	1800                	addi	s0,sp,48
    80002586:	892a                	mv	s2,a0
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002588:	00230497          	auipc	s1,0x230
    8000258c:	d6048493          	addi	s1,s1,-672 # 802322e8 <proc>
    80002590:	00239997          	auipc	s3,0x239
    80002594:	f5898993          	addi	s3,s3,-168 # 8023b4e8 <mlfq>
    80002598:	a811                	j	800025ac <release_ptable+0x34>
      release(&p->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	92e080e7          	jalr	-1746(ra) # 80000eca <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    800025a4:	24848493          	addi	s1,s1,584
    800025a8:	01348563          	beq	s1,s3,800025b2 <release_ptable+0x3a>
    if (p != e)
    800025ac:	fe9917e3          	bne	s2,s1,8000259a <release_ptable+0x22>
    800025b0:	bfd5                	j	800025a4 <release_ptable+0x2c>
}
    800025b2:	70a2                	ld	ra,40(sp)
    800025b4:	7402                	ld	s0,32(sp)
    800025b6:	64e2                	ld	s1,24(sp)
    800025b8:	6942                	ld	s2,16(sp)
    800025ba:	69a2                	ld	s3,8(sp)
    800025bc:	6145                	addi	sp,sp,48
    800025be:	8082                	ret

00000000800025c0 <scheduler>:
{
    800025c0:	d6010113          	addi	sp,sp,-672
    800025c4:	28113c23          	sd	ra,664(sp)
    800025c8:	28813823          	sd	s0,656(sp)
    800025cc:	28913423          	sd	s1,648(sp)
    800025d0:	29213023          	sd	s2,640(sp)
    800025d4:	27313c23          	sd	s3,632(sp)
    800025d8:	27413823          	sd	s4,624(sp)
    800025dc:	27513423          	sd	s5,616(sp)
    800025e0:	27613023          	sd	s6,608(sp)
    800025e4:	25713c23          	sd	s7,600(sp)
    800025e8:	25813823          	sd	s8,592(sp)
    800025ec:	25913423          	sd	s9,584(sp)
    800025f0:	25a13023          	sd	s10,576(sp)
    800025f4:	23b13c23          	sd	s11,568(sp)
    800025f8:	1500                	addi	s0,sp,672
    800025fa:	8792                	mv	a5,tp
  int id = r_tp();
    800025fc:	2781                	sext.w	a5,a5
  c->proc = 0;
    800025fe:	00779693          	slli	a3,a5,0x7
    80002602:	00230717          	auipc	a4,0x230
    80002606:	8b670713          	addi	a4,a4,-1866 # 80231eb8 <pid_lock>
    8000260a:	9736                	add	a4,a4,a3
    8000260c:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &proc_to_run->context);
    80002610:	00230717          	auipc	a4,0x230
    80002614:	8e070713          	addi	a4,a4,-1824 # 80231ef0 <cpus+0x8>
    80002618:	9736                	add	a4,a4,a3
    8000261a:	d6e43423          	sd	a4,-664(s0)
        enqueue(&mlfq[p->mlfq_priority], p);
    8000261e:	00239c97          	auipc	s9,0x239
    80002622:	ecac8c93          	addi	s9,s9,-310 # 8023b4e8 <mlfq>
        p->queue_in_time = ticks;
    80002626:	00007c17          	auipc	s8,0x7
    8000262a:	60ac0c13          	addi	s8,s8,1546 # 80009c30 <ticks>
    c->proc = proc_to_run;
    8000262e:	00230d97          	auipc	s11,0x230
    80002632:	88ad8d93          	addi	s11,s11,-1910 # 80231eb8 <pid_lock>
    80002636:	9db6                	add	s11,s11,a3
    80002638:	aa7d                	j	800027f6 <scheduler+0x236>
        enqueue(&mlfq[p->mlfq_priority], p);
    8000263a:	1d04b783          	ld	a5,464(s1)
    8000263e:	00479513          	slli	a0,a5,0x4
    80002642:	953e                	add	a0,a0,a5
    80002644:	0516                	slli	a0,a0,0x5
    80002646:	85a6                	mv	a1,s1
    80002648:	9566                	add	a0,a0,s9
    8000264a:	fffff097          	auipc	ra,0xfffff
    8000264e:	48e080e7          	jalr	1166(ra) # 80001ad8 <enqueue>
        p->queue_in_time = ticks;
    80002652:	000c6783          	lwu	a5,0(s8)
    80002656:	1ef4b823          	sd	a5,496(s1)
        p->queued = 1;
    8000265a:	1d24bc23          	sd	s2,472(s1)
        p->wait_time = 0;
    8000265e:	1a04b023          	sd	zero,416(s1)
      release(&p->lock);
    80002662:	8526                	mv	a0,s1
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	866080e7          	jalr	-1946(ra) # 80000eca <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000266c:	24848493          	addi	s1,s1,584
    80002670:	01448e63          	beq	s1,s4,8000268c <scheduler+0xcc>
      acquire(&p->lock);
    80002674:	8526                	mv	a0,s1
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	7a0080e7          	jalr	1952(ra) # 80000e16 <acquire>
      if (p->state == RUNNABLE && !p->queued)
    8000267e:	4c9c                	lw	a5,24(s1)
    80002680:	ff3791e3          	bne	a5,s3,80002662 <scheduler+0xa2>
    80002684:	1d84b783          	ld	a5,472(s1)
    80002688:	ffe9                	bnez	a5,80002662 <scheduler+0xa2>
    8000268a:	bf45                	j	8000263a <scheduler+0x7a>
    for (p = proc; p < &proc[NPROC]; p++)
    8000268c:	00230497          	auipc	s1,0x230
    80002690:	c5c48493          	addi	s1,s1,-932 # 802322e8 <proc>
    80002694:	a811                	j	800026a8 <scheduler+0xe8>
      release(&p->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	832080e7          	jalr	-1998(ra) # 80000eca <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800026a0:	24848493          	addi	s1,s1,584
    800026a4:	07448f63          	beq	s1,s4,80002722 <scheduler+0x162>
      acquire(&p->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	76c080e7          	jalr	1900(ra) # 80000e16 <acquire>
      if (p && p->state == RUNNABLE && p->mlfq_priority && ticks - p->queue_in_time >= p->age_queue[p->mlfq_priority])
    800026b2:	d0f5                	beqz	s1,80002696 <scheduler+0xd6>
    800026b4:	4c9c                	lw	a5,24(s1)
    800026b6:	ff3790e3          	bne	a5,s3,80002696 <scheduler+0xd6>
    800026ba:	1d04b703          	ld	a4,464(s1)
    800026be:	df61                	beqz	a4,80002696 <scheduler+0xd6>
    800026c0:	000c6683          	lwu	a3,0(s8)
    800026c4:	1f04b783          	ld	a5,496(s1)
    800026c8:	8e9d                	sub	a3,a3,a5
    800026ca:	04470793          	addi	a5,a4,68
    800026ce:	078e                	slli	a5,a5,0x3
    800026d0:	97a6                	add	a5,a5,s1
    800026d2:	639c                	ld	a5,0(a5)
    800026d4:	fcf6e1e3          	bltu	a3,a5,80002696 <scheduler+0xd6>
        if (p->queued)
    800026d8:	1d84b783          	ld	a5,472(s1)
    800026dc:	dfcd                	beqz	a5,80002696 <scheduler+0xd6>
          queue_swap(&mlfq[p->mlfq_priority], p->pid);
    800026de:	00471513          	slli	a0,a4,0x4
    800026e2:	972a                	add	a4,a4,a0
    800026e4:	00571513          	slli	a0,a4,0x5
    800026e8:	588c                	lw	a1,48(s1)
    800026ea:	9566                	add	a0,a0,s9
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	834080e7          	jalr	-1996(ra) # 80001f20 <queue_swap>
          p->mlfq_priority--;
    800026f4:	1d04b503          	ld	a0,464(s1)
    800026f8:	fff50793          	addi	a5,a0,-1
    800026fc:	1cf4b823          	sd	a5,464(s1)
          enqueue(&mlfq[p->mlfq_priority], p);
    80002700:	00479513          	slli	a0,a5,0x4
    80002704:	953e                	add	a0,a0,a5
    80002706:	0516                	slli	a0,a0,0x5
    80002708:	85a6                	mv	a1,s1
    8000270a:	9566                	add	a0,a0,s9
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	3cc080e7          	jalr	972(ra) # 80001ad8 <enqueue>
          p->queue_in_time = ticks;
    80002714:	000c6783          	lwu	a5,0(s8)
    80002718:	1ef4b823          	sd	a5,496(s1)
          p->wait_time = 0;
    8000271c:	1a04b023          	sd	zero,416(s1)
    80002720:	bf9d                	j	80002696 <scheduler+0xd6>
    80002722:	00239b97          	auipc	s7,0x239
    80002726:	dc6b8b93          	addi	s7,s7,-570 # 8023b4e8 <mlfq>
    8000272a:	a88d                	j	8000279c <scheduler+0x1dc>
      while (mlfq[level].numitems)
    8000272c:	21892783          	lw	a5,536(s2)
    80002730:	c3b5                	beqz	a5,80002794 <scheduler+0x1d4>
        p = front(mlfq[level]);
    80002732:	87ca                	mv	a5,s2
    80002734:	d7040713          	addi	a4,s0,-656
    80002738:	6388                	ld	a0,0(a5)
    8000273a:	678c                	ld	a1,8(a5)
    8000273c:	6b90                	ld	a2,16(a5)
    8000273e:	6f94                	ld	a3,24(a5)
    80002740:	e308                	sd	a0,0(a4)
    80002742:	e70c                	sd	a1,8(a4)
    80002744:	eb10                	sd	a2,16(a4)
    80002746:	ef14                	sd	a3,24(a4)
    80002748:	02078793          	addi	a5,a5,32
    8000274c:	02070713          	addi	a4,a4,32
    80002750:	ff5794e3          	bne	a5,s5,80002738 <scheduler+0x178>
  return qu.arr[qu.front];
    80002754:	00492783          	lw	a5,4(s2)
    80002758:	0789                	addi	a5,a5,2
    8000275a:	078e                	slli	a5,a5,0x3
    8000275c:	f9040713          	addi	a4,s0,-112
    80002760:	97ba                	add	a5,a5,a4
    80002762:	de07b483          	ld	s1,-544(a5)
        dequeue(&mlfq[level]);
    80002766:	854a                	mv	a0,s2
    80002768:	fffff097          	auipc	ra,0xfffff
    8000276c:	3c8080e7          	jalr	968(ra) # 80001b30 <dequeue>
        if (p)
    80002770:	dcd5                	beqz	s1,8000272c <scheduler+0x16c>
          acquire(&p->lock);
    80002772:	8b26                	mv	s6,s1
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	6a0080e7          	jalr	1696(ra) # 80000e16 <acquire>
          p->queued = 0;
    8000277e:	1c04bc23          	sd	zero,472(s1)
          if (p->state == RUNNABLE)
    80002782:	4c9c                	lw	a5,24(s1)
    80002784:	03378363          	beq	a5,s3,800027aa <scheduler+0x1ea>
          release(&p->lock);
    80002788:	8526                	mv	a0,s1
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	740080e7          	jalr	1856(ra) # 80000eca <release>
    80002792:	bf69                	j	8000272c <scheduler+0x16c>
    for (int level = 0; level < 5; level++)
    80002794:	220b8b93          	addi	s7,s7,544
    80002798:	077d0863          	beq	s10,s7,80002808 <scheduler+0x248>
      while (mlfq[level].numitems)
    8000279c:	895e                	mv	s2,s7
    8000279e:	218ba783          	lw	a5,536(s7)
    800027a2:	220b8a93          	addi	s5,s7,544
    800027a6:	f7d1                	bnez	a5,80002732 <scheduler+0x172>
    800027a8:	b7f5                	j	80002794 <scheduler+0x1d4>
    proc_to_run->state = RUNNING;
    800027aa:	4791                	li	a5,4
    800027ac:	cc9c                	sw	a5,24(s1)
    if (p->quantums_left <= 0)
    800027ae:	1e04b783          	ld	a5,480(s1)
    800027b2:	eb81                	bnez	a5,800027c2 <scheduler+0x202>
      proc_to_run->quantums_left = 1 << proc_to_run->mlfq_priority;
    800027b4:	1d04b703          	ld	a4,464(s1)
    800027b8:	4785                	li	a5,1
    800027ba:	00e797bb          	sllw	a5,a5,a4
    800027be:	1ef4b023          	sd	a5,480(s1)
    c->proc = proc_to_run;
    800027c2:	029db823          	sd	s1,48(s11)
    proc_to_run->runs_till_now++;
    800027c6:	1e84b783          	ld	a5,488(s1)
    800027ca:	0785                	addi	a5,a5,1
    800027cc:	1ef4b423          	sd	a5,488(s1)
    swtch(&c->context, &proc_to_run->context);
    800027d0:	06048593          	addi	a1,s1,96
    800027d4:	d6843503          	ld	a0,-664(s0)
    800027d8:	00001097          	auipc	ra,0x1
    800027dc:	ad0080e7          	jalr	-1328(ra) # 800032a8 <swtch>
    c->proc = 0;
    800027e0:	020db823          	sd	zero,48(s11)
    proc_to_run->queue_in_time = ticks;
    800027e4:	000c6783          	lwu	a5,0(s8)
    800027e8:	1ef4b823          	sd	a5,496(s1)
    release(&proc_to_run->lock);
    800027ec:	855a                	mv	a0,s6
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	6dc080e7          	jalr	1756(ra) # 80000eca <release>
      if (p->state == RUNNABLE && !p->queued)
    800027f6:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    800027f8:	00239a17          	auipc	s4,0x239
    800027fc:	cf0a0a13          	addi	s4,s4,-784 # 8023b4e8 <mlfq>
    80002800:	00239d17          	auipc	s10,0x239
    80002804:	788d0d13          	addi	s10,s10,1928 # 8023bf88 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002808:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000280c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002810:	10079073          	csrw	sstatus,a5
    80002814:	00230497          	auipc	s1,0x230
    80002818:	ad448493          	addi	s1,s1,-1324 # 802322e8 <proc>
        p->queued = 1;
    8000281c:	4905                	li	s2,1
    8000281e:	bd99                	j	80002674 <scheduler+0xb4>

0000000080002820 <update_time>:
{
    80002820:	715d                	addi	sp,sp,-80
    80002822:	e486                	sd	ra,72(sp)
    80002824:	e0a2                	sd	s0,64(sp)
    80002826:	fc26                	sd	s1,56(sp)
    80002828:	f84a                	sd	s2,48(sp)
    8000282a:	f44e                	sd	s3,40(sp)
    8000282c:	f052                	sd	s4,32(sp)
    8000282e:	ec56                	sd	s5,24(sp)
    80002830:	e85a                	sd	s6,16(sp)
    80002832:	e45e                	sd	s7,8(sp)
    80002834:	e062                	sd	s8,0(sp)
    80002836:	0880                	addi	s0,sp,80
  for (p = proc; p < &proc[NPROC]; p++)
    80002838:	00230497          	auipc	s1,0x230
    8000283c:	ab048493          	addi	s1,s1,-1360 # 802322e8 <proc>
    if (p->state == RUNNING)
    80002840:	4991                	li	s3,4
    else if (p->state == SLEEPING)
    80002842:	4a09                	li	s4,2
    else if (p->state == RUNNABLE)
    80002844:	4a8d                	li	s5,3
        queue_swap(&mlfq[p->mlfq_priority], p->pid);
    80002846:	00239b17          	auipc	s6,0x239
    8000284a:	ca2b0b13          	addi	s6,s6,-862 # 8023b4e8 <mlfq>
        p->queued = 1;
    8000284e:	4c05                	li	s8,1
        p->queue_in_time = ticks;
    80002850:	00007b97          	auipc	s7,0x7
    80002854:	3e0b8b93          	addi	s7,s7,992 # 80009c30 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002858:	00239917          	auipc	s2,0x239
    8000285c:	c9090913          	addi	s2,s2,-880 # 8023b4e8 <mlfq>
    80002860:	a091                	j	800028a4 <update_time+0x84>
      p->run_time++;
    80002862:	1a84b783          	ld	a5,424(s1)
    80002866:	0785                	addi	a5,a5,1
    80002868:	1af4b423          	sd	a5,424(s1)
      p->total_run_time++;
    8000286c:	1c84b783          	ld	a5,456(s1)
    80002870:	0785                	addi	a5,a5,1
    80002872:	1cf4b423          	sd	a5,456(s1)
      p->quantums_left--;
    80002876:	1e04b783          	ld	a5,480(s1)
    8000287a:	17fd                	addi	a5,a5,-1
    8000287c:	1ef4b023          	sd	a5,480(s1)
      p->queue_run_time[p->mlfq_priority]++;
    80002880:	1d04b783          	ld	a5,464(s1)
    80002884:	078e                	slli	a5,a5,0x3
    80002886:	97a6                	add	a5,a5,s1
    80002888:	1f87b703          	ld	a4,504(a5)
    8000288c:	0705                	addi	a4,a4,1
    8000288e:	1ee7bc23          	sd	a4,504(a5)
    release(&p->lock);
    80002892:	8526                	mv	a0,s1
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	636080e7          	jalr	1590(ra) # 80000eca <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289c:	24848493          	addi	s1,s1,584
    800028a0:	0b248563          	beq	s1,s2,8000294a <update_time+0x12a>
    acquire(&p->lock);
    800028a4:	8526                	mv	a0,s1
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	570080e7          	jalr	1392(ra) # 80000e16 <acquire>
    if (p->queued)
    800028ae:	1d84b703          	ld	a4,472(s1)
    800028b2:	cb11                	beqz	a4,800028c6 <update_time+0xa6>
      p->queue_run_time[p->mlfq_priority]++;
    800028b4:	1d04b783          	ld	a5,464(s1)
    800028b8:	078e                	slli	a5,a5,0x3
    800028ba:	97a6                	add	a5,a5,s1
    800028bc:	1f87b683          	ld	a3,504(a5)
    800028c0:	0685                	addi	a3,a3,1
    800028c2:	1ed7bc23          	sd	a3,504(a5)
    if (p->state == RUNNING)
    800028c6:	4c9c                	lw	a5,24(s1)
    800028c8:	f9378de3          	beq	a5,s3,80002862 <update_time+0x42>
    else if (p->state == SLEEPING)
    800028cc:	07478963          	beq	a5,s4,8000293e <update_time+0x11e>
    else if (p->state == RUNNABLE)
    800028d0:	fd5791e3          	bne	a5,s5,80002892 <update_time+0x72>
      p->wait_time++;
    800028d4:	1a04b683          	ld	a3,416(s1)
    800028d8:	0685                	addi	a3,a3,1
    800028da:	1ad4b023          	sd	a3,416(s1)
      if (p && p->wait_time > p->age_queue[p->mlfq_priority] && p->queued && p->mlfq_priority)
    800028de:	1d04b603          	ld	a2,464(s1)
    800028e2:	04460793          	addi	a5,a2,68 # 1044 <_entry-0x7fffefbc>
    800028e6:	078e                	slli	a5,a5,0x3
    800028e8:	97a6                	add	a5,a5,s1
    800028ea:	639c                	ld	a5,0(a5)
    800028ec:	fad7f3e3          	bgeu	a5,a3,80002892 <update_time+0x72>
    800028f0:	d34d                	beqz	a4,80002892 <update_time+0x72>
    800028f2:	d245                	beqz	a2,80002892 <update_time+0x72>
        queue_swap(&mlfq[p->mlfq_priority], p->pid);
    800028f4:	00461513          	slli	a0,a2,0x4
    800028f8:	962a                	add	a2,a2,a0
    800028fa:	00561513          	slli	a0,a2,0x5
    800028fe:	588c                	lw	a1,48(s1)
    80002900:	955a                	add	a0,a0,s6
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	61e080e7          	jalr	1566(ra) # 80001f20 <queue_swap>
        p->queued = 0;
    8000290a:	1c04bc23          	sd	zero,472(s1)
        p->mlfq_priority--;
    8000290e:	1d04b783          	ld	a5,464(s1)
    80002912:	17fd                	addi	a5,a5,-1
    80002914:	1cf4b823          	sd	a5,464(s1)
        enqueue(&mlfq[p->mlfq_priority], p);
    80002918:	00479513          	slli	a0,a5,0x4
    8000291c:	953e                	add	a0,a0,a5
    8000291e:	0516                	slli	a0,a0,0x5
    80002920:	85a6                	mv	a1,s1
    80002922:	955a                	add	a0,a0,s6
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	1b4080e7          	jalr	436(ra) # 80001ad8 <enqueue>
        p->queued = 1;
    8000292c:	1d84bc23          	sd	s8,472(s1)
        p->wait_time = 0;
    80002930:	1a04b023          	sd	zero,416(s1)
        p->queue_in_time = ticks;
    80002934:	000be783          	lwu	a5,0(s7)
    80002938:	1ef4b823          	sd	a5,496(s1)
    8000293c:	bf99                	j	80002892 <update_time+0x72>
      p->sleep_time++;
    8000293e:	1b84b783          	ld	a5,440(s1)
    80002942:	0785                	addi	a5,a5,1
    80002944:	1af4bc23          	sd	a5,440(s1)
    80002948:	b7a9                	j	80002892 <update_time+0x72>
}
    8000294a:	60a6                	ld	ra,72(sp)
    8000294c:	6406                	ld	s0,64(sp)
    8000294e:	74e2                	ld	s1,56(sp)
    80002950:	7942                	ld	s2,48(sp)
    80002952:	79a2                	ld	s3,40(sp)
    80002954:	7a02                	ld	s4,32(sp)
    80002956:	6ae2                	ld	s5,24(sp)
    80002958:	6b42                	ld	s6,16(sp)
    8000295a:	6ba2                	ld	s7,8(sp)
    8000295c:	6c02                	ld	s8,0(sp)
    8000295e:	6161                	addi	sp,sp,80
    80002960:	8082                	ret

0000000080002962 <sched>:
{
    80002962:	7179                	addi	sp,sp,-48
    80002964:	f406                	sd	ra,40(sp)
    80002966:	f022                	sd	s0,32(sp)
    80002968:	ec26                	sd	s1,24(sp)
    8000296a:	e84a                	sd	s2,16(sp)
    8000296c:	e44e                	sd	s3,8(sp)
    8000296e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	492080e7          	jalr	1170(ra) # 80001e02 <myproc>
    80002978:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	422080e7          	jalr	1058(ra) # 80000d9c <holding>
    80002982:	c93d                	beqz	a0,800029f8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002984:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002986:	2781                	sext.w	a5,a5
    80002988:	079e                	slli	a5,a5,0x7
    8000298a:	0022f717          	auipc	a4,0x22f
    8000298e:	52e70713          	addi	a4,a4,1326 # 80231eb8 <pid_lock>
    80002992:	97ba                	add	a5,a5,a4
    80002994:	0a87a703          	lw	a4,168(a5)
    80002998:	4785                	li	a5,1
    8000299a:	06f71763          	bne	a4,a5,80002a08 <sched+0xa6>
  if (p->state == RUNNING)
    8000299e:	4c98                	lw	a4,24(s1)
    800029a0:	4791                	li	a5,4
    800029a2:	06f70b63          	beq	a4,a5,80002a18 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029aa:	8b89                	andi	a5,a5,2
  if (intr_get())
    800029ac:	efb5                	bnez	a5,80002a28 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800029ae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800029b0:	0022f917          	auipc	s2,0x22f
    800029b4:	50890913          	addi	s2,s2,1288 # 80231eb8 <pid_lock>
    800029b8:	2781                	sext.w	a5,a5
    800029ba:	079e                	slli	a5,a5,0x7
    800029bc:	97ca                	add	a5,a5,s2
    800029be:	0ac7a983          	lw	s3,172(a5)
    800029c2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800029c4:	2781                	sext.w	a5,a5
    800029c6:	079e                	slli	a5,a5,0x7
    800029c8:	0022f597          	auipc	a1,0x22f
    800029cc:	52858593          	addi	a1,a1,1320 # 80231ef0 <cpus+0x8>
    800029d0:	95be                	add	a1,a1,a5
    800029d2:	06048513          	addi	a0,s1,96
    800029d6:	00001097          	auipc	ra,0x1
    800029da:	8d2080e7          	jalr	-1838(ra) # 800032a8 <swtch>
    800029de:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800029e0:	2781                	sext.w	a5,a5
    800029e2:	079e                	slli	a5,a5,0x7
    800029e4:	97ca                	add	a5,a5,s2
    800029e6:	0b37a623          	sw	s3,172(a5)
}
    800029ea:	70a2                	ld	ra,40(sp)
    800029ec:	7402                	ld	s0,32(sp)
    800029ee:	64e2                	ld	s1,24(sp)
    800029f0:	6942                	ld	s2,16(sp)
    800029f2:	69a2                	ld	s3,8(sp)
    800029f4:	6145                	addi	sp,sp,48
    800029f6:	8082                	ret
    panic("sched p->lock");
    800029f8:	00007517          	auipc	a0,0x7
    800029fc:	85850513          	addi	a0,a0,-1960 # 80009250 <digits+0x210>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b44080e7          	jalr	-1212(ra) # 80000544 <panic>
    panic("sched locks");
    80002a08:	00007517          	auipc	a0,0x7
    80002a0c:	85850513          	addi	a0,a0,-1960 # 80009260 <digits+0x220>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b34080e7          	jalr	-1228(ra) # 80000544 <panic>
    panic("sched running");
    80002a18:	00007517          	auipc	a0,0x7
    80002a1c:	85850513          	addi	a0,a0,-1960 # 80009270 <digits+0x230>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b24080e7          	jalr	-1244(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002a28:	00007517          	auipc	a0,0x7
    80002a2c:	85850513          	addi	a0,a0,-1960 # 80009280 <digits+0x240>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b14080e7          	jalr	-1260(ra) # 80000544 <panic>

0000000080002a38 <yield>:
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	e426                	sd	s1,8(sp)
    80002a40:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	3c0080e7          	jalr	960(ra) # 80001e02 <myproc>
    80002a4a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	3ca080e7          	jalr	970(ra) # 80000e16 <acquire>
  p->state = RUNNABLE;
    80002a54:	478d                	li	a5,3
    80002a56:	cc9c                	sw	a5,24(s1)
  if (!p->queued)
    80002a58:	1d84b783          	ld	a5,472(s1)
    80002a5c:	cf99                	beqz	a5,80002a7a <yield+0x42>
  sched();
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	f04080e7          	jalr	-252(ra) # 80002962 <sched>
  release(&p->lock);
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	462080e7          	jalr	1122(ra) # 80000eca <release>
}
    80002a70:	60e2                	ld	ra,24(sp)
    80002a72:	6442                	ld	s0,16(sp)
    80002a74:	64a2                	ld	s1,8(sp)
    80002a76:	6105                	addi	sp,sp,32
    80002a78:	8082                	ret
    enqueue(&mlfq[p->mlfq_priority], p);
    80002a7a:	1d04b503          	ld	a0,464(s1)
    80002a7e:	00451793          	slli	a5,a0,0x4
    80002a82:	97aa                	add	a5,a5,a0
    80002a84:	0796                	slli	a5,a5,0x5
    80002a86:	85a6                	mv	a1,s1
    80002a88:	00239517          	auipc	a0,0x239
    80002a8c:	a6050513          	addi	a0,a0,-1440 # 8023b4e8 <mlfq>
    80002a90:	953e                	add	a0,a0,a5
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	046080e7          	jalr	70(ra) # 80001ad8 <enqueue>
    p->wait_time = 0;
    80002a9a:	1a04b023          	sd	zero,416(s1)
    p->queued = 1;
    80002a9e:	4785                	li	a5,1
    80002aa0:	1cf4bc23          	sd	a5,472(s1)
    p->queue_in_time = ticks;
    80002aa4:	00007797          	auipc	a5,0x7
    80002aa8:	18c7e783          	lwu	a5,396(a5) # 80009c30 <ticks>
    80002aac:	1ef4b823          	sd	a5,496(s1)
    80002ab0:	b77d                	j	80002a5e <yield+0x26>

0000000080002ab2 <set_priority>:
{
    80002ab2:	7179                	addi	sp,sp,-48
    80002ab4:	f406                	sd	ra,40(sp)
    80002ab6:	f022                	sd	s0,32(sp)
    80002ab8:	ec26                	sd	s1,24(sp)
    80002aba:	e84a                	sd	s2,16(sp)
    80002abc:	e44e                	sd	s3,8(sp)
    80002abe:	e052                	sd	s4,0(sp)
    80002ac0:	1800                	addi	s0,sp,48
    80002ac2:	8a2a                	mv	s4,a0
    80002ac4:	892e                	mv	s2,a1
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac6:	00230497          	auipc	s1,0x230
    80002aca:	82248493          	addi	s1,s1,-2014 # 802322e8 <proc>
    80002ace:	00239997          	auipc	s3,0x239
    80002ad2:	a1a98993          	addi	s3,s3,-1510 # 8023b4e8 <mlfq>
    acquire(&p->lock);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	33e080e7          	jalr	830(ra) # 80000e16 <acquire>
    if (p->pid == proc_pid)
    80002ae0:	589c                	lw	a5,48(s1)
    80002ae2:	03278663          	beq	a5,s2,80002b0e <set_priority+0x5c>
    release(&p->lock);
    80002ae6:	8526                	mv	a0,s1
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	3e2080e7          	jalr	994(ra) # 80000eca <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002af0:	24848493          	addi	s1,s1,584
    80002af4:	ff3491e3          	bne	s1,s3,80002ad6 <set_priority+0x24>
    printf("no process with pid : %d exists\n", proc_pid);
    80002af8:	85ca                	mv	a1,s2
    80002afa:	00006517          	auipc	a0,0x6
    80002afe:	79e50513          	addi	a0,a0,1950 # 80009298 <digits+0x258>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	a8c080e7          	jalr	-1396(ra) # 8000058e <printf>
  int old_priority = 0, found = 0;
    80002b0a:	4901                	li	s2,0
    80002b0c:	a831                	j	80002b28 <set_priority+0x76>
      old_priority = p->stat_priority;
    80002b0e:	1904a903          	lw	s2,400(s1)
      p->run_time = 0;
    80002b12:	1a04b423          	sd	zero,424(s1)
      p->stat_priority = new_priority;
    80002b16:	1944a823          	sw	s4,400(s1)
      release(&p->lock);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	3ae080e7          	jalr	942(ra) # 80000eca <release>
      if (old_priority >= new_priority)
    80002b24:	01494b63          	blt	s2,s4,80002b3a <set_priority+0x88>
}
    80002b28:	854a                	mv	a0,s2
    80002b2a:	70a2                	ld	ra,40(sp)
    80002b2c:	7402                	ld	s0,32(sp)
    80002b2e:	64e2                	ld	s1,24(sp)
    80002b30:	6942                	ld	s2,16(sp)
    80002b32:	69a2                	ld	s3,8(sp)
    80002b34:	6a02                	ld	s4,0(sp)
    80002b36:	6145                	addi	sp,sp,48
    80002b38:	8082                	ret
      yield();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	efe080e7          	jalr	-258(ra) # 80002a38 <yield>
  if (!found)
    80002b42:	b7dd                	j	80002b28 <set_priority+0x76>

0000000080002b44 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002b44:	7179                	addi	sp,sp,-48
    80002b46:	f406                	sd	ra,40(sp)
    80002b48:	f022                	sd	s0,32(sp)
    80002b4a:	ec26                	sd	s1,24(sp)
    80002b4c:	e84a                	sd	s2,16(sp)
    80002b4e:	e44e                	sd	s3,8(sp)
    80002b50:	1800                	addi	s0,sp,48
    80002b52:	89aa                	mv	s3,a0
    80002b54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	2ac080e7          	jalr	684(ra) # 80001e02 <myproc>
    80002b5e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	2b6080e7          	jalr	694(ra) # 80000e16 <acquire>
  release(lk);
    80002b68:	854a                	mv	a0,s2
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	360080e7          	jalr	864(ra) # 80000eca <release>

  // Go to sleep.
  p->chan = chan;
    80002b72:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002b76:	4789                	li	a5,2
    80002b78:	cc9c                	sw	a5,24(s1)

  sched();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	de8080e7          	jalr	-536(ra) # 80002962 <sched>

  // Tidy up.
  p->chan = 0;
    80002b82:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	342080e7          	jalr	834(ra) # 80000eca <release>
  acquire(lk);
    80002b90:	854a                	mv	a0,s2
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	284080e7          	jalr	644(ra) # 80000e16 <acquire>
}
    80002b9a:	70a2                	ld	ra,40(sp)
    80002b9c:	7402                	ld	s0,32(sp)
    80002b9e:	64e2                	ld	s1,24(sp)
    80002ba0:	6942                	ld	s2,16(sp)
    80002ba2:	69a2                	ld	s3,8(sp)
    80002ba4:	6145                	addi	sp,sp,48
    80002ba6:	8082                	ret

0000000080002ba8 <wait>:
{
    80002ba8:	715d                	addi	sp,sp,-80
    80002baa:	e486                	sd	ra,72(sp)
    80002bac:	e0a2                	sd	s0,64(sp)
    80002bae:	fc26                	sd	s1,56(sp)
    80002bb0:	f84a                	sd	s2,48(sp)
    80002bb2:	f44e                	sd	s3,40(sp)
    80002bb4:	f052                	sd	s4,32(sp)
    80002bb6:	ec56                	sd	s5,24(sp)
    80002bb8:	e85a                	sd	s6,16(sp)
    80002bba:	e45e                	sd	s7,8(sp)
    80002bbc:	e062                	sd	s8,0(sp)
    80002bbe:	0880                	addi	s0,sp,80
    80002bc0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	240080e7          	jalr	576(ra) # 80001e02 <myproc>
    80002bca:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002bcc:	0022f517          	auipc	a0,0x22f
    80002bd0:	30450513          	addi	a0,a0,772 # 80231ed0 <wait_lock>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	242080e7          	jalr	578(ra) # 80000e16 <acquire>
    havekids = 0;
    80002bdc:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002bde:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002be0:	00239997          	auipc	s3,0x239
    80002be4:	90898993          	addi	s3,s3,-1784 # 8023b4e8 <mlfq>
        havekids = 1;
    80002be8:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002bea:	0022fc17          	auipc	s8,0x22f
    80002bee:	2e6c0c13          	addi	s8,s8,742 # 80231ed0 <wait_lock>
    havekids = 0;
    80002bf2:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002bf4:	0022f497          	auipc	s1,0x22f
    80002bf8:	6f448493          	addi	s1,s1,1780 # 802322e8 <proc>
    80002bfc:	a0bd                	j	80002c6a <wait+0xc2>
          pid = pp->pid;
    80002bfe:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002c02:	000b0e63          	beqz	s6,80002c1e <wait+0x76>
    80002c06:	4691                	li	a3,4
    80002c08:	02c48613          	addi	a2,s1,44
    80002c0c:	85da                	mv	a1,s6
    80002c0e:	05093503          	ld	a0,80(s2)
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	caa080e7          	jalr	-854(ra) # 800018bc <copyout>
    80002c1a:	02054563          	bltz	a0,80002c44 <wait+0x9c>
          freeproc(pp);
    80002c1e:	8526                	mv	a0,s1
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	452080e7          	jalr	1106(ra) # 80002072 <freeproc>
          release(&pp->lock);
    80002c28:	8526                	mv	a0,s1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	2a0080e7          	jalr	672(ra) # 80000eca <release>
          release(&wait_lock);
    80002c32:	0022f517          	auipc	a0,0x22f
    80002c36:	29e50513          	addi	a0,a0,670 # 80231ed0 <wait_lock>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	290080e7          	jalr	656(ra) # 80000eca <release>
          return pid;
    80002c42:	a09d                	j	80002ca8 <wait+0x100>
            release(&pp->lock);
    80002c44:	8526                	mv	a0,s1
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	284080e7          	jalr	644(ra) # 80000eca <release>
            release(&wait_lock);
    80002c4e:	0022f517          	auipc	a0,0x22f
    80002c52:	28250513          	addi	a0,a0,642 # 80231ed0 <wait_lock>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	274080e7          	jalr	628(ra) # 80000eca <release>
            return -1;
    80002c5e:	59fd                	li	s3,-1
    80002c60:	a0a1                	j	80002ca8 <wait+0x100>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002c62:	24848493          	addi	s1,s1,584
    80002c66:	03348463          	beq	s1,s3,80002c8e <wait+0xe6>
      if (pp->parent == p)
    80002c6a:	7c9c                	ld	a5,56(s1)
    80002c6c:	ff279be3          	bne	a5,s2,80002c62 <wait+0xba>
        acquire(&pp->lock);
    80002c70:	8526                	mv	a0,s1
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	1a4080e7          	jalr	420(ra) # 80000e16 <acquire>
        if (pp->state == ZOMBIE)
    80002c7a:	4c9c                	lw	a5,24(s1)
    80002c7c:	f94781e3          	beq	a5,s4,80002bfe <wait+0x56>
        release(&pp->lock);
    80002c80:	8526                	mv	a0,s1
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	248080e7          	jalr	584(ra) # 80000eca <release>
        havekids = 1;
    80002c8a:	8756                	mv	a4,s5
    80002c8c:	bfd9                	j	80002c62 <wait+0xba>
    if (!havekids || p->killed)
    80002c8e:	c701                	beqz	a4,80002c96 <wait+0xee>
    80002c90:	02892783          	lw	a5,40(s2)
    80002c94:	c79d                	beqz	a5,80002cc2 <wait+0x11a>
      release(&wait_lock);
    80002c96:	0022f517          	auipc	a0,0x22f
    80002c9a:	23a50513          	addi	a0,a0,570 # 80231ed0 <wait_lock>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	22c080e7          	jalr	556(ra) # 80000eca <release>
      return -1;
    80002ca6:	59fd                	li	s3,-1
}
    80002ca8:	854e                	mv	a0,s3
    80002caa:	60a6                	ld	ra,72(sp)
    80002cac:	6406                	ld	s0,64(sp)
    80002cae:	74e2                	ld	s1,56(sp)
    80002cb0:	7942                	ld	s2,48(sp)
    80002cb2:	79a2                	ld	s3,40(sp)
    80002cb4:	7a02                	ld	s4,32(sp)
    80002cb6:	6ae2                	ld	s5,24(sp)
    80002cb8:	6b42                	ld	s6,16(sp)
    80002cba:	6ba2                	ld	s7,8(sp)
    80002cbc:	6c02                	ld	s8,0(sp)
    80002cbe:	6161                	addi	sp,sp,80
    80002cc0:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002cc2:	85e2                	mv	a1,s8
    80002cc4:	854a                	mv	a0,s2
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	e7e080e7          	jalr	-386(ra) # 80002b44 <sleep>
    havekids = 0;
    80002cce:	b715                	j	80002bf2 <wait+0x4a>

0000000080002cd0 <waitx>:
{
    80002cd0:	711d                	addi	sp,sp,-96
    80002cd2:	ec86                	sd	ra,88(sp)
    80002cd4:	e8a2                	sd	s0,80(sp)
    80002cd6:	e4a6                	sd	s1,72(sp)
    80002cd8:	e0ca                	sd	s2,64(sp)
    80002cda:	fc4e                	sd	s3,56(sp)
    80002cdc:	f852                	sd	s4,48(sp)
    80002cde:	f456                	sd	s5,40(sp)
    80002ce0:	f05a                	sd	s6,32(sp)
    80002ce2:	ec5e                	sd	s7,24(sp)
    80002ce4:	e862                	sd	s8,16(sp)
    80002ce6:	e466                	sd	s9,8(sp)
    80002ce8:	e06a                	sd	s10,0(sp)
    80002cea:	1080                	addi	s0,sp,96
    80002cec:	8b2a                	mv	s6,a0
    80002cee:	8c2e                	mv	s8,a1
    80002cf0:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	110080e7          	jalr	272(ra) # 80001e02 <myproc>
    80002cfa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002cfc:	0022f517          	auipc	a0,0x22f
    80002d00:	1d450513          	addi	a0,a0,468 # 80231ed0 <wait_lock>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	112080e7          	jalr	274(ra) # 80000e16 <acquire>
    havekids = 0;
    80002d0c:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    80002d0e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002d10:	00238997          	auipc	s3,0x238
    80002d14:	7d898993          	addi	s3,s3,2008 # 8023b4e8 <mlfq>
        havekids = 1;
    80002d18:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d1a:	0022fd17          	auipc	s10,0x22f
    80002d1e:	1b6d0d13          	addi	s10,s10,438 # 80231ed0 <wait_lock>
    havekids = 0;
    80002d22:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002d24:	0022f497          	auipc	s1,0x22f
    80002d28:	5c448493          	addi	s1,s1,1476 # 802322e8 <proc>
    80002d2c:	a069                	j	80002db6 <waitx+0xe6>
          pid = np->pid;
    80002d2e:	0304a983          	lw	s3,48(s1)
          *rtime = np->total_run_time;
    80002d32:	1c84b783          	ld	a5,456(s1)
    80002d36:	00fc2023          	sw	a5,0(s8)
          *wtime = np->end_time - np->init_time - np->total_run_time;
    80002d3a:	1b04b783          	ld	a5,432(s1)
    80002d3e:	1984b703          	ld	a4,408(s1)
    80002d42:	1c84b683          	ld	a3,456(s1)
    80002d46:	9f35                	addw	a4,a4,a3
    80002d48:	9f99                	subw	a5,a5,a4
    80002d4a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d4e:	000b0e63          	beqz	s6,80002d6a <waitx+0x9a>
    80002d52:	4691                	li	a3,4
    80002d54:	02c48613          	addi	a2,s1,44
    80002d58:	85da                	mv	a1,s6
    80002d5a:	05093503          	ld	a0,80(s2)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	b5e080e7          	jalr	-1186(ra) # 800018bc <copyout>
    80002d66:	02054563          	bltz	a0,80002d90 <waitx+0xc0>
          freeproc(np);
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	306080e7          	jalr	774(ra) # 80002072 <freeproc>
          release(&np->lock);
    80002d74:	8526                	mv	a0,s1
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	154080e7          	jalr	340(ra) # 80000eca <release>
          release(&wait_lock);
    80002d7e:	0022f517          	auipc	a0,0x22f
    80002d82:	15250513          	addi	a0,a0,338 # 80231ed0 <wait_lock>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	144080e7          	jalr	324(ra) # 80000eca <release>
          return pid;
    80002d8e:	a09d                	j	80002df4 <waitx+0x124>
            release(&np->lock);
    80002d90:	8526                	mv	a0,s1
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	138080e7          	jalr	312(ra) # 80000eca <release>
            release(&wait_lock);
    80002d9a:	0022f517          	auipc	a0,0x22f
    80002d9e:	13650513          	addi	a0,a0,310 # 80231ed0 <wait_lock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	128080e7          	jalr	296(ra) # 80000eca <release>
            return -1;
    80002daa:	59fd                	li	s3,-1
    80002dac:	a0a1                	j	80002df4 <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    80002dae:	24848493          	addi	s1,s1,584
    80002db2:	03348463          	beq	s1,s3,80002dda <waitx+0x10a>
      if (np->parent == p)
    80002db6:	7c9c                	ld	a5,56(s1)
    80002db8:	ff279be3          	bne	a5,s2,80002dae <waitx+0xde>
        acquire(&np->lock);
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	058080e7          	jalr	88(ra) # 80000e16 <acquire>
        if (np->state == ZOMBIE)
    80002dc6:	4c9c                	lw	a5,24(s1)
    80002dc8:	f74783e3          	beq	a5,s4,80002d2e <waitx+0x5e>
        release(&np->lock);
    80002dcc:	8526                	mv	a0,s1
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	0fc080e7          	jalr	252(ra) # 80000eca <release>
        havekids = 1;
    80002dd6:	8756                	mv	a4,s5
    80002dd8:	bfd9                	j	80002dae <waitx+0xde>
    if (!havekids || p->killed)
    80002dda:	c701                	beqz	a4,80002de2 <waitx+0x112>
    80002ddc:	02892783          	lw	a5,40(s2)
    80002de0:	cb8d                	beqz	a5,80002e12 <waitx+0x142>
      release(&wait_lock);
    80002de2:	0022f517          	auipc	a0,0x22f
    80002de6:	0ee50513          	addi	a0,a0,238 # 80231ed0 <wait_lock>
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	0e0080e7          	jalr	224(ra) # 80000eca <release>
      return -1;
    80002df2:	59fd                	li	s3,-1
}
    80002df4:	854e                	mv	a0,s3
    80002df6:	60e6                	ld	ra,88(sp)
    80002df8:	6446                	ld	s0,80(sp)
    80002dfa:	64a6                	ld	s1,72(sp)
    80002dfc:	6906                	ld	s2,64(sp)
    80002dfe:	79e2                	ld	s3,56(sp)
    80002e00:	7a42                	ld	s4,48(sp)
    80002e02:	7aa2                	ld	s5,40(sp)
    80002e04:	7b02                	ld	s6,32(sp)
    80002e06:	6be2                	ld	s7,24(sp)
    80002e08:	6c42                	ld	s8,16(sp)
    80002e0a:	6ca2                	ld	s9,8(sp)
    80002e0c:	6d02                	ld	s10,0(sp)
    80002e0e:	6125                	addi	sp,sp,96
    80002e10:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002e12:	85ea                	mv	a1,s10
    80002e14:	854a                	mv	a0,s2
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	d2e080e7          	jalr	-722(ra) # 80002b44 <sleep>
    havekids = 0;
    80002e1e:	b711                	j	80002d22 <waitx+0x52>

0000000080002e20 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002e20:	715d                	addi	sp,sp,-80
    80002e22:	e486                	sd	ra,72(sp)
    80002e24:	e0a2                	sd	s0,64(sp)
    80002e26:	fc26                	sd	s1,56(sp)
    80002e28:	f84a                	sd	s2,48(sp)
    80002e2a:	f44e                	sd	s3,40(sp)
    80002e2c:	f052                	sd	s4,32(sp)
    80002e2e:	ec56                	sd	s5,24(sp)
    80002e30:	e85a                	sd	s6,16(sp)
    80002e32:	e45e                	sd	s7,8(sp)
    80002e34:	e062                	sd	s8,0(sp)
    80002e36:	0880                	addi	s0,sp,80
    80002e38:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002e3a:	0022f497          	auipc	s1,0x22f
    80002e3e:	4ae48493          	addi	s1,s1,1198 # 802322e8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p && p->state == SLEEPING && p->chan == chan)
    80002e42:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002e44:	4a8d                	li	s5,3
#ifdef MLFQ
        if (!p->queued)
        {
          p->queued = 1;
    80002e46:	4c05                	li	s8,1
          p->queue_in_time = ticks;
    80002e48:	00007b97          	auipc	s7,0x7
    80002e4c:	de8b8b93          	addi	s7,s7,-536 # 80009c30 <ticks>
          enqueue(&mlfq[p->mlfq_priority], p);
    80002e50:	00238b17          	auipc	s6,0x238
    80002e54:	698b0b13          	addi	s6,s6,1688 # 8023b4e8 <mlfq>
  for (p = proc; p < &proc[NPROC]; p++)
    80002e58:	00238917          	auipc	s2,0x238
    80002e5c:	69090913          	addi	s2,s2,1680 # 8023b4e8 <mlfq>
    80002e60:	a811                	j	80002e74 <wakeup+0x54>
          p->wait_time = 0;
        }
#endif
      }
      release(&p->lock);
    80002e62:	8526                	mv	a0,s1
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	066080e7          	jalr	102(ra) # 80000eca <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002e6c:	24848493          	addi	s1,s1,584
    80002e70:	05248e63          	beq	s1,s2,80002ecc <wakeup+0xac>
    if (p != myproc())
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	f8e080e7          	jalr	-114(ra) # 80001e02 <myproc>
    80002e7c:	fea488e3          	beq	s1,a0,80002e6c <wakeup+0x4c>
      acquire(&p->lock);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	f94080e7          	jalr	-108(ra) # 80000e16 <acquire>
      if (p && p->state == SLEEPING && p->chan == chan)
    80002e8a:	dce1                	beqz	s1,80002e62 <wakeup+0x42>
    80002e8c:	4c9c                	lw	a5,24(s1)
    80002e8e:	fd379ae3          	bne	a5,s3,80002e62 <wakeup+0x42>
    80002e92:	709c                	ld	a5,32(s1)
    80002e94:	fd4797e3          	bne	a5,s4,80002e62 <wakeup+0x42>
        p->state = RUNNABLE;
    80002e98:	0154ac23          	sw	s5,24(s1)
        if (!p->queued)
    80002e9c:	1d84b783          	ld	a5,472(s1)
    80002ea0:	f3e9                	bnez	a5,80002e62 <wakeup+0x42>
          p->queued = 1;
    80002ea2:	1d84bc23          	sd	s8,472(s1)
          p->queue_in_time = ticks;
    80002ea6:	000be783          	lwu	a5,0(s7)
    80002eaa:	1ef4b823          	sd	a5,496(s1)
          enqueue(&mlfq[p->mlfq_priority], p);
    80002eae:	1d04b783          	ld	a5,464(s1)
    80002eb2:	00479513          	slli	a0,a5,0x4
    80002eb6:	953e                	add	a0,a0,a5
    80002eb8:	0516                	slli	a0,a0,0x5
    80002eba:	85a6                	mv	a1,s1
    80002ebc:	955a                	add	a0,a0,s6
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	c1a080e7          	jalr	-998(ra) # 80001ad8 <enqueue>
          p->wait_time = 0;
    80002ec6:	1a04b023          	sd	zero,416(s1)
    80002eca:	bf61                	j	80002e62 <wakeup+0x42>
    }
  }
}
    80002ecc:	60a6                	ld	ra,72(sp)
    80002ece:	6406                	ld	s0,64(sp)
    80002ed0:	74e2                	ld	s1,56(sp)
    80002ed2:	7942                	ld	s2,48(sp)
    80002ed4:	79a2                	ld	s3,40(sp)
    80002ed6:	7a02                	ld	s4,32(sp)
    80002ed8:	6ae2                	ld	s5,24(sp)
    80002eda:	6b42                	ld	s6,16(sp)
    80002edc:	6ba2                	ld	s7,8(sp)
    80002ede:	6c02                	ld	s8,0(sp)
    80002ee0:	6161                	addi	sp,sp,80
    80002ee2:	8082                	ret

0000000080002ee4 <reparent>:
{
    80002ee4:	7179                	addi	sp,sp,-48
    80002ee6:	f406                	sd	ra,40(sp)
    80002ee8:	f022                	sd	s0,32(sp)
    80002eea:	ec26                	sd	s1,24(sp)
    80002eec:	e84a                	sd	s2,16(sp)
    80002eee:	e44e                	sd	s3,8(sp)
    80002ef0:	e052                	sd	s4,0(sp)
    80002ef2:	1800                	addi	s0,sp,48
    80002ef4:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002ef6:	0022f497          	auipc	s1,0x22f
    80002efa:	3f248493          	addi	s1,s1,1010 # 802322e8 <proc>
      pp->parent = initproc;
    80002efe:	00007a17          	auipc	s4,0x7
    80002f02:	d2aa0a13          	addi	s4,s4,-726 # 80009c28 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002f06:	00238997          	auipc	s3,0x238
    80002f0a:	5e298993          	addi	s3,s3,1506 # 8023b4e8 <mlfq>
    80002f0e:	a029                	j	80002f18 <reparent+0x34>
    80002f10:	24848493          	addi	s1,s1,584
    80002f14:	01348d63          	beq	s1,s3,80002f2e <reparent+0x4a>
    if (pp->parent == p)
    80002f18:	7c9c                	ld	a5,56(s1)
    80002f1a:	ff279be3          	bne	a5,s2,80002f10 <reparent+0x2c>
      pp->parent = initproc;
    80002f1e:	000a3503          	ld	a0,0(s4)
    80002f22:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	efc080e7          	jalr	-260(ra) # 80002e20 <wakeup>
    80002f2c:	b7d5                	j	80002f10 <reparent+0x2c>
}
    80002f2e:	70a2                	ld	ra,40(sp)
    80002f30:	7402                	ld	s0,32(sp)
    80002f32:	64e2                	ld	s1,24(sp)
    80002f34:	6942                	ld	s2,16(sp)
    80002f36:	69a2                	ld	s3,8(sp)
    80002f38:	6a02                	ld	s4,0(sp)
    80002f3a:	6145                	addi	sp,sp,48
    80002f3c:	8082                	ret

0000000080002f3e <exit>:
{
    80002f3e:	7179                	addi	sp,sp,-48
    80002f40:	f406                	sd	ra,40(sp)
    80002f42:	f022                	sd	s0,32(sp)
    80002f44:	ec26                	sd	s1,24(sp)
    80002f46:	e84a                	sd	s2,16(sp)
    80002f48:	e44e                	sd	s3,8(sp)
    80002f4a:	e052                	sd	s4,0(sp)
    80002f4c:	1800                	addi	s0,sp,48
    80002f4e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	eb2080e7          	jalr	-334(ra) # 80001e02 <myproc>
    80002f58:	89aa                	mv	s3,a0
  if (p == initproc)
    80002f5a:	00007797          	auipc	a5,0x7
    80002f5e:	cce7b783          	ld	a5,-818(a5) # 80009c28 <initproc>
    80002f62:	0d050493          	addi	s1,a0,208
    80002f66:	15050913          	addi	s2,a0,336
    80002f6a:	02a79363          	bne	a5,a0,80002f90 <exit+0x52>
    panic("init exiting");
    80002f6e:	00006517          	auipc	a0,0x6
    80002f72:	35250513          	addi	a0,a0,850 # 800092c0 <digits+0x280>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	5ce080e7          	jalr	1486(ra) # 80000544 <panic>
      fileclose(f);
    80002f7e:	00002097          	auipc	ra,0x2
    80002f82:	6aa080e7          	jalr	1706(ra) # 80005628 <fileclose>
      p->ofile[fd] = 0;
    80002f86:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002f8a:	04a1                	addi	s1,s1,8
    80002f8c:	01248563          	beq	s1,s2,80002f96 <exit+0x58>
    if (p->ofile[fd])
    80002f90:	6088                	ld	a0,0(s1)
    80002f92:	f575                	bnez	a0,80002f7e <exit+0x40>
    80002f94:	bfdd                	j	80002f8a <exit+0x4c>
  begin_op();
    80002f96:	00002097          	auipc	ra,0x2
    80002f9a:	1c6080e7          	jalr	454(ra) # 8000515c <begin_op>
  iput(p->cwd);
    80002f9e:	1509b503          	ld	a0,336(s3)
    80002fa2:	00002097          	auipc	ra,0x2
    80002fa6:	9b2080e7          	jalr	-1614(ra) # 80004954 <iput>
  end_op();
    80002faa:	00002097          	auipc	ra,0x2
    80002fae:	232080e7          	jalr	562(ra) # 800051dc <end_op>
  p->cwd = 0;
    80002fb2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002fb6:	0022f497          	auipc	s1,0x22f
    80002fba:	f1a48493          	addi	s1,s1,-230 # 80231ed0 <wait_lock>
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	e56080e7          	jalr	-426(ra) # 80000e16 <acquire>
  reparent(p);
    80002fc8:	854e                	mv	a0,s3
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	f1a080e7          	jalr	-230(ra) # 80002ee4 <reparent>
  wakeup(p->parent);
    80002fd2:	0389b503          	ld	a0,56(s3)
    80002fd6:	00000097          	auipc	ra,0x0
    80002fda:	e4a080e7          	jalr	-438(ra) # 80002e20 <wakeup>
  acquire(&p->lock);
    80002fde:	854e                	mv	a0,s3
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	e36080e7          	jalr	-458(ra) # 80000e16 <acquire>
  p->xstate = status;
    80002fe8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002fec:	4795                	li	a5,5
    80002fee:	00f9ac23          	sw	a5,24(s3)
  p->end_time = ticks;
    80002ff2:	00007797          	auipc	a5,0x7
    80002ff6:	c3e7e783          	lwu	a5,-962(a5) # 80009c30 <ticks>
    80002ffa:	1af9b823          	sd	a5,432(s3)
  release(&wait_lock);
    80002ffe:	8526                	mv	a0,s1
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	eca080e7          	jalr	-310(ra) # 80000eca <release>
  sched();
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	95a080e7          	jalr	-1702(ra) # 80002962 <sched>
  panic("zombie exit");
    80003010:	00006517          	auipc	a0,0x6
    80003014:	2c050513          	addi	a0,a0,704 # 800092d0 <digits+0x290>
    80003018:	ffffd097          	auipc	ra,0xffffd
    8000301c:	52c080e7          	jalr	1324(ra) # 80000544 <panic>

0000000080003020 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80003020:	7179                	addi	sp,sp,-48
    80003022:	f406                	sd	ra,40(sp)
    80003024:	f022                	sd	s0,32(sp)
    80003026:	ec26                	sd	s1,24(sp)
    80003028:	e84a                	sd	s2,16(sp)
    8000302a:	e44e                	sd	s3,8(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80003030:	0022f497          	auipc	s1,0x22f
    80003034:	2b848493          	addi	s1,s1,696 # 802322e8 <proc>
    80003038:	00238997          	auipc	s3,0x238
    8000303c:	4b098993          	addi	s3,s3,1200 # 8023b4e8 <mlfq>
  {
    acquire(&p->lock);
    80003040:	8526                	mv	a0,s1
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	dd4080e7          	jalr	-556(ra) # 80000e16 <acquire>
    if (p->pid == pid)
    8000304a:	589c                	lw	a5,48(s1)
    8000304c:	01278d63          	beq	a5,s2,80003066 <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003050:	8526                	mv	a0,s1
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	e78080e7          	jalr	-392(ra) # 80000eca <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000305a:	24848493          	addi	s1,s1,584
    8000305e:	ff3491e3          	bne	s1,s3,80003040 <kill+0x20>
  }
  return -1;
    80003062:	557d                	li	a0,-1
    80003064:	a829                	j	8000307e <kill+0x5e>
      p->killed = 1;
    80003066:	4785                	li	a5,1
    80003068:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000306a:	4c98                	lw	a4,24(s1)
    8000306c:	4789                	li	a5,2
    8000306e:	00f70f63          	beq	a4,a5,8000308c <kill+0x6c>
      release(&p->lock);
    80003072:	8526                	mv	a0,s1
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	e56080e7          	jalr	-426(ra) # 80000eca <release>
      return 0;
    8000307c:	4501                	li	a0,0
}
    8000307e:	70a2                	ld	ra,40(sp)
    80003080:	7402                	ld	s0,32(sp)
    80003082:	64e2                	ld	s1,24(sp)
    80003084:	6942                	ld	s2,16(sp)
    80003086:	69a2                	ld	s3,8(sp)
    80003088:	6145                	addi	sp,sp,48
    8000308a:	8082                	ret
        p->state = RUNNABLE;
    8000308c:	478d                	li	a5,3
    8000308e:	cc9c                	sw	a5,24(s1)
        if (!p->queued)
    80003090:	1d84b783          	ld	a5,472(s1)
    80003094:	fff9                	bnez	a5,80003072 <kill+0x52>
          p->queued = 1;
    80003096:	4785                	li	a5,1
    80003098:	1cf4bc23          	sd	a5,472(s1)
          p->queue_in_time = ticks;
    8000309c:	00007797          	auipc	a5,0x7
    800030a0:	b947e783          	lwu	a5,-1132(a5) # 80009c30 <ticks>
    800030a4:	1ef4b823          	sd	a5,496(s1)
          enqueue(&mlfq[p->mlfq_priority], p);
    800030a8:	1d04b703          	ld	a4,464(s1)
    800030ac:	00471793          	slli	a5,a4,0x4
    800030b0:	97ba                	add	a5,a5,a4
    800030b2:	0796                	slli	a5,a5,0x5
    800030b4:	85a6                	mv	a1,s1
    800030b6:	00238517          	auipc	a0,0x238
    800030ba:	43250513          	addi	a0,a0,1074 # 8023b4e8 <mlfq>
    800030be:	953e                	add	a0,a0,a5
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	a18080e7          	jalr	-1512(ra) # 80001ad8 <enqueue>
    800030c8:	b76d                	j	80003072 <kill+0x52>

00000000800030ca <setkilled>:

void setkilled(struct proc *p)
{
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	d40080e7          	jalr	-704(ra) # 80000e16 <acquire>
  p->killed = 1;
    800030de:	4785                	li	a5,1
    800030e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800030e2:	8526                	mv	a0,s1
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	de6080e7          	jalr	-538(ra) # 80000eca <release>
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <killed>:

int killed(struct proc *p)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	e04a                	sd	s2,0(sp)
    80003100:	1000                	addi	s0,sp,32
    80003102:	84aa                	mv	s1,a0
  int k;
  acquire(&p->lock);
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	d12080e7          	jalr	-750(ra) # 80000e16 <acquire>
  k = p->killed;
    8000310c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80003110:	8526                	mv	a0,s1
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	db8080e7          	jalr	-584(ra) # 80000eca <release>
  return k;
}
    8000311a:	854a                	mv	a0,s2
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	64a2                	ld	s1,8(sp)
    80003122:	6902                	ld	s2,0(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret

0000000080003128 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80003128:	7179                	addi	sp,sp,-48
    8000312a:	f406                	sd	ra,40(sp)
    8000312c:	f022                	sd	s0,32(sp)
    8000312e:	ec26                	sd	s1,24(sp)
    80003130:	e84a                	sd	s2,16(sp)
    80003132:	e44e                	sd	s3,8(sp)
    80003134:	e052                	sd	s4,0(sp)
    80003136:	1800                	addi	s0,sp,48
    80003138:	84aa                	mv	s1,a0
    8000313a:	892e                	mv	s2,a1
    8000313c:	89b2                	mv	s3,a2
    8000313e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	cc2080e7          	jalr	-830(ra) # 80001e02 <myproc>
  if (user_dst)
    80003148:	c08d                	beqz	s1,8000316a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000314a:	86d2                	mv	a3,s4
    8000314c:	864e                	mv	a2,s3
    8000314e:	85ca                	mv	a1,s2
    80003150:	6928                	ld	a0,80(a0)
    80003152:	ffffe097          	auipc	ra,0xffffe
    80003156:	76a080e7          	jalr	1898(ra) # 800018bc <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000315a:	70a2                	ld	ra,40(sp)
    8000315c:	7402                	ld	s0,32(sp)
    8000315e:	64e2                	ld	s1,24(sp)
    80003160:	6942                	ld	s2,16(sp)
    80003162:	69a2                	ld	s3,8(sp)
    80003164:	6a02                	ld	s4,0(sp)
    80003166:	6145                	addi	sp,sp,48
    80003168:	8082                	ret
    memmove((char *)dst, src, len);
    8000316a:	000a061b          	sext.w	a2,s4
    8000316e:	85ce                	mv	a1,s3
    80003170:	854a                	mv	a0,s2
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	e00080e7          	jalr	-512(ra) # 80000f72 <memmove>
    return 0;
    8000317a:	8526                	mv	a0,s1
    8000317c:	bff9                	j	8000315a <either_copyout+0x32>

000000008000317e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000317e:	7179                	addi	sp,sp,-48
    80003180:	f406                	sd	ra,40(sp)
    80003182:	f022                	sd	s0,32(sp)
    80003184:	ec26                	sd	s1,24(sp)
    80003186:	e84a                	sd	s2,16(sp)
    80003188:	e44e                	sd	s3,8(sp)
    8000318a:	e052                	sd	s4,0(sp)
    8000318c:	1800                	addi	s0,sp,48
    8000318e:	892a                	mv	s2,a0
    80003190:	84ae                	mv	s1,a1
    80003192:	89b2                	mv	s3,a2
    80003194:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	c6c080e7          	jalr	-916(ra) # 80001e02 <myproc>
  if (user_src)
    8000319e:	c08d                	beqz	s1,800031c0 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800031a0:	86d2                	mv	a3,s4
    800031a2:	864e                	mv	a2,s3
    800031a4:	85ca                	mv	a1,s2
    800031a6:	6928                	ld	a0,80(a0)
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	7d8080e7          	jalr	2008(ra) # 80001980 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800031b0:	70a2                	ld	ra,40(sp)
    800031b2:	7402                	ld	s0,32(sp)
    800031b4:	64e2                	ld	s1,24(sp)
    800031b6:	6942                	ld	s2,16(sp)
    800031b8:	69a2                	ld	s3,8(sp)
    800031ba:	6a02                	ld	s4,0(sp)
    800031bc:	6145                	addi	sp,sp,48
    800031be:	8082                	ret
    memmove(dst, (char *)src, len);
    800031c0:	000a061b          	sext.w	a2,s4
    800031c4:	85ce                	mv	a1,s3
    800031c6:	854a                	mv	a0,s2
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	daa080e7          	jalr	-598(ra) # 80000f72 <memmove>
    return 0;
    800031d0:	8526                	mv	a0,s1
    800031d2:	bff9                	j	800031b0 <either_copyin+0x32>

00000000800031d4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800031d4:	7159                	addi	sp,sp,-112
    800031d6:	f486                	sd	ra,104(sp)
    800031d8:	f0a2                	sd	s0,96(sp)
    800031da:	eca6                	sd	s1,88(sp)
    800031dc:	e8ca                	sd	s2,80(sp)
    800031de:	e4ce                	sd	s3,72(sp)
    800031e0:	e0d2                	sd	s4,64(sp)
    800031e2:	fc56                	sd	s5,56(sp)
    800031e4:	f85a                	sd	s6,48(sp)
    800031e6:	f45e                	sd	s7,40(sp)
    800031e8:	1880                	addi	s0,sp,112
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;
  printf("\n");
    800031ea:	00006517          	auipc	a0,0x6
    800031ee:	11e50513          	addi	a0,a0,286 # 80009308 <digits+0x2c8>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	39c080e7          	jalr	924(ra) # 8000058e <printf>

  for (p = proc; p < &proc[NPROC]; p++)
    800031fa:	0022f497          	auipc	s1,0x22f
    800031fe:	0ee48493          	addi	s1,s1,238 # 802322e8 <proc>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003202:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003204:	00006997          	auipc	s3,0x6
    80003208:	0dc98993          	addi	s3,s3,220 # 800092e0 <digits+0x2a0>
#else
#ifdef LBS
    printf("%d %s %sc%d\n", p->pid, state, p->name, p->tickets);
#else
#ifdef MLFQ
    int wtime = ticks - p->init_time - p->total_run_time;
    8000320c:	00007a97          	auipc	s5,0x7
    80003210:	a24a8a93          	addi	s5,s5,-1500 # 80009c30 <ticks>
    printf("%d %d %s %d %d %d %d %d %d %d %d\n", p->pid, p->mlfq_priority, state, p->total_run_time, wtime, p->runs_till_now, p->queue_run_time[0], p->queue_run_time[1], p->queue_run_time[2], p->queue_run_time[3], p->queue_run_time[4]);
    80003214:	00006a17          	auipc	s4,0x6
    80003218:	0d4a0a13          	addi	s4,s4,212 # 800092e8 <digits+0x2a8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000321c:	00006b97          	auipc	s7,0x6
    80003220:	124b8b93          	addi	s7,s7,292 # 80009340 <states.1902>
  for (p = proc; p < &proc[NPROC]; p++)
    80003224:	00238917          	auipc	s2,0x238
    80003228:	2c490913          	addi	s2,s2,708 # 8023b4e8 <mlfq>
    8000322c:	a0b1                	j	80003278 <procdump+0xa4>
    int wtime = ticks - p->init_time - p->total_run_time;
    8000322e:	1c84b703          	ld	a4,456(s1)
    80003232:	1984b783          	ld	a5,408(s1)
    80003236:	9fb9                	addw	a5,a5,a4
    80003238:	000aa603          	lw	a2,0(s5)
    printf("%d %d %s %d %d %d %d %d %d %d %d\n", p->pid, p->mlfq_priority, state, p->total_run_time, wtime, p->runs_till_now, p->queue_run_time[0], p->queue_run_time[1], p->queue_run_time[2], p->queue_run_time[3], p->queue_run_time[4]);
    8000323c:	2184b583          	ld	a1,536(s1)
    80003240:	ec2e                	sd	a1,24(sp)
    80003242:	2104b583          	ld	a1,528(s1)
    80003246:	e82e                	sd	a1,16(sp)
    80003248:	2084b583          	ld	a1,520(s1)
    8000324c:	e42e                	sd	a1,8(sp)
    8000324e:	2004b583          	ld	a1,512(s1)
    80003252:	e02e                	sd	a1,0(sp)
    80003254:	1f84b883          	ld	a7,504(s1)
    80003258:	1e84b803          	ld	a6,488(s1)
    8000325c:	40f607bb          	subw	a5,a2,a5
    80003260:	1d04b603          	ld	a2,464(s1)
    80003264:	588c                	lw	a1,48(s1)
    80003266:	8552                	mv	a0,s4
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	326080e7          	jalr	806(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80003270:	24848493          	addi	s1,s1,584
    80003274:	01248f63          	beq	s1,s2,80003292 <procdump+0xbe>
    if (p->state == UNUSED)
    80003278:	4c9c                	lw	a5,24(s1)
    8000327a:	dbfd                	beqz	a5,80003270 <procdump+0x9c>
      state = "???";
    8000327c:	86ce                	mv	a3,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000327e:	fafb68e3          	bltu	s6,a5,8000322e <procdump+0x5a>
    80003282:	1782                	slli	a5,a5,0x20
    80003284:	9381                	srli	a5,a5,0x20
    80003286:	078e                	slli	a5,a5,0x3
    80003288:	97de                	add	a5,a5,s7
    8000328a:	6394                	ld	a3,0(a5)
    8000328c:	f2cd                	bnez	a3,8000322e <procdump+0x5a>
      state = "???";
    8000328e:	86ce                	mv	a3,s3
    80003290:	bf79                	j	8000322e <procdump+0x5a>
#endif
#endif
#endif
#endif
  }
    80003292:	70a6                	ld	ra,104(sp)
    80003294:	7406                	ld	s0,96(sp)
    80003296:	64e6                	ld	s1,88(sp)
    80003298:	6946                	ld	s2,80(sp)
    8000329a:	69a6                	ld	s3,72(sp)
    8000329c:	6a06                	ld	s4,64(sp)
    8000329e:	7ae2                	ld	s5,56(sp)
    800032a0:	7b42                	ld	s6,48(sp)
    800032a2:	7ba2                	ld	s7,40(sp)
    800032a4:	6165                	addi	sp,sp,112
    800032a6:	8082                	ret

00000000800032a8 <swtch>:
    800032a8:	00153023          	sd	ra,0(a0)
    800032ac:	00253423          	sd	sp,8(a0)
    800032b0:	e900                	sd	s0,16(a0)
    800032b2:	ed04                	sd	s1,24(a0)
    800032b4:	03253023          	sd	s2,32(a0)
    800032b8:	03353423          	sd	s3,40(a0)
    800032bc:	03453823          	sd	s4,48(a0)
    800032c0:	03553c23          	sd	s5,56(a0)
    800032c4:	05653023          	sd	s6,64(a0)
    800032c8:	05753423          	sd	s7,72(a0)
    800032cc:	05853823          	sd	s8,80(a0)
    800032d0:	05953c23          	sd	s9,88(a0)
    800032d4:	07a53023          	sd	s10,96(a0)
    800032d8:	07b53423          	sd	s11,104(a0)
    800032dc:	0005b083          	ld	ra,0(a1)
    800032e0:	0085b103          	ld	sp,8(a1)
    800032e4:	6980                	ld	s0,16(a1)
    800032e6:	6d84                	ld	s1,24(a1)
    800032e8:	0205b903          	ld	s2,32(a1)
    800032ec:	0285b983          	ld	s3,40(a1)
    800032f0:	0305ba03          	ld	s4,48(a1)
    800032f4:	0385ba83          	ld	s5,56(a1)
    800032f8:	0405bb03          	ld	s6,64(a1)
    800032fc:	0485bb83          	ld	s7,72(a1)
    80003300:	0505bc03          	ld	s8,80(a1)
    80003304:	0585bc83          	ld	s9,88(a1)
    80003308:	0605bd03          	ld	s10,96(a1)
    8000330c:	0685bd83          	ld	s11,104(a1)
    80003310:	8082                	ret

0000000080003312 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80003312:	1141                	addi	sp,sp,-16
    80003314:	e406                	sd	ra,8(sp)
    80003316:	e022                	sd	s0,0(sp)
    80003318:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000331a:	00006597          	auipc	a1,0x6
    8000331e:	05658593          	addi	a1,a1,86 # 80009370 <states.1902+0x30>
    80003322:	00239517          	auipc	a0,0x239
    80003326:	c6650513          	addi	a0,a0,-922 # 8023bf88 <tickslock>
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	a5c080e7          	jalr	-1444(ra) # 80000d86 <initlock>
}
    80003332:	60a2                	ld	ra,8(sp)
    80003334:	6402                	ld	s0,0(sp)
    80003336:	0141                	addi	sp,sp,16
    80003338:	8082                	ret

000000008000333a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000333a:	1141                	addi	sp,sp,-16
    8000333c:	e422                	sd	s0,8(sp)
    8000333e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003340:	00004797          	auipc	a5,0x4
    80003344:	92078793          	addi	a5,a5,-1760 # 80006c60 <kernelvec>
    80003348:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000334c:	6422                	ld	s0,8(sp)
    8000334e:	0141                	addi	sp,sp,16
    80003350:	8082                	ret

0000000080003352 <handle_page>:

int handle_page(void *va, pagetable_t pagetable)
{
    80003352:	7179                	addi	sp,sp,-48
    80003354:	f406                	sd	ra,40(sp)
    80003356:	f022                	sd	s0,32(sp)
    80003358:	ec26                	sd	s1,24(sp)
    8000335a:	e84a                	sd	s2,16(sp)
    8000335c:	e44e                	sd	s3,8(sp)
    8000335e:	1800                	addi	s0,sp,48
    80003360:	84aa                	mv	s1,a0
    80003362:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003364:	fffff097          	auipc	ra,0xfffff
    80003368:	a9e080e7          	jalr	-1378(ra) # 80001e02 <myproc>
  uint64 val = PGROUNDDOWN(p->trapframe->sp);
    8000336c:	6d3c                	ld	a5,88(a0)
    8000336e:	7b98                	ld	a4,48(a5)
    80003370:	77fd                	lui	a5,0xfffff
    80003372:	8ff9                	and	a5,a5,a4
  if ((uint64)va >= MAXVA || ((uint64)va <= val && (uint64)va >= val - PGSIZE))
    80003374:	577d                	li	a4,-1
    80003376:	8369                	srli	a4,a4,0x1a
    80003378:	08976563          	bltu	a4,s1,80003402 <handle_page+0xb0>
    8000337c:	0097e663          	bltu	a5,s1,80003388 <handle_page+0x36>
    80003380:	777d                	lui	a4,0xfffff
    80003382:	97ba                	add	a5,a5,a4
    80003384:	08f4f163          	bgeu	s1,a5,80003406 <handle_page+0xb4>
  {
    return -2;
  }
  else
  {
    pte_t *pte = walk(pagetable, (uint64)va, 0);
    80003388:	4601                	li	a2,0
    8000338a:	85a6                	mv	a1,s1
    8000338c:	854a                	mv	a0,s2
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	e70080e7          	jalr	-400(ra) # 800011fe <walk>
    80003396:	892a                	mv	s2,a0
    // uint64 pa;
    uint flags;
    va = (void *)PGROUNDDOWN((uint64)va);
    if (pte)
    80003398:	c92d                	beqz	a0,8000340a <handle_page+0xb8>
    {
      if (PTE2PA(*pte))
    8000339a:	611c                	ld	a5,0(a0)
    8000339c:	00a7d713          	srli	a4,a5,0xa
    800033a0:	0732                	slli	a4,a4,0xc
    800033a2:	c735                	beqz	a4,8000340e <handle_page+0xbc>
      {
        flags = PTE_FLAGS(*pte);
    800033a4:	2781                	sext.w	a5,a5
        if (flags & PTE_C)
    800033a6:	1007f713          	andi	a4,a5,256
            *pte = PA2PTE(mem) | flags;
          }
        }
        else
        {
          return 0;
    800033aa:	4501                	li	a0,0
        if (flags & PTE_C)
    800033ac:	eb01                	bnez	a4,800033bc <handle_page+0x6a>
    {
      return -1;
    }
  }
  return 0;
}
    800033ae:	70a2                	ld	ra,40(sp)
    800033b0:	7402                	ld	s0,32(sp)
    800033b2:	64e2                	ld	s1,24(sp)
    800033b4:	6942                	ld	s2,16(sp)
    800033b6:	69a2                	ld	s3,8(sp)
    800033b8:	6145                	addi	sp,sp,48
    800033ba:	8082                	ret
          flags = (flags | PTE_W) & (~PTE_C);
    800033bc:	2ff7f793          	andi	a5,a5,767
    800033c0:	0047e493          	ori	s1,a5,4
          char *mem = (char *)kalloc();
    800033c4:	ffffe097          	auipc	ra,0xffffe
    800033c8:	956080e7          	jalr	-1706(ra) # 80000d1a <kalloc>
    800033cc:	89aa                	mv	s3,a0
          if (!mem)
    800033ce:	c131                	beqz	a0,80003412 <handle_page+0xc0>
            memmove(mem, (void *)PTE2PA(*pte), PGSIZE);
    800033d0:	00093583          	ld	a1,0(s2)
    800033d4:	81a9                	srli	a1,a1,0xa
    800033d6:	6605                	lui	a2,0x1
    800033d8:	05b2                	slli	a1,a1,0xc
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	b98080e7          	jalr	-1128(ra) # 80000f72 <memmove>
            kfree((void *)PTE2PA(*pte));
    800033e2:	00093503          	ld	a0,0(s2)
    800033e6:	8129                	srli	a0,a0,0xa
    800033e8:	0532                	slli	a0,a0,0xc
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7a8080e7          	jalr	1960(ra) # 80000b92 <kfree>
            *pte = PA2PTE(mem) | flags;
    800033f2:	00c9d793          	srli	a5,s3,0xc
    800033f6:	07aa                	slli	a5,a5,0xa
    800033f8:	8fc5                	or	a5,a5,s1
    800033fa:	00f93023          	sd	a5,0(s2)
  return 0;
    800033fe:	4501                	li	a0,0
    80003400:	b77d                	j	800033ae <handle_page+0x5c>
    return -2;
    80003402:	5579                	li	a0,-2
    80003404:	b76d                	j	800033ae <handle_page+0x5c>
    80003406:	5579                	li	a0,-2
    80003408:	b75d                	j	800033ae <handle_page+0x5c>
      return -1;
    8000340a:	557d                	li	a0,-1
    8000340c:	b74d                	j	800033ae <handle_page+0x5c>
        return -1;
    8000340e:	557d                	li	a0,-1
    80003410:	bf79                	j	800033ae <handle_page+0x5c>
            return -1;
    80003412:	557d                	li	a0,-1
    80003414:	bf69                	j	800033ae <handle_page+0x5c>

0000000080003416 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80003416:	1141                	addi	sp,sp,-16
    80003418:	e406                	sd	ra,8(sp)
    8000341a:	e022                	sd	s0,0(sp)
    8000341c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000341e:	fffff097          	auipc	ra,0xfffff
    80003422:	9e4080e7          	jalr	-1564(ra) # 80001e02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003426:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000342a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000342c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003430:	00005617          	auipc	a2,0x5
    80003434:	bd060613          	addi	a2,a2,-1072 # 80008000 <_trampoline>
    80003438:	00005697          	auipc	a3,0x5
    8000343c:	bc868693          	addi	a3,a3,-1080 # 80008000 <_trampoline>
    80003440:	8e91                	sub	a3,a3,a2
    80003442:	040007b7          	lui	a5,0x4000
    80003446:	17fd                	addi	a5,a5,-1
    80003448:	07b2                	slli	a5,a5,0xc
    8000344a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000344c:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003450:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003452:	180026f3          	csrr	a3,satp
    80003456:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003458:	6d38                	ld	a4,88(a0)
    8000345a:	6134                	ld	a3,64(a0)
    8000345c:	6585                	lui	a1,0x1
    8000345e:	96ae                	add	a3,a3,a1
    80003460:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003462:	6d38                	ld	a4,88(a0)
    80003464:	00000697          	auipc	a3,0x0
    80003468:	13e68693          	addi	a3,a3,318 # 800035a2 <usertrap>
    8000346c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    8000346e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003470:	8692                	mv	a3,tp
    80003472:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003474:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003478:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000347c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003480:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003484:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003486:	6f18                	ld	a4,24(a4)
    80003488:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000348c:	6928                	ld	a0,80(a0)
    8000348e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80003490:	00005717          	auipc	a4,0x5
    80003494:	c0c70713          	addi	a4,a4,-1012 # 8000809c <userret>
    80003498:	8f11                	sub	a4,a4,a2
    8000349a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000349c:	577d                	li	a4,-1
    8000349e:	177e                	slli	a4,a4,0x3f
    800034a0:	8d59                	or	a0,a0,a4
    800034a2:	9782                	jalr	a5
}
    800034a4:	60a2                	ld	ra,8(sp)
    800034a6:	6402                	ld	s0,0(sp)
    800034a8:	0141                	addi	sp,sp,16
    800034aa:	8082                	ret

00000000800034ac <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	e04a                	sd	s2,0(sp)
    800034b6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800034b8:	00239917          	auipc	s2,0x239
    800034bc:	ad090913          	addi	s2,s2,-1328 # 8023bf88 <tickslock>
    800034c0:	854a                	mv	a0,s2
    800034c2:	ffffe097          	auipc	ra,0xffffe
    800034c6:	954080e7          	jalr	-1708(ra) # 80000e16 <acquire>
  ticks++;
    800034ca:	00006497          	auipc	s1,0x6
    800034ce:	76648493          	addi	s1,s1,1894 # 80009c30 <ticks>
    800034d2:	409c                	lw	a5,0(s1)
    800034d4:	2785                	addiw	a5,a5,1
    800034d6:	c09c                	sw	a5,0(s1)
  update_time();
    800034d8:	fffff097          	auipc	ra,0xfffff
    800034dc:	348080e7          	jalr	840(ra) # 80002820 <update_time>
  wakeup(&ticks);
    800034e0:	8526                	mv	a0,s1
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	93e080e7          	jalr	-1730(ra) # 80002e20 <wakeup>
  release(&tickslock);
    800034ea:	854a                	mv	a0,s2
    800034ec:	ffffe097          	auipc	ra,0xffffe
    800034f0:	9de080e7          	jalr	-1570(ra) # 80000eca <release>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	64a2                	ld	s1,8(sp)
    800034fa:	6902                	ld	s2,0(sp)
    800034fc:	6105                	addi	sp,sp,32
    800034fe:	8082                	ret

0000000080003500 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80003500:	1101                	addi	sp,sp,-32
    80003502:	ec06                	sd	ra,24(sp)
    80003504:	e822                	sd	s0,16(sp)
    80003506:	e426                	sd	s1,8(sp)
    80003508:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000350a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    8000350e:	00074d63          	bltz	a4,80003528 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80003512:	57fd                	li	a5,-1
    80003514:	17fe                	slli	a5,a5,0x3f
    80003516:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80003518:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000351a:	06f70363          	beq	a4,a5,80003580 <devintr+0x80>
  }
    8000351e:	60e2                	ld	ra,24(sp)
    80003520:	6442                	ld	s0,16(sp)
    80003522:	64a2                	ld	s1,8(sp)
    80003524:	6105                	addi	sp,sp,32
    80003526:	8082                	ret
      (scause & 0xff) == 9)
    80003528:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    8000352c:	46a5                	li	a3,9
    8000352e:	fed792e3          	bne	a5,a3,80003512 <devintr+0x12>
    int irq = plic_claim();
    80003532:	00004097          	auipc	ra,0x4
    80003536:	836080e7          	jalr	-1994(ra) # 80006d68 <plic_claim>
    8000353a:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    8000353c:	47a9                	li	a5,10
    8000353e:	02f50763          	beq	a0,a5,8000356c <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80003542:	4785                	li	a5,1
    80003544:	02f50963          	beq	a0,a5,80003576 <devintr+0x76>
    return 1;
    80003548:	4505                	li	a0,1
    else if (irq)
    8000354a:	d8f1                	beqz	s1,8000351e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000354c:	85a6                	mv	a1,s1
    8000354e:	00006517          	auipc	a0,0x6
    80003552:	e2a50513          	addi	a0,a0,-470 # 80009378 <states.1902+0x38>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	038080e7          	jalr	56(ra) # 8000058e <printf>
      plic_complete(irq);
    8000355e:	8526                	mv	a0,s1
    80003560:	00004097          	auipc	ra,0x4
    80003564:	82c080e7          	jalr	-2004(ra) # 80006d8c <plic_complete>
    return 1;
    80003568:	4505                	li	a0,1
    8000356a:	bf55                	j	8000351e <devintr+0x1e>
      uartintr();
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	442080e7          	jalr	1090(ra) # 800009ae <uartintr>
    80003574:	b7ed                	j	8000355e <devintr+0x5e>
      virtio_disk_intr();
    80003576:	00004097          	auipc	ra,0x4
    8000357a:	d40080e7          	jalr	-704(ra) # 800072b6 <virtio_disk_intr>
    8000357e:	b7c5                	j	8000355e <devintr+0x5e>
    if (cpuid() == 0)
    80003580:	fffff097          	auipc	ra,0xfffff
    80003584:	856080e7          	jalr	-1962(ra) # 80001dd6 <cpuid>
    80003588:	c901                	beqz	a0,80003598 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000358a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000358e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003590:	14479073          	csrw	sip,a5
    return 2;
    80003594:	4509                	li	a0,2
    80003596:	b761                	j	8000351e <devintr+0x1e>
      clockintr();
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	f14080e7          	jalr	-236(ra) # 800034ac <clockintr>
    800035a0:	b7ed                	j	8000358a <devintr+0x8a>

00000000800035a2 <usertrap>:
{
    800035a2:	7179                	addi	sp,sp,-48
    800035a4:	f406                	sd	ra,40(sp)
    800035a6:	f022                	sd	s0,32(sp)
    800035a8:	ec26                	sd	s1,24(sp)
    800035aa:	e84a                	sd	s2,16(sp)
    800035ac:	e44e                	sd	s3,8(sp)
    800035ae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035b0:	100024f3          	csrr	s1,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800035b4:	1004f493          	andi	s1,s1,256
    800035b8:	e4b9                	bnez	s1,80003606 <usertrap+0x64>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800035ba:	00003797          	auipc	a5,0x3
    800035be:	6a678793          	addi	a5,a5,1702 # 80006c60 <kernelvec>
    800035c2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800035c6:	fffff097          	auipc	ra,0xfffff
    800035ca:	83c080e7          	jalr	-1988(ra) # 80001e02 <myproc>
    800035ce:	892a                	mv	s2,a0
  p->trapframe->epc = r_sepc();
    800035d0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035d2:	14102773          	csrr	a4,sepc
    800035d6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035d8:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800035dc:	47a1                	li	a5,8
    800035de:	02f70c63          	beq	a4,a5,80003616 <usertrap+0x74>
  else if ((which_dev = devintr()) != 0)
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	f1e080e7          	jalr	-226(ra) # 80003500 <devintr>
    800035ea:	89aa                	mv	s3,a0
    800035ec:	ed69                	bnez	a0,800036c6 <usertrap+0x124>
    800035ee:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    800035f2:	47bd                	li	a5,15
    800035f4:	08f71b63          	bne	a4,a5,8000368a <usertrap+0xe8>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035f8:	143027f3          	csrr	a5,stval
    if (!r_stval())
    800035fc:	eba5                	bnez	a5,8000366c <usertrap+0xca>
      p->killed = 1;
    800035fe:	4785                	li	a5,1
    80003600:	02f92423          	sw	a5,40(s2)
    80003604:	a82d                	j	8000363e <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80003606:	00006517          	auipc	a0,0x6
    8000360a:	d9250513          	addi	a0,a0,-622 # 80009398 <states.1902+0x58>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	f36080e7          	jalr	-202(ra) # 80000544 <panic>
    if (killed(p))
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	ae0080e7          	jalr	-1312(ra) # 800030f6 <killed>
    8000361e:	e129                	bnez	a0,80003660 <usertrap+0xbe>
    p->trapframe->epc += 4;
    80003620:	05893703          	ld	a4,88(s2)
    80003624:	6f1c                	ld	a5,24(a4)
    80003626:	0791                	addi	a5,a5,4
    80003628:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000362a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000362e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003632:	10079073          	csrw	sstatus,a5
    syscall();
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	406080e7          	jalr	1030(ra) # 80003a3c <syscall>
  if (killed(p))
    8000363e:	854a                	mv	a0,s2
    80003640:	00000097          	auipc	ra,0x0
    80003644:	ab6080e7          	jalr	-1354(ra) # 800030f6 <killed>
    80003648:	e551                	bnez	a0,800036d4 <usertrap+0x132>
  usertrapret();
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	dcc080e7          	jalr	-564(ra) # 80003416 <usertrapret>
}
    80003652:	70a2                	ld	ra,40(sp)
    80003654:	7402                	ld	s0,32(sp)
    80003656:	64e2                	ld	s1,24(sp)
    80003658:	6942                	ld	s2,16(sp)
    8000365a:	69a2                	ld	s3,8(sp)
    8000365c:	6145                	addi	sp,sp,48
    8000365e:	8082                	ret
      exit(-1);
    80003660:	557d                	li	a0,-1
    80003662:	00000097          	auipc	ra,0x0
    80003666:	8dc080e7          	jalr	-1828(ra) # 80002f3e <exit>
    8000366a:	bf5d                	j	80003620 <usertrap+0x7e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000366c:	14302573          	csrr	a0,stval
      int res = handle_page((void *)r_stval(), p->pagetable);
    80003670:	05093583          	ld	a1,80(s2)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	cde080e7          	jalr	-802(ra) # 80003352 <handle_page>
      if (res == -1 || res == -2)
    8000367c:	2509                	addiw	a0,a0,2
    8000367e:	4785                	li	a5,1
    80003680:	faa7efe3          	bltu	a5,a0,8000363e <usertrap+0x9c>
        p->killed = 1;
    80003684:	02f92423          	sw	a5,40(s2)
    80003688:	bf5d                	j	8000363e <usertrap+0x9c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000368a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000368e:	03092603          	lw	a2,48(s2)
    80003692:	00006517          	auipc	a0,0x6
    80003696:	d2650513          	addi	a0,a0,-730 # 800093b8 <states.1902+0x78>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	ef4080e7          	jalr	-268(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800036a2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800036a6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800036aa:	00006517          	auipc	a0,0x6
    800036ae:	d3e50513          	addi	a0,a0,-706 # 800093e8 <states.1902+0xa8>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	edc080e7          	jalr	-292(ra) # 8000058e <printf>
    setkilled(p);
    800036ba:	854a                	mv	a0,s2
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	a0e080e7          	jalr	-1522(ra) # 800030ca <setkilled>
    800036c4:	bfad                	j	8000363e <usertrap+0x9c>
  if (killed(p))
    800036c6:	854a                	mv	a0,s2
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	a2e080e7          	jalr	-1490(ra) # 800030f6 <killed>
    800036d0:	c901                	beqz	a0,800036e0 <usertrap+0x13e>
    800036d2:	a011                	j	800036d6 <usertrap+0x134>
    800036d4:	4981                	li	s3,0
    exit(-1);
    800036d6:	557d                	li	a0,-1
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	866080e7          	jalr	-1946(ra) # 80002f3e <exit>
  if (which_dev == 2 && p != 0)
    800036e0:	4789                	li	a5,2
    800036e2:	f6f994e3          	bne	s3,a5,8000364a <usertrap+0xa8>
    p->completed_clockval = p->completed_clockval + 1;
    800036e6:	17492783          	lw	a5,372(s2)
    800036ea:	2785                	addiw	a5,a5,1
    800036ec:	0007871b          	sext.w	a4,a5
    800036f0:	16f92a23          	sw	a5,372(s2)
    if (p->clockval > 0 && p->clockval <= p->completed_clockval)
    800036f4:	17092783          	lw	a5,368(s2)
    800036f8:	04f05863          	blez	a5,80003748 <usertrap+0x1a6>
    800036fc:	04f74663          	blt	a4,a5,80003748 <usertrap+0x1a6>
      if (p->is_sigalarm == 0)
    80003700:	16c92783          	lw	a5,364(s2)
    80003704:	e3b1                	bnez	a5,80003748 <usertrap+0x1a6>
        p->is_sigalarm = 1;
    80003706:	4785                	li	a5,1
    80003708:	16f92623          	sw	a5,364(s2)
        p->completed_clockval = 0;
    8000370c:	16092a23          	sw	zero,372(s2)
        *(p->cpy_trapframe) = *(p->trapframe);
    80003710:	05893683          	ld	a3,88(s2)
    80003714:	87b6                	mv	a5,a3
    80003716:	18893703          	ld	a4,392(s2)
    8000371a:	12068693          	addi	a3,a3,288
    8000371e:	0007b803          	ld	a6,0(a5)
    80003722:	6788                	ld	a0,8(a5)
    80003724:	6b8c                	ld	a1,16(a5)
    80003726:	6f90                	ld	a2,24(a5)
    80003728:	01073023          	sd	a6,0(a4)
    8000372c:	e708                	sd	a0,8(a4)
    8000372e:	eb0c                	sd	a1,16(a4)
    80003730:	ef10                	sd	a2,24(a4)
    80003732:	02078793          	addi	a5,a5,32
    80003736:	02070713          	addi	a4,a4,32
    8000373a:	fed792e3          	bne	a5,a3,8000371e <usertrap+0x17c>
        p->trapframe->epc = p->handler;
    8000373e:	05893783          	ld	a5,88(s2)
    80003742:	17893703          	ld	a4,376(s2)
    80003746:	ef98                	sd	a4,24(a5)
    p = myproc();
    80003748:	ffffe097          	auipc	ra,0xffffe
    8000374c:	6ba080e7          	jalr	1722(ra) # 80001e02 <myproc>
    80003750:	89aa                	mv	s3,a0
    if (p->state == RUNNING && p->quantums_left <= 0)
    80003752:	4d18                	lw	a4,24(a0)
    80003754:	4791                	li	a5,4
    80003756:	00f70b63          	beq	a4,a5,8000376c <usertrap+0x1ca>
    for (int i = 0; i < p->mlfq_priority; i++)
    8000375a:	1d09b783          	ld	a5,464(s3)
    8000375e:	ee0786e3          	beqz	a5,8000364a <usertrap+0xa8>
    80003762:	00238917          	auipc	s2,0x238
    80003766:	f9e90913          	addi	s2,s2,-98 # 8023b700 <mlfq+0x218>
    8000376a:	a825                	j	800037a2 <usertrap+0x200>
    if (p->state == RUNNING && p->quantums_left <= 0)
    8000376c:	1e053783          	ld	a5,480(a0)
    80003770:	f7ed                	bnez	a5,8000375a <usertrap+0x1b8>
      if (p->mlfq_priority <= 3)
    80003772:	1d053783          	ld	a5,464(a0)
    80003776:	470d                	li	a4,3
    80003778:	00f76563          	bltu	a4,a5,80003782 <usertrap+0x1e0>
        p->mlfq_priority++;
    8000377c:	0785                	addi	a5,a5,1
    8000377e:	1cf53823          	sd	a5,464(a0)
      yield();
    80003782:	fffff097          	auipc	ra,0xfffff
    80003786:	2b6080e7          	jalr	694(ra) # 80002a38 <yield>
    8000378a:	bfc1                	j	8000375a <usertrap+0x1b8>
        yield();
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	2ac080e7          	jalr	684(ra) # 80002a38 <yield>
    for (int i = 0; i < p->mlfq_priority; i++)
    80003794:	0485                	addi	s1,s1,1
    80003796:	22090913          	addi	s2,s2,544
    8000379a:	1d09b783          	ld	a5,464(s3)
    8000379e:	eaf4f6e3          	bgeu	s1,a5,8000364a <usertrap+0xa8>
      if (mlfq[i].numitems)
    800037a2:	00092783          	lw	a5,0(s2)
    800037a6:	d7fd                	beqz	a5,80003794 <usertrap+0x1f2>
    800037a8:	b7d5                	j	8000378c <usertrap+0x1ea>

00000000800037aa <kerneltrap>:
{
    800037aa:	7139                	addi	sp,sp,-64
    800037ac:	fc06                	sd	ra,56(sp)
    800037ae:	f822                	sd	s0,48(sp)
    800037b0:	f426                	sd	s1,40(sp)
    800037b2:	f04a                	sd	s2,32(sp)
    800037b4:	ec4e                	sd	s3,24(sp)
    800037b6:	e852                	sd	s4,16(sp)
    800037b8:	e456                	sd	s5,8(sp)
    800037ba:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800037bc:	ffffe097          	auipc	ra,0xffffe
    800037c0:	646080e7          	jalr	1606(ra) # 80001e02 <myproc>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800037c4:	14102a73          	csrr	s4,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800037c8:	100029f3          	csrr	s3,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800037cc:	14202af3          	csrr	s5,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800037d0:	1009f793          	andi	a5,s3,256
    800037d4:	cb9d                	beqz	a5,8000380a <kerneltrap+0x60>
    800037d6:	892a                	mv	s2,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800037d8:	100024f3          	csrr	s1,sstatus
  return (x & SSTATUS_SIE) != 0;
    800037dc:	8889                	andi	s1,s1,2
  if (intr_get() != 0)
    800037de:	ec95                	bnez	s1,8000381a <kerneltrap+0x70>
  if ((which_dev = devintr()) == 0)
    800037e0:	00000097          	auipc	ra,0x0
    800037e4:	d20080e7          	jalr	-736(ra) # 80003500 <devintr>
    800037e8:	c129                	beqz	a0,8000382a <kerneltrap+0x80>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    800037ea:	4789                	li	a5,2
    800037ec:	06f50c63          	beq	a0,a5,80003864 <kerneltrap+0xba>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800037f0:	141a1073          	csrw	sepc,s4
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800037f4:	10099073          	csrw	sstatus,s3
}
    800037f8:	70e2                	ld	ra,56(sp)
    800037fa:	7442                	ld	s0,48(sp)
    800037fc:	74a2                	ld	s1,40(sp)
    800037fe:	7902                	ld	s2,32(sp)
    80003800:	69e2                	ld	s3,24(sp)
    80003802:	6a42                	ld	s4,16(sp)
    80003804:	6aa2                	ld	s5,8(sp)
    80003806:	6121                	addi	sp,sp,64
    80003808:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000380a:	00006517          	auipc	a0,0x6
    8000380e:	bfe50513          	addi	a0,a0,-1026 # 80009408 <states.1902+0xc8>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	d32080e7          	jalr	-718(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000381a:	00006517          	auipc	a0,0x6
    8000381e:	c1650513          	addi	a0,a0,-1002 # 80009430 <states.1902+0xf0>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d22080e7          	jalr	-734(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000382a:	85d6                	mv	a1,s5
    8000382c:	00006517          	auipc	a0,0x6
    80003830:	c2450513          	addi	a0,a0,-988 # 80009450 <states.1902+0x110>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d5a080e7          	jalr	-678(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000383c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003840:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003844:	00006517          	auipc	a0,0x6
    80003848:	c1c50513          	addi	a0,a0,-996 # 80009460 <states.1902+0x120>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	d42080e7          	jalr	-702(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003854:	00006517          	auipc	a0,0x6
    80003858:	c2450513          	addi	a0,a0,-988 # 80009478 <states.1902+0x138>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	ce8080e7          	jalr	-792(ra) # 80000544 <panic>
  if (which_dev == 2 && p != 0 && p->state == RUNNING)
    80003864:	f80906e3          	beqz	s2,800037f0 <kerneltrap+0x46>
    80003868:	01892703          	lw	a4,24(s2)
    8000386c:	4791                	li	a5,4
    8000386e:	f8f711e3          	bne	a4,a5,800037f0 <kerneltrap+0x46>
    if (p->quantums_left <= 0)
    80003872:	1e093783          	ld	a5,480(s2)
    80003876:	ef89                	bnez	a5,80003890 <kerneltrap+0xe6>
      if (p->mlfq_priority <= 3)
    80003878:	1d093783          	ld	a5,464(s2)
    8000387c:	470d                	li	a4,3
    8000387e:	00f76563          	bltu	a4,a5,80003888 <kerneltrap+0xde>
        p->mlfq_priority++;
    80003882:	0785                	addi	a5,a5,1
    80003884:	1cf93823          	sd	a5,464(s2)
      yield();
    80003888:	fffff097          	auipc	ra,0xfffff
    8000388c:	1b0080e7          	jalr	432(ra) # 80002a38 <yield>
    for (int i = 0; i < p->mlfq_priority; i++)
    80003890:	1d093783          	ld	a5,464(s2)
    80003894:	dfb1                	beqz	a5,800037f0 <kerneltrap+0x46>
    80003896:	00238a97          	auipc	s5,0x238
    8000389a:	e6aa8a93          	addi	s5,s5,-406 # 8023b700 <mlfq+0x218>
    8000389e:	a821                	j	800038b6 <kerneltrap+0x10c>
        yield();
    800038a0:	fffff097          	auipc	ra,0xfffff
    800038a4:	198080e7          	jalr	408(ra) # 80002a38 <yield>
    for (int i = 0; i < p->mlfq_priority; i++)
    800038a8:	0485                	addi	s1,s1,1
    800038aa:	220a8a93          	addi	s5,s5,544
    800038ae:	1d093783          	ld	a5,464(s2)
    800038b2:	f2f4ffe3          	bgeu	s1,a5,800037f0 <kerneltrap+0x46>
      if (mlfq[i].numitems)
    800038b6:	000aa783          	lw	a5,0(s5)
    800038ba:	d7fd                	beqz	a5,800038a8 <kerneltrap+0xfe>
    800038bc:	b7d5                	j	800038a0 <kerneltrap+0xf6>

00000000800038be <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	e426                	sd	s1,8(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800038ca:	ffffe097          	auipc	ra,0xffffe
    800038ce:	538080e7          	jalr	1336(ra) # 80001e02 <myproc>
  switch (n)
    800038d2:	4795                	li	a5,5
    800038d4:	0497e163          	bltu	a5,s1,80003916 <argraw+0x58>
    800038d8:	048a                	slli	s1,s1,0x2
    800038da:	00006717          	auipc	a4,0x6
    800038de:	d2e70713          	addi	a4,a4,-722 # 80009608 <states.1902+0x2c8>
    800038e2:	94ba                	add	s1,s1,a4
    800038e4:	409c                	lw	a5,0(s1)
    800038e6:	97ba                	add	a5,a5,a4
    800038e8:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800038ea:	6d3c                	ld	a5,88(a0)
    800038ec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800038ee:	60e2                	ld	ra,24(sp)
    800038f0:	6442                	ld	s0,16(sp)
    800038f2:	64a2                	ld	s1,8(sp)
    800038f4:	6105                	addi	sp,sp,32
    800038f6:	8082                	ret
    return p->trapframe->a1;
    800038f8:	6d3c                	ld	a5,88(a0)
    800038fa:	7fa8                	ld	a0,120(a5)
    800038fc:	bfcd                	j	800038ee <argraw+0x30>
    return p->trapframe->a2;
    800038fe:	6d3c                	ld	a5,88(a0)
    80003900:	63c8                	ld	a0,128(a5)
    80003902:	b7f5                	j	800038ee <argraw+0x30>
    return p->trapframe->a3;
    80003904:	6d3c                	ld	a5,88(a0)
    80003906:	67c8                	ld	a0,136(a5)
    80003908:	b7dd                	j	800038ee <argraw+0x30>
    return p->trapframe->a4;
    8000390a:	6d3c                	ld	a5,88(a0)
    8000390c:	6bc8                	ld	a0,144(a5)
    8000390e:	b7c5                	j	800038ee <argraw+0x30>
    return p->trapframe->a5;
    80003910:	6d3c                	ld	a5,88(a0)
    80003912:	6fc8                	ld	a0,152(a5)
    80003914:	bfe9                	j	800038ee <argraw+0x30>
  panic("argraw");
    80003916:	00006517          	auipc	a0,0x6
    8000391a:	b7250513          	addi	a0,a0,-1166 # 80009488 <states.1902+0x148>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	c26080e7          	jalr	-986(ra) # 80000544 <panic>

0000000080003926 <fetchaddr>:
{
    80003926:	1101                	addi	sp,sp,-32
    80003928:	ec06                	sd	ra,24(sp)
    8000392a:	e822                	sd	s0,16(sp)
    8000392c:	e426                	sd	s1,8(sp)
    8000392e:	e04a                	sd	s2,0(sp)
    80003930:	1000                	addi	s0,sp,32
    80003932:	84aa                	mv	s1,a0
    80003934:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003936:	ffffe097          	auipc	ra,0xffffe
    8000393a:	4cc080e7          	jalr	1228(ra) # 80001e02 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000393e:	653c                	ld	a5,72(a0)
    80003940:	02f4f863          	bgeu	s1,a5,80003970 <fetchaddr+0x4a>
    80003944:	00848713          	addi	a4,s1,8
    80003948:	02e7e663          	bltu	a5,a4,80003974 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000394c:	46a1                	li	a3,8
    8000394e:	8626                	mv	a2,s1
    80003950:	85ca                	mv	a1,s2
    80003952:	6928                	ld	a0,80(a0)
    80003954:	ffffe097          	auipc	ra,0xffffe
    80003958:	02c080e7          	jalr	44(ra) # 80001980 <copyin>
    8000395c:	00a03533          	snez	a0,a0
    80003960:	40a00533          	neg	a0,a0
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6902                	ld	s2,0(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret
    return -1;
    80003970:	557d                	li	a0,-1
    80003972:	bfcd                	j	80003964 <fetchaddr+0x3e>
    80003974:	557d                	li	a0,-1
    80003976:	b7fd                	j	80003964 <fetchaddr+0x3e>

0000000080003978 <fetchstr>:
{
    80003978:	7179                	addi	sp,sp,-48
    8000397a:	f406                	sd	ra,40(sp)
    8000397c:	f022                	sd	s0,32(sp)
    8000397e:	ec26                	sd	s1,24(sp)
    80003980:	e84a                	sd	s2,16(sp)
    80003982:	e44e                	sd	s3,8(sp)
    80003984:	1800                	addi	s0,sp,48
    80003986:	892a                	mv	s2,a0
    80003988:	84ae                	mv	s1,a1
    8000398a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000398c:	ffffe097          	auipc	ra,0xffffe
    80003990:	476080e7          	jalr	1142(ra) # 80001e02 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003994:	86ce                	mv	a3,s3
    80003996:	864a                	mv	a2,s2
    80003998:	85a6                	mv	a1,s1
    8000399a:	6928                	ld	a0,80(a0)
    8000399c:	ffffe097          	auipc	ra,0xffffe
    800039a0:	070080e7          	jalr	112(ra) # 80001a0c <copyinstr>
    800039a4:	00054e63          	bltz	a0,800039c0 <fetchstr+0x48>
  return strlen(buf);
    800039a8:	8526                	mv	a0,s1
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	6ec080e7          	jalr	1772(ra) # 80001096 <strlen>
}
    800039b2:	70a2                	ld	ra,40(sp)
    800039b4:	7402                	ld	s0,32(sp)
    800039b6:	64e2                	ld	s1,24(sp)
    800039b8:	6942                	ld	s2,16(sp)
    800039ba:	69a2                	ld	s3,8(sp)
    800039bc:	6145                	addi	sp,sp,48
    800039be:	8082                	ret
    return -1;
    800039c0:	557d                	li	a0,-1
    800039c2:	bfc5                	j	800039b2 <fetchstr+0x3a>

00000000800039c4 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    800039c4:	1101                	addi	sp,sp,-32
    800039c6:	ec06                	sd	ra,24(sp)
    800039c8:	e822                	sd	s0,16(sp)
    800039ca:	e426                	sd	s1,8(sp)
    800039cc:	1000                	addi	s0,sp,32
    800039ce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	eee080e7          	jalr	-274(ra) # 800038be <argraw>
    800039d8:	c088                	sw	a0,0(s1)
}
    800039da:	60e2                	ld	ra,24(sp)
    800039dc:	6442                	ld	s0,16(sp)
    800039de:	64a2                	ld	s1,8(sp)
    800039e0:	6105                	addi	sp,sp,32
    800039e2:	8082                	ret

00000000800039e4 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	1000                	addi	s0,sp,32
    800039ee:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	ece080e7          	jalr	-306(ra) # 800038be <argraw>
    800039f8:	e088                	sd	a0,0(s1)
}
    800039fa:	60e2                	ld	ra,24(sp)
    800039fc:	6442                	ld	s0,16(sp)
    800039fe:	64a2                	ld	s1,8(sp)
    80003a00:	6105                	addi	sp,sp,32
    80003a02:	8082                	ret

0000000080003a04 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003a04:	7179                	addi	sp,sp,-48
    80003a06:	f406                	sd	ra,40(sp)
    80003a08:	f022                	sd	s0,32(sp)
    80003a0a:	ec26                	sd	s1,24(sp)
    80003a0c:	e84a                	sd	s2,16(sp)
    80003a0e:	1800                	addi	s0,sp,48
    80003a10:	84ae                	mv	s1,a1
    80003a12:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003a14:	fd840593          	addi	a1,s0,-40
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	fcc080e7          	jalr	-52(ra) # 800039e4 <argaddr>
  return fetchstr(addr, buf, max);
    80003a20:	864a                	mv	a2,s2
    80003a22:	85a6                	mv	a1,s1
    80003a24:	fd843503          	ld	a0,-40(s0)
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	f50080e7          	jalr	-176(ra) # 80003978 <fetchstr>
}
    80003a30:	70a2                	ld	ra,40(sp)
    80003a32:	7402                	ld	s0,32(sp)
    80003a34:	64e2                	ld	s1,24(sp)
    80003a36:	6942                	ld	s2,16(sp)
    80003a38:	6145                	addi	sp,sp,48
    80003a3a:	8082                	ret

0000000080003a3c <syscall>:
    [SYS_waitx] 3,
    [SYS_set_tickets] 1,
};

void syscall(void)
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80003a4a:	ffffe097          	auipc	ra,0xffffe
    80003a4e:	3b8080e7          	jalr	952(ra) # 80001e02 <myproc>
    80003a52:	84aa                	mv	s1,a0

  int num = p->trapframe->a7;
    80003a54:	05853903          	ld	s2,88(a0)
    80003a58:	0a893783          	ld	a5,168(s2)
    80003a5c:	0007899b          	sext.w	s3,a5

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003a60:	37fd                	addiw	a5,a5,-1
    80003a62:	4769                	li	a4,26
    80003a64:	10f76663          	bltu	a4,a5,80003b70 <syscall+0x134>
    80003a68:	00399713          	slli	a4,s3,0x3
    80003a6c:	00006797          	auipc	a5,0x6
    80003a70:	bcc78793          	addi	a5,a5,-1076 # 80009638 <syscalls>
    80003a74:	97ba                	add	a5,a5,a4
    80003a76:	639c                	ld	a5,0(a5)
    80003a78:	cfe5                	beqz	a5,80003b70 <syscall+0x134>
  {
    p->trapframe->a0 = syscalls[num]();
    80003a7a:	9782                	jalr	a5
    80003a7c:	06a93823          	sd	a0,112(s2)

    if ((1 << p->trapframe->a7) & p->bitmask)
    80003a80:	6cb8                	ld	a4,88(s1)
    80003a82:	7754                	ld	a3,168(a4)
    80003a84:	1684a783          	lw	a5,360(s1)
    80003a88:	40d7d7bb          	sraw	a5,a5,a3
    80003a8c:	8b85                	andi	a5,a5,1
    80003a8e:	10078063          	beqz	a5,80003b8e <syscall+0x152>
    {
      printf("%d: syscall %s (%d ", p->pid, names[num], p->trapframe->a0);
    80003a92:	00006917          	auipc	s2,0x6
    80003a96:	01690913          	addi	s2,s2,22 # 80009aa8 <names>
    80003a9a:	00399793          	slli	a5,s3,0x3
    80003a9e:	97ca                	add	a5,a5,s2
    80003aa0:	7b34                	ld	a3,112(a4)
    80003aa2:	6390                	ld	a2,0(a5)
    80003aa4:	588c                	lw	a1,48(s1)
    80003aa6:	00006517          	auipc	a0,0x6
    80003aaa:	9ea50513          	addi	a0,a0,-1558 # 80009490 <states.1902+0x150>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	ae0080e7          	jalr	-1312(ra) # 8000058e <printf>
      switch (args_num[num])
    80003ab6:	098a                	slli	s3,s3,0x2
    80003ab8:	994e                	add	s2,s2,s3
    80003aba:	0e092703          	lw	a4,224(s2)
    80003abe:	4795                	li	a5,5
    80003ac0:	08e7e963          	bltu	a5,a4,80003b52 <syscall+0x116>
    80003ac4:	0e096783          	lwu	a5,224(s2)
    80003ac8:	078a                	slli	a5,a5,0x2
    80003aca:	00006717          	auipc	a4,0x6
    80003ace:	b5670713          	addi	a4,a4,-1194 # 80009620 <states.1902+0x2e0>
    80003ad2:	97ba                	add	a5,a5,a4
    80003ad4:	439c                	lw	a5,0(a5)
    80003ad6:	97ba                	add	a5,a5,a4
    80003ad8:	8782                	jr	a5
      case L0:
        break;
      case L1:
        break;
      case L2:
        printf("%d", p->trapframe->a1);
    80003ada:	6cbc                	ld	a5,88(s1)
    80003adc:	7fac                	ld	a1,120(a5)
    80003ade:	00006517          	auipc	a0,0x6
    80003ae2:	9ca50513          	addi	a0,a0,-1590 # 800094a8 <states.1902+0x168>
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	aa8080e7          	jalr	-1368(ra) # 8000058e <printf>
        break;
      default:
        printf("%d %d %d %d %d", p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a5);
        break;
      }
      printf(") -> %d\n", p->trapframe->a0);
    80003aee:	6cbc                	ld	a5,88(s1)
    80003af0:	7bac                	ld	a1,112(a5)
    80003af2:	00006517          	auipc	a0,0x6
    80003af6:	9f650513          	addi	a0,a0,-1546 # 800094e8 <states.1902+0x1a8>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a94080e7          	jalr	-1388(ra) # 8000058e <printf>
    80003b02:	a071                	j	80003b8e <syscall+0x152>
        printf("%d %d", p->trapframe->a1, p->trapframe->a2);
    80003b04:	6cbc                	ld	a5,88(s1)
    80003b06:	63d0                	ld	a2,128(a5)
    80003b08:	7fac                	ld	a1,120(a5)
    80003b0a:	00006517          	auipc	a0,0x6
    80003b0e:	9a650513          	addi	a0,a0,-1626 # 800094b0 <states.1902+0x170>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a7c080e7          	jalr	-1412(ra) # 8000058e <printf>
        break;
    80003b1a:	bfd1                	j	80003aee <syscall+0xb2>
        printf("%d %d %d", p->trapframe->a1, p->trapframe->a2, p->trapframe->a3);
    80003b1c:	6cbc                	ld	a5,88(s1)
    80003b1e:	67d4                	ld	a3,136(a5)
    80003b20:	63d0                	ld	a2,128(a5)
    80003b22:	7fac                	ld	a1,120(a5)
    80003b24:	00006517          	auipc	a0,0x6
    80003b28:	99450513          	addi	a0,a0,-1644 # 800094b8 <states.1902+0x178>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	a62080e7          	jalr	-1438(ra) # 8000058e <printf>
        break;
    80003b34:	bf6d                	j	80003aee <syscall+0xb2>
        printf("%d %d %d %d", p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4);
    80003b36:	6cbc                	ld	a5,88(s1)
    80003b38:	6bd8                	ld	a4,144(a5)
    80003b3a:	67d4                	ld	a3,136(a5)
    80003b3c:	63d0                	ld	a2,128(a5)
    80003b3e:	7fac                	ld	a1,120(a5)
    80003b40:	00006517          	auipc	a0,0x6
    80003b44:	98850513          	addi	a0,a0,-1656 # 800094c8 <states.1902+0x188>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	a46080e7          	jalr	-1466(ra) # 8000058e <printf>
        break;
    80003b50:	bf79                	j	80003aee <syscall+0xb2>
        printf("%d %d %d %d %d", p->trapframe->a1, p->trapframe->a2, p->trapframe->a3, p->trapframe->a4, p->trapframe->a5);
    80003b52:	6cac                	ld	a1,88(s1)
    80003b54:	6ddc                	ld	a5,152(a1)
    80003b56:	69d8                	ld	a4,144(a1)
    80003b58:	65d4                	ld	a3,136(a1)
    80003b5a:	61d0                	ld	a2,128(a1)
    80003b5c:	7dac                	ld	a1,120(a1)
    80003b5e:	00006517          	auipc	a0,0x6
    80003b62:	97a50513          	addi	a0,a0,-1670 # 800094d8 <states.1902+0x198>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	a28080e7          	jalr	-1496(ra) # 8000058e <printf>
        break;
    80003b6e:	b741                	j	80003aee <syscall+0xb2>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003b70:	86ce                	mv	a3,s3
    80003b72:	15848613          	addi	a2,s1,344
    80003b76:	588c                	lw	a1,48(s1)
    80003b78:	00006517          	auipc	a0,0x6
    80003b7c:	98050513          	addi	a0,a0,-1664 # 800094f8 <states.1902+0x1b8>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	a0e080e7          	jalr	-1522(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003b88:	6cbc                	ld	a5,88(s1)
    80003b8a:	577d                	li	a4,-1
    80003b8c:	fbb8                	sd	a4,112(a5)
  }
}
    80003b8e:	70a2                	ld	ra,40(sp)
    80003b90:	7402                	ld	s0,32(sp)
    80003b92:	64e2                	ld	s1,24(sp)
    80003b94:	6942                	ld	s2,16(sp)
    80003b96:	69a2                	ld	s3,8(sp)
    80003b98:	6145                	addi	sp,sp,48
    80003b9a:	8082                	ret

0000000080003b9c <sys_exit>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_exit(void)
{
    80003b9c:	1101                	addi	sp,sp,-32
    80003b9e:	ec06                	sd	ra,24(sp)
    80003ba0:	e822                	sd	s0,16(sp)
    80003ba2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003ba4:	fec40593          	addi	a1,s0,-20
    80003ba8:	4501                	li	a0,0
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	e1a080e7          	jalr	-486(ra) # 800039c4 <argint>
  exit(n);
    80003bb2:	fec42503          	lw	a0,-20(s0)
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	388080e7          	jalr	904(ra) # 80002f3e <exit>
  return 0; // not reached
}
    80003bbe:	4501                	li	a0,0
    80003bc0:	60e2                	ld	ra,24(sp)
    80003bc2:	6442                	ld	s0,16(sp)
    80003bc4:	6105                	addi	sp,sp,32
    80003bc6:	8082                	ret

0000000080003bc8 <sys_getpid>:

uint64 sys_getpid(void)
{
    80003bc8:	1141                	addi	sp,sp,-16
    80003bca:	e406                	sd	ra,8(sp)
    80003bcc:	e022                	sd	s0,0(sp)
    80003bce:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003bd0:	ffffe097          	auipc	ra,0xffffe
    80003bd4:	232080e7          	jalr	562(ra) # 80001e02 <myproc>
}
    80003bd8:	5908                	lw	a0,48(a0)
    80003bda:	60a2                	ld	ra,8(sp)
    80003bdc:	6402                	ld	s0,0(sp)
    80003bde:	0141                	addi	sp,sp,16
    80003be0:	8082                	ret

0000000080003be2 <sys_fork>:

uint64 sys_fork(void)
{
    80003be2:	1141                	addi	sp,sp,-16
    80003be4:	e406                	sd	ra,8(sp)
    80003be6:	e022                	sd	s0,0(sp)
    80003be8:	0800                	addi	s0,sp,16
  return fork();
    80003bea:	ffffe097          	auipc	ra,0xffffe
    80003bee:	7ce080e7          	jalr	1998(ra) # 800023b8 <fork>
}
    80003bf2:	60a2                	ld	ra,8(sp)
    80003bf4:	6402                	ld	s0,0(sp)
    80003bf6:	0141                	addi	sp,sp,16
    80003bf8:	8082                	ret

0000000080003bfa <sys_wait>:

uint64 sys_wait(void)
{
    80003bfa:	1101                	addi	sp,sp,-32
    80003bfc:	ec06                	sd	ra,24(sp)
    80003bfe:	e822                	sd	s0,16(sp)
    80003c00:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003c02:	fe840593          	addi	a1,s0,-24
    80003c06:	4501                	li	a0,0
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	ddc080e7          	jalr	-548(ra) # 800039e4 <argaddr>
  return wait(p);
    80003c10:	fe843503          	ld	a0,-24(s0)
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	f94080e7          	jalr	-108(ra) # 80002ba8 <wait>
}
    80003c1c:	60e2                	ld	ra,24(sp)
    80003c1e:	6442                	ld	s0,16(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret

0000000080003c24 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003c24:	7139                	addi	sp,sp,-64
    80003c26:	fc06                	sd	ra,56(sp)
    80003c28:	f822                	sd	s0,48(sp)
    80003c2a:	f426                	sd	s1,40(sp)
    80003c2c:	f04a                	sd	s2,32(sp)
    80003c2e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003c30:	fd840593          	addi	a1,s0,-40
    80003c34:	4501                	li	a0,0
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	dae080e7          	jalr	-594(ra) # 800039e4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003c3e:	fd040593          	addi	a1,s0,-48
    80003c42:	4505                	li	a0,1
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	da0080e7          	jalr	-608(ra) # 800039e4 <argaddr>
  argaddr(2, &addr2);
    80003c4c:	fc840593          	addi	a1,s0,-56
    80003c50:	4509                	li	a0,2
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	d92080e7          	jalr	-622(ra) # 800039e4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003c5a:	fc040613          	addi	a2,s0,-64
    80003c5e:	fc440593          	addi	a1,s0,-60
    80003c62:	fd843503          	ld	a0,-40(s0)
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	06a080e7          	jalr	106(ra) # 80002cd0 <waitx>
    80003c6e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003c70:	ffffe097          	auipc	ra,0xffffe
    80003c74:	192080e7          	jalr	402(ra) # 80001e02 <myproc>
    80003c78:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003c7a:	4691                	li	a3,4
    80003c7c:	fc440613          	addi	a2,s0,-60
    80003c80:	fd043583          	ld	a1,-48(s0)
    80003c84:	6928                	ld	a0,80(a0)
    80003c86:	ffffe097          	auipc	ra,0xffffe
    80003c8a:	c36080e7          	jalr	-970(ra) # 800018bc <copyout>
    return -1;
    80003c8e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003c90:	00054f63          	bltz	a0,80003cae <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003c94:	4691                	li	a3,4
    80003c96:	fc040613          	addi	a2,s0,-64
    80003c9a:	fc843583          	ld	a1,-56(s0)
    80003c9e:	68a8                	ld	a0,80(s1)
    80003ca0:	ffffe097          	auipc	ra,0xffffe
    80003ca4:	c1c080e7          	jalr	-996(ra) # 800018bc <copyout>
    80003ca8:	00054a63          	bltz	a0,80003cbc <sys_waitx+0x98>
    return -1;
  return ret;
    80003cac:	87ca                	mv	a5,s2
}
    80003cae:	853e                	mv	a0,a5
    80003cb0:	70e2                	ld	ra,56(sp)
    80003cb2:	7442                	ld	s0,48(sp)
    80003cb4:	74a2                	ld	s1,40(sp)
    80003cb6:	7902                	ld	s2,32(sp)
    80003cb8:	6121                	addi	sp,sp,64
    80003cba:	8082                	ret
    return -1;
    80003cbc:	57fd                	li	a5,-1
    80003cbe:	bfc5                	j	80003cae <sys_waitx+0x8a>

0000000080003cc0 <sys_sbrk>:

uint64 sys_sbrk(void)
{
    80003cc0:	7179                	addi	sp,sp,-48
    80003cc2:	f406                	sd	ra,40(sp)
    80003cc4:	f022                	sd	s0,32(sp)
    80003cc6:	ec26                	sd	s1,24(sp)
    80003cc8:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003cca:	fdc40593          	addi	a1,s0,-36
    80003cce:	4501                	li	a0,0
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	cf4080e7          	jalr	-780(ra) # 800039c4 <argint>
  addr = myproc()->sz;
    80003cd8:	ffffe097          	auipc	ra,0xffffe
    80003cdc:	12a080e7          	jalr	298(ra) # 80001e02 <myproc>
    80003ce0:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003ce2:	fdc42503          	lw	a0,-36(s0)
    80003ce6:	ffffe097          	auipc	ra,0xffffe
    80003cea:	676080e7          	jalr	1654(ra) # 8000235c <growproc>
    80003cee:	00054863          	bltz	a0,80003cfe <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	70a2                	ld	ra,40(sp)
    80003cf6:	7402                	ld	s0,32(sp)
    80003cf8:	64e2                	ld	s1,24(sp)
    80003cfa:	6145                	addi	sp,sp,48
    80003cfc:	8082                	ret
    return -1;
    80003cfe:	54fd                	li	s1,-1
    80003d00:	bfcd                	j	80003cf2 <sys_sbrk+0x32>

0000000080003d02 <sys_sleep>:

uint64 sys_sleep(void)
{
    80003d02:	7139                	addi	sp,sp,-64
    80003d04:	fc06                	sd	ra,56(sp)
    80003d06:	f822                	sd	s0,48(sp)
    80003d08:	f426                	sd	s1,40(sp)
    80003d0a:	f04a                	sd	s2,32(sp)
    80003d0c:	ec4e                	sd	s3,24(sp)
    80003d0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003d10:	fcc40593          	addi	a1,s0,-52
    80003d14:	4501                	li	a0,0
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	cae080e7          	jalr	-850(ra) # 800039c4 <argint>
  acquire(&tickslock);
    80003d1e:	00238517          	auipc	a0,0x238
    80003d22:	26a50513          	addi	a0,a0,618 # 8023bf88 <tickslock>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	0f0080e7          	jalr	240(ra) # 80000e16 <acquire>
  ticks0 = ticks;
    80003d2e:	00006917          	auipc	s2,0x6
    80003d32:	f0292903          	lw	s2,-254(s2) # 80009c30 <ticks>
  while (ticks - ticks0 < n)
    80003d36:	fcc42783          	lw	a5,-52(s0)
    80003d3a:	cf9d                	beqz	a5,80003d78 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003d3c:	00238997          	auipc	s3,0x238
    80003d40:	24c98993          	addi	s3,s3,588 # 8023bf88 <tickslock>
    80003d44:	00006497          	auipc	s1,0x6
    80003d48:	eec48493          	addi	s1,s1,-276 # 80009c30 <ticks>
    if (killed(myproc()))
    80003d4c:	ffffe097          	auipc	ra,0xffffe
    80003d50:	0b6080e7          	jalr	182(ra) # 80001e02 <myproc>
    80003d54:	fffff097          	auipc	ra,0xfffff
    80003d58:	3a2080e7          	jalr	930(ra) # 800030f6 <killed>
    80003d5c:	ed15                	bnez	a0,80003d98 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003d5e:	85ce                	mv	a1,s3
    80003d60:	8526                	mv	a0,s1
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	de2080e7          	jalr	-542(ra) # 80002b44 <sleep>
  while (ticks - ticks0 < n)
    80003d6a:	409c                	lw	a5,0(s1)
    80003d6c:	412787bb          	subw	a5,a5,s2
    80003d70:	fcc42703          	lw	a4,-52(s0)
    80003d74:	fce7ece3          	bltu	a5,a4,80003d4c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003d78:	00238517          	auipc	a0,0x238
    80003d7c:	21050513          	addi	a0,a0,528 # 8023bf88 <tickslock>
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	14a080e7          	jalr	330(ra) # 80000eca <release>
  return 0;
    80003d88:	4501                	li	a0,0
}
    80003d8a:	70e2                	ld	ra,56(sp)
    80003d8c:	7442                	ld	s0,48(sp)
    80003d8e:	74a2                	ld	s1,40(sp)
    80003d90:	7902                	ld	s2,32(sp)
    80003d92:	69e2                	ld	s3,24(sp)
    80003d94:	6121                	addi	sp,sp,64
    80003d96:	8082                	ret
      release(&tickslock);
    80003d98:	00238517          	auipc	a0,0x238
    80003d9c:	1f050513          	addi	a0,a0,496 # 8023bf88 <tickslock>
    80003da0:	ffffd097          	auipc	ra,0xffffd
    80003da4:	12a080e7          	jalr	298(ra) # 80000eca <release>
      return -1;
    80003da8:	557d                	li	a0,-1
    80003daa:	b7c5                	j	80003d8a <sys_sleep+0x88>

0000000080003dac <sys_kill>:

uint64 sys_kill(void)
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003db4:	fec40593          	addi	a1,s0,-20
    80003db8:	4501                	li	a0,0
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	c0a080e7          	jalr	-1014(ra) # 800039c4 <argint>
  return kill(pid);
    80003dc2:	fec42503          	lw	a0,-20(s0)
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	25a080e7          	jalr	602(ra) # 80003020 <kill>
}
    80003dce:	60e2                	ld	ra,24(sp)
    80003dd0:	6442                	ld	s0,16(sp)
    80003dd2:	6105                	addi	sp,sp,32
    80003dd4:	8082                	ret

0000000080003dd6 <sys_uptime>:

uint64 sys_uptime(void)
{
    80003dd6:	1101                	addi	sp,sp,-32
    80003dd8:	ec06                	sd	ra,24(sp)
    80003dda:	e822                	sd	s0,16(sp)
    80003ddc:	e426                	sd	s1,8(sp)
    80003dde:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003de0:	00238517          	auipc	a0,0x238
    80003de4:	1a850513          	addi	a0,a0,424 # 8023bf88 <tickslock>
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	02e080e7          	jalr	46(ra) # 80000e16 <acquire>
  xticks = ticks;
    80003df0:	00006497          	auipc	s1,0x6
    80003df4:	e404a483          	lw	s1,-448(s1) # 80009c30 <ticks>
  release(&tickslock);
    80003df8:	00238517          	auipc	a0,0x238
    80003dfc:	19050513          	addi	a0,a0,400 # 8023bf88 <tickslock>
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	0ca080e7          	jalr	202(ra) # 80000eca <release>
  return xticks;
}
    80003e08:	02049513          	slli	a0,s1,0x20
    80003e0c:	9101                	srli	a0,a0,0x20
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	64a2                	ld	s1,8(sp)
    80003e14:	6105                	addi	sp,sp,32
    80003e16:	8082                	ret

0000000080003e18 <sys_trace>:

uint64 sys_trace(void)
{
    80003e18:	1141                	addi	sp,sp,-16
    80003e1a:	e406                	sd	ra,8(sp)
    80003e1c:	e022                	sd	s0,0(sp)
    80003e1e:	0800                	addi	s0,sp,16
  argint(0, &myproc()->bitmask);
    80003e20:	ffffe097          	auipc	ra,0xffffe
    80003e24:	fe2080e7          	jalr	-30(ra) # 80001e02 <myproc>
    80003e28:	16850593          	addi	a1,a0,360
    80003e2c:	4501                	li	a0,0
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	b96080e7          	jalr	-1130(ra) # 800039c4 <argint>
  return 0;
}
    80003e36:	4501                	li	a0,0
    80003e38:	60a2                	ld	ra,8(sp)
    80003e3a:	6402                	ld	s0,0(sp)
    80003e3c:	0141                	addi	sp,sp,16
    80003e3e:	8082                	ret

0000000080003e40 <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80003e40:	1101                	addi	sp,sp,-32
    80003e42:	ec06                	sd	ra,24(sp)
    80003e44:	e822                	sd	s0,16(sp)
    80003e46:	e426                	sd	s1,8(sp)
    80003e48:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003e4a:	ffffe097          	auipc	ra,0xffffe
    80003e4e:	fb8080e7          	jalr	-72(ra) # 80001e02 <myproc>
    80003e52:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->cpy_trapframe, sizeof(*(p->trapframe)));
    80003e54:	12000613          	li	a2,288
    80003e58:	18853583          	ld	a1,392(a0)
    80003e5c:	6d28                	ld	a0,88(a0)
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	114080e7          	jalr	276(ra) # 80000f72 <memmove>

  p->completed_clockval = 0;
    80003e66:	1604aa23          	sw	zero,372(s1)
  p->is_sigalarm = 0;
    80003e6a:	1604a623          	sw	zero,364(s1)

  // printf("* handler is %d\n", handler)
  // printf("~ clockval is %d\n", curr_clockval);

  usertrapret();
    80003e6e:	fffff097          	auipc	ra,0xfffff
    80003e72:	5a8080e7          	jalr	1448(ra) # 80003416 <usertrapret>
  return 0;
}
    80003e76:	4501                	li	a0,0
    80003e78:	60e2                	ld	ra,24(sp)
    80003e7a:	6442                	ld	s0,16(sp)
    80003e7c:	64a2                	ld	s1,8(sp)
    80003e7e:	6105                	addi	sp,sp,32
    80003e80:	8082                	ret

0000000080003e82 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80003e82:	7179                	addi	sp,sp,-48
    80003e84:	f406                	sd	ra,40(sp)
    80003e86:	f022                	sd	s0,32(sp)
    80003e88:	ec26                	sd	s1,24(sp)
    80003e8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80003e8c:	ffffe097          	auipc	ra,0xffffe
    80003e90:	f76080e7          	jalr	-138(ra) # 80001e02 <myproc>
    80003e94:	84aa                	mv	s1,a0
  int curr_clockval;
  argint(0, &curr_clockval);
    80003e96:	fdc40593          	addi	a1,s0,-36
    80003e9a:	4501                	li	a0,0
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	b28080e7          	jalr	-1240(ra) # 800039c4 <argint>

  uint64 curr_handler;
  argaddr(1, &curr_handler);
    80003ea4:	fd040593          	addi	a1,s0,-48
    80003ea8:	4505                	li	a0,1
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	b3a080e7          	jalr	-1222(ra) # 800039e4 <argaddr>

  // printf("* handler is %d\n", curr_handler);
  // printf("~ clockval is %d\n", curr_clockval);

  p->is_sigalarm = 0;
    80003eb2:	1604a623          	sw	zero,364(s1)
  p->completed_clockval = 0;
    80003eb6:	1604aa23          	sw	zero,372(s1)

  p->clockval = curr_clockval;
    80003eba:	fdc42783          	lw	a5,-36(s0)
    80003ebe:	16f4a823          	sw	a5,368(s1)
  p->handler = curr_handler; // to store the handler function address
    80003ec2:	fd043783          	ld	a5,-48(s0)
    80003ec6:	16f4bc23          	sd	a5,376(s1)
  return 0;
}
    80003eca:	4501                	li	a0,0
    80003ecc:	70a2                	ld	ra,40(sp)
    80003ece:	7402                	ld	s0,32(sp)
    80003ed0:	64e2                	ld	s1,24(sp)
    80003ed2:	6145                	addi	sp,sp,48
    80003ed4:	8082                	ret

0000000080003ed6 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003ed6:	1141                	addi	sp,sp,-16
    80003ed8:	e422                	sd	s0,8(sp)
    80003eda:	0800                	addi	s0,sp,16
  // #if defined(FCFS) || defined(ROUNDROBIN)
  //   printf("Wrong scheduler\n");
  //   return 0;
  // #endif
  return 0;
}
    80003edc:	4501                	li	a0,0
    80003ede:	6422                	ld	s0,8(sp)
    80003ee0:	0141                	addi	sp,sp,16
    80003ee2:	8082                	ret

0000000080003ee4 <sys_set_tickets>:

uint64
sys_set_tickets(void)
{
    80003ee4:	1141                	addi	sp,sp,-16
    80003ee6:	e422                	sd	s0,8(sp)
    80003ee8:	0800                	addi	s0,sp,16

  return change;
#endif

  return 0;
    80003eea:	4501                	li	a0,0
    80003eec:	6422                	ld	s0,8(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003ef2:	7179                	addi	sp,sp,-48
    80003ef4:	f406                	sd	ra,40(sp)
    80003ef6:	f022                	sd	s0,32(sp)
    80003ef8:	ec26                	sd	s1,24(sp)
    80003efa:	e84a                	sd	s2,16(sp)
    80003efc:	e44e                	sd	s3,8(sp)
    80003efe:	e052                	sd	s4,0(sp)
    80003f00:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003f02:	00006597          	auipc	a1,0x6
    80003f06:	81658593          	addi	a1,a1,-2026 # 80009718 <syscalls+0xe0>
    80003f0a:	00238517          	auipc	a0,0x238
    80003f0e:	09650513          	addi	a0,a0,150 # 8023bfa0 <bcache>
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	e74080e7          	jalr	-396(ra) # 80000d86 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003f1a:	00240797          	auipc	a5,0x240
    80003f1e:	08678793          	addi	a5,a5,134 # 80243fa0 <bcache+0x8000>
    80003f22:	00240717          	auipc	a4,0x240
    80003f26:	2e670713          	addi	a4,a4,742 # 80244208 <bcache+0x8268>
    80003f2a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003f2e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003f32:	00238497          	auipc	s1,0x238
    80003f36:	08648493          	addi	s1,s1,134 # 8023bfb8 <bcache+0x18>
    b->next = bcache.head.next;
    80003f3a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003f3c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003f3e:	00005a17          	auipc	s4,0x5
    80003f42:	7e2a0a13          	addi	s4,s4,2018 # 80009720 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003f46:	2b893783          	ld	a5,696(s2)
    80003f4a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003f4c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003f50:	85d2                	mv	a1,s4
    80003f52:	01048513          	addi	a0,s1,16
    80003f56:	00001097          	auipc	ra,0x1
    80003f5a:	4c4080e7          	jalr	1220(ra) # 8000541a <initsleeplock>
    bcache.head.next->prev = b;
    80003f5e:	2b893783          	ld	a5,696(s2)
    80003f62:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003f64:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003f68:	45848493          	addi	s1,s1,1112
    80003f6c:	fd349de3          	bne	s1,s3,80003f46 <binit+0x54>
  }
}
    80003f70:	70a2                	ld	ra,40(sp)
    80003f72:	7402                	ld	s0,32(sp)
    80003f74:	64e2                	ld	s1,24(sp)
    80003f76:	6942                	ld	s2,16(sp)
    80003f78:	69a2                	ld	s3,8(sp)
    80003f7a:	6a02                	ld	s4,0(sp)
    80003f7c:	6145                	addi	sp,sp,48
    80003f7e:	8082                	ret

0000000080003f80 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003f80:	7179                	addi	sp,sp,-48
    80003f82:	f406                	sd	ra,40(sp)
    80003f84:	f022                	sd	s0,32(sp)
    80003f86:	ec26                	sd	s1,24(sp)
    80003f88:	e84a                	sd	s2,16(sp)
    80003f8a:	e44e                	sd	s3,8(sp)
    80003f8c:	1800                	addi	s0,sp,48
    80003f8e:	89aa                	mv	s3,a0
    80003f90:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003f92:	00238517          	auipc	a0,0x238
    80003f96:	00e50513          	addi	a0,a0,14 # 8023bfa0 <bcache>
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	e7c080e7          	jalr	-388(ra) # 80000e16 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003fa2:	00240497          	auipc	s1,0x240
    80003fa6:	2b64b483          	ld	s1,694(s1) # 80244258 <bcache+0x82b8>
    80003faa:	00240797          	auipc	a5,0x240
    80003fae:	25e78793          	addi	a5,a5,606 # 80244208 <bcache+0x8268>
    80003fb2:	02f48f63          	beq	s1,a5,80003ff0 <bread+0x70>
    80003fb6:	873e                	mv	a4,a5
    80003fb8:	a021                	j	80003fc0 <bread+0x40>
    80003fba:	68a4                	ld	s1,80(s1)
    80003fbc:	02e48a63          	beq	s1,a4,80003ff0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003fc0:	449c                	lw	a5,8(s1)
    80003fc2:	ff379ce3          	bne	a5,s3,80003fba <bread+0x3a>
    80003fc6:	44dc                	lw	a5,12(s1)
    80003fc8:	ff2799e3          	bne	a5,s2,80003fba <bread+0x3a>
      b->refcnt++;
    80003fcc:	40bc                	lw	a5,64(s1)
    80003fce:	2785                	addiw	a5,a5,1
    80003fd0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003fd2:	00238517          	auipc	a0,0x238
    80003fd6:	fce50513          	addi	a0,a0,-50 # 8023bfa0 <bcache>
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	ef0080e7          	jalr	-272(ra) # 80000eca <release>
      acquiresleep(&b->lock);
    80003fe2:	01048513          	addi	a0,s1,16
    80003fe6:	00001097          	auipc	ra,0x1
    80003fea:	46e080e7          	jalr	1134(ra) # 80005454 <acquiresleep>
      return b;
    80003fee:	a8b9                	j	8000404c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ff0:	00240497          	auipc	s1,0x240
    80003ff4:	2604b483          	ld	s1,608(s1) # 80244250 <bcache+0x82b0>
    80003ff8:	00240797          	auipc	a5,0x240
    80003ffc:	21078793          	addi	a5,a5,528 # 80244208 <bcache+0x8268>
    80004000:	00f48863          	beq	s1,a5,80004010 <bread+0x90>
    80004004:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80004006:	40bc                	lw	a5,64(s1)
    80004008:	cf81                	beqz	a5,80004020 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000400a:	64a4                	ld	s1,72(s1)
    8000400c:	fee49de3          	bne	s1,a4,80004006 <bread+0x86>
  panic("bget: no buffers");
    80004010:	00005517          	auipc	a0,0x5
    80004014:	71850513          	addi	a0,a0,1816 # 80009728 <syscalls+0xf0>
    80004018:	ffffc097          	auipc	ra,0xffffc
    8000401c:	52c080e7          	jalr	1324(ra) # 80000544 <panic>
      b->dev = dev;
    80004020:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80004024:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80004028:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000402c:	4785                	li	a5,1
    8000402e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004030:	00238517          	auipc	a0,0x238
    80004034:	f7050513          	addi	a0,a0,-144 # 8023bfa0 <bcache>
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	e92080e7          	jalr	-366(ra) # 80000eca <release>
      acquiresleep(&b->lock);
    80004040:	01048513          	addi	a0,s1,16
    80004044:	00001097          	auipc	ra,0x1
    80004048:	410080e7          	jalr	1040(ra) # 80005454 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000404c:	409c                	lw	a5,0(s1)
    8000404e:	cb89                	beqz	a5,80004060 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80004050:	8526                	mv	a0,s1
    80004052:	70a2                	ld	ra,40(sp)
    80004054:	7402                	ld	s0,32(sp)
    80004056:	64e2                	ld	s1,24(sp)
    80004058:	6942                	ld	s2,16(sp)
    8000405a:	69a2                	ld	s3,8(sp)
    8000405c:	6145                	addi	sp,sp,48
    8000405e:	8082                	ret
    virtio_disk_rw(b, 0);
    80004060:	4581                	li	a1,0
    80004062:	8526                	mv	a0,s1
    80004064:	00003097          	auipc	ra,0x3
    80004068:	fc4080e7          	jalr	-60(ra) # 80007028 <virtio_disk_rw>
    b->valid = 1;
    8000406c:	4785                	li	a5,1
    8000406e:	c09c                	sw	a5,0(s1)
  return b;
    80004070:	b7c5                	j	80004050 <bread+0xd0>

0000000080004072 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80004072:	1101                	addi	sp,sp,-32
    80004074:	ec06                	sd	ra,24(sp)
    80004076:	e822                	sd	s0,16(sp)
    80004078:	e426                	sd	s1,8(sp)
    8000407a:	1000                	addi	s0,sp,32
    8000407c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000407e:	0541                	addi	a0,a0,16
    80004080:	00001097          	auipc	ra,0x1
    80004084:	46e080e7          	jalr	1134(ra) # 800054ee <holdingsleep>
    80004088:	cd01                	beqz	a0,800040a0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000408a:	4585                	li	a1,1
    8000408c:	8526                	mv	a0,s1
    8000408e:	00003097          	auipc	ra,0x3
    80004092:	f9a080e7          	jalr	-102(ra) # 80007028 <virtio_disk_rw>
}
    80004096:	60e2                	ld	ra,24(sp)
    80004098:	6442                	ld	s0,16(sp)
    8000409a:	64a2                	ld	s1,8(sp)
    8000409c:	6105                	addi	sp,sp,32
    8000409e:	8082                	ret
    panic("bwrite");
    800040a0:	00005517          	auipc	a0,0x5
    800040a4:	6a050513          	addi	a0,a0,1696 # 80009740 <syscalls+0x108>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	49c080e7          	jalr	1180(ra) # 80000544 <panic>

00000000800040b0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800040b0:	1101                	addi	sp,sp,-32
    800040b2:	ec06                	sd	ra,24(sp)
    800040b4:	e822                	sd	s0,16(sp)
    800040b6:	e426                	sd	s1,8(sp)
    800040b8:	e04a                	sd	s2,0(sp)
    800040ba:	1000                	addi	s0,sp,32
    800040bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800040be:	01050913          	addi	s2,a0,16
    800040c2:	854a                	mv	a0,s2
    800040c4:	00001097          	auipc	ra,0x1
    800040c8:	42a080e7          	jalr	1066(ra) # 800054ee <holdingsleep>
    800040cc:	c92d                	beqz	a0,8000413e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800040ce:	854a                	mv	a0,s2
    800040d0:	00001097          	auipc	ra,0x1
    800040d4:	3da080e7          	jalr	986(ra) # 800054aa <releasesleep>

  acquire(&bcache.lock);
    800040d8:	00238517          	auipc	a0,0x238
    800040dc:	ec850513          	addi	a0,a0,-312 # 8023bfa0 <bcache>
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	d36080e7          	jalr	-714(ra) # 80000e16 <acquire>
  b->refcnt--;
    800040e8:	40bc                	lw	a5,64(s1)
    800040ea:	37fd                	addiw	a5,a5,-1
    800040ec:	0007871b          	sext.w	a4,a5
    800040f0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800040f2:	eb05                	bnez	a4,80004122 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800040f4:	68bc                	ld	a5,80(s1)
    800040f6:	64b8                	ld	a4,72(s1)
    800040f8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800040fa:	64bc                	ld	a5,72(s1)
    800040fc:	68b8                	ld	a4,80(s1)
    800040fe:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80004100:	00240797          	auipc	a5,0x240
    80004104:	ea078793          	addi	a5,a5,-352 # 80243fa0 <bcache+0x8000>
    80004108:	2b87b703          	ld	a4,696(a5)
    8000410c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000410e:	00240717          	auipc	a4,0x240
    80004112:	0fa70713          	addi	a4,a4,250 # 80244208 <bcache+0x8268>
    80004116:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80004118:	2b87b703          	ld	a4,696(a5)
    8000411c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000411e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80004122:	00238517          	auipc	a0,0x238
    80004126:	e7e50513          	addi	a0,a0,-386 # 8023bfa0 <bcache>
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	da0080e7          	jalr	-608(ra) # 80000eca <release>
}
    80004132:	60e2                	ld	ra,24(sp)
    80004134:	6442                	ld	s0,16(sp)
    80004136:	64a2                	ld	s1,8(sp)
    80004138:	6902                	ld	s2,0(sp)
    8000413a:	6105                	addi	sp,sp,32
    8000413c:	8082                	ret
    panic("brelse");
    8000413e:	00005517          	auipc	a0,0x5
    80004142:	60a50513          	addi	a0,a0,1546 # 80009748 <syscalls+0x110>
    80004146:	ffffc097          	auipc	ra,0xffffc
    8000414a:	3fe080e7          	jalr	1022(ra) # 80000544 <panic>

000000008000414e <bpin>:

void
bpin(struct buf *b) {
    8000414e:	1101                	addi	sp,sp,-32
    80004150:	ec06                	sd	ra,24(sp)
    80004152:	e822                	sd	s0,16(sp)
    80004154:	e426                	sd	s1,8(sp)
    80004156:	1000                	addi	s0,sp,32
    80004158:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000415a:	00238517          	auipc	a0,0x238
    8000415e:	e4650513          	addi	a0,a0,-442 # 8023bfa0 <bcache>
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	cb4080e7          	jalr	-844(ra) # 80000e16 <acquire>
  b->refcnt++;
    8000416a:	40bc                	lw	a5,64(s1)
    8000416c:	2785                	addiw	a5,a5,1
    8000416e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004170:	00238517          	auipc	a0,0x238
    80004174:	e3050513          	addi	a0,a0,-464 # 8023bfa0 <bcache>
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	d52080e7          	jalr	-686(ra) # 80000eca <release>
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6105                	addi	sp,sp,32
    80004188:	8082                	ret

000000008000418a <bunpin>:

void
bunpin(struct buf *b) {
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	1000                	addi	s0,sp,32
    80004194:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004196:	00238517          	auipc	a0,0x238
    8000419a:	e0a50513          	addi	a0,a0,-502 # 8023bfa0 <bcache>
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	c78080e7          	jalr	-904(ra) # 80000e16 <acquire>
  b->refcnt--;
    800041a6:	40bc                	lw	a5,64(s1)
    800041a8:	37fd                	addiw	a5,a5,-1
    800041aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800041ac:	00238517          	auipc	a0,0x238
    800041b0:	df450513          	addi	a0,a0,-524 # 8023bfa0 <bcache>
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	d16080e7          	jalr	-746(ra) # 80000eca <release>
}
    800041bc:	60e2                	ld	ra,24(sp)
    800041be:	6442                	ld	s0,16(sp)
    800041c0:	64a2                	ld	s1,8(sp)
    800041c2:	6105                	addi	sp,sp,32
    800041c4:	8082                	ret

00000000800041c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800041c6:	1101                	addi	sp,sp,-32
    800041c8:	ec06                	sd	ra,24(sp)
    800041ca:	e822                	sd	s0,16(sp)
    800041cc:	e426                	sd	s1,8(sp)
    800041ce:	e04a                	sd	s2,0(sp)
    800041d0:	1000                	addi	s0,sp,32
    800041d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800041d4:	00d5d59b          	srliw	a1,a1,0xd
    800041d8:	00240797          	auipc	a5,0x240
    800041dc:	4a47a783          	lw	a5,1188(a5) # 8024467c <sb+0x1c>
    800041e0:	9dbd                	addw	a1,a1,a5
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	d9e080e7          	jalr	-610(ra) # 80003f80 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800041ea:	0074f713          	andi	a4,s1,7
    800041ee:	4785                	li	a5,1
    800041f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800041f4:	14ce                	slli	s1,s1,0x33
    800041f6:	90d9                	srli	s1,s1,0x36
    800041f8:	00950733          	add	a4,a0,s1
    800041fc:	05874703          	lbu	a4,88(a4)
    80004200:	00e7f6b3          	and	a3,a5,a4
    80004204:	c69d                	beqz	a3,80004232 <bfree+0x6c>
    80004206:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80004208:	94aa                	add	s1,s1,a0
    8000420a:	fff7c793          	not	a5,a5
    8000420e:	8ff9                	and	a5,a5,a4
    80004210:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80004214:	00001097          	auipc	ra,0x1
    80004218:	120080e7          	jalr	288(ra) # 80005334 <log_write>
  brelse(bp);
    8000421c:	854a                	mv	a0,s2
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	e92080e7          	jalr	-366(ra) # 800040b0 <brelse>
}
    80004226:	60e2                	ld	ra,24(sp)
    80004228:	6442                	ld	s0,16(sp)
    8000422a:	64a2                	ld	s1,8(sp)
    8000422c:	6902                	ld	s2,0(sp)
    8000422e:	6105                	addi	sp,sp,32
    80004230:	8082                	ret
    panic("freeing free block");
    80004232:	00005517          	auipc	a0,0x5
    80004236:	51e50513          	addi	a0,a0,1310 # 80009750 <syscalls+0x118>
    8000423a:	ffffc097          	auipc	ra,0xffffc
    8000423e:	30a080e7          	jalr	778(ra) # 80000544 <panic>

0000000080004242 <balloc>:
{
    80004242:	711d                	addi	sp,sp,-96
    80004244:	ec86                	sd	ra,88(sp)
    80004246:	e8a2                	sd	s0,80(sp)
    80004248:	e4a6                	sd	s1,72(sp)
    8000424a:	e0ca                	sd	s2,64(sp)
    8000424c:	fc4e                	sd	s3,56(sp)
    8000424e:	f852                	sd	s4,48(sp)
    80004250:	f456                	sd	s5,40(sp)
    80004252:	f05a                	sd	s6,32(sp)
    80004254:	ec5e                	sd	s7,24(sp)
    80004256:	e862                	sd	s8,16(sp)
    80004258:	e466                	sd	s9,8(sp)
    8000425a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000425c:	00240797          	auipc	a5,0x240
    80004260:	4087a783          	lw	a5,1032(a5) # 80244664 <sb+0x4>
    80004264:	10078163          	beqz	a5,80004366 <balloc+0x124>
    80004268:	8baa                	mv	s7,a0
    8000426a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000426c:	00240b17          	auipc	s6,0x240
    80004270:	3f4b0b13          	addi	s6,s6,1012 # 80244660 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004274:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80004276:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004278:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000427a:	6c89                	lui	s9,0x2
    8000427c:	a061                	j	80004304 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000427e:	974a                	add	a4,a4,s2
    80004280:	8fd5                	or	a5,a5,a3
    80004282:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80004286:	854a                	mv	a0,s2
    80004288:	00001097          	auipc	ra,0x1
    8000428c:	0ac080e7          	jalr	172(ra) # 80005334 <log_write>
        brelse(bp);
    80004290:	854a                	mv	a0,s2
    80004292:	00000097          	auipc	ra,0x0
    80004296:	e1e080e7          	jalr	-482(ra) # 800040b0 <brelse>
  bp = bread(dev, bno);
    8000429a:	85a6                	mv	a1,s1
    8000429c:	855e                	mv	a0,s7
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	ce2080e7          	jalr	-798(ra) # 80003f80 <bread>
    800042a6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800042a8:	40000613          	li	a2,1024
    800042ac:	4581                	li	a1,0
    800042ae:	05850513          	addi	a0,a0,88
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	c60080e7          	jalr	-928(ra) # 80000f12 <memset>
  log_write(bp);
    800042ba:	854a                	mv	a0,s2
    800042bc:	00001097          	auipc	ra,0x1
    800042c0:	078080e7          	jalr	120(ra) # 80005334 <log_write>
  brelse(bp);
    800042c4:	854a                	mv	a0,s2
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	dea080e7          	jalr	-534(ra) # 800040b0 <brelse>
}
    800042ce:	8526                	mv	a0,s1
    800042d0:	60e6                	ld	ra,88(sp)
    800042d2:	6446                	ld	s0,80(sp)
    800042d4:	64a6                	ld	s1,72(sp)
    800042d6:	6906                	ld	s2,64(sp)
    800042d8:	79e2                	ld	s3,56(sp)
    800042da:	7a42                	ld	s4,48(sp)
    800042dc:	7aa2                	ld	s5,40(sp)
    800042de:	7b02                	ld	s6,32(sp)
    800042e0:	6be2                	ld	s7,24(sp)
    800042e2:	6c42                	ld	s8,16(sp)
    800042e4:	6ca2                	ld	s9,8(sp)
    800042e6:	6125                	addi	sp,sp,96
    800042e8:	8082                	ret
    brelse(bp);
    800042ea:	854a                	mv	a0,s2
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	dc4080e7          	jalr	-572(ra) # 800040b0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800042f4:	015c87bb          	addw	a5,s9,s5
    800042f8:	00078a9b          	sext.w	s5,a5
    800042fc:	004b2703          	lw	a4,4(s6)
    80004300:	06eaf363          	bgeu	s5,a4,80004366 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80004304:	41fad79b          	sraiw	a5,s5,0x1f
    80004308:	0137d79b          	srliw	a5,a5,0x13
    8000430c:	015787bb          	addw	a5,a5,s5
    80004310:	40d7d79b          	sraiw	a5,a5,0xd
    80004314:	01cb2583          	lw	a1,28(s6)
    80004318:	9dbd                	addw	a1,a1,a5
    8000431a:	855e                	mv	a0,s7
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	c64080e7          	jalr	-924(ra) # 80003f80 <bread>
    80004324:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004326:	004b2503          	lw	a0,4(s6)
    8000432a:	000a849b          	sext.w	s1,s5
    8000432e:	8662                	mv	a2,s8
    80004330:	faa4fde3          	bgeu	s1,a0,800042ea <balloc+0xa8>
      m = 1 << (bi % 8);
    80004334:	41f6579b          	sraiw	a5,a2,0x1f
    80004338:	01d7d69b          	srliw	a3,a5,0x1d
    8000433c:	00c6873b          	addw	a4,a3,a2
    80004340:	00777793          	andi	a5,a4,7
    80004344:	9f95                	subw	a5,a5,a3
    80004346:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000434a:	4037571b          	sraiw	a4,a4,0x3
    8000434e:	00e906b3          	add	a3,s2,a4
    80004352:	0586c683          	lbu	a3,88(a3)
    80004356:	00d7f5b3          	and	a1,a5,a3
    8000435a:	d195                	beqz	a1,8000427e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000435c:	2605                	addiw	a2,a2,1
    8000435e:	2485                	addiw	s1,s1,1
    80004360:	fd4618e3          	bne	a2,s4,80004330 <balloc+0xee>
    80004364:	b759                	j	800042ea <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80004366:	00005517          	auipc	a0,0x5
    8000436a:	40250513          	addi	a0,a0,1026 # 80009768 <syscalls+0x130>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	220080e7          	jalr	544(ra) # 8000058e <printf>
  return 0;
    80004376:	4481                	li	s1,0
    80004378:	bf99                	j	800042ce <balloc+0x8c>

000000008000437a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000437a:	7179                	addi	sp,sp,-48
    8000437c:	f406                	sd	ra,40(sp)
    8000437e:	f022                	sd	s0,32(sp)
    80004380:	ec26                	sd	s1,24(sp)
    80004382:	e84a                	sd	s2,16(sp)
    80004384:	e44e                	sd	s3,8(sp)
    80004386:	e052                	sd	s4,0(sp)
    80004388:	1800                	addi	s0,sp,48
    8000438a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000438c:	47ad                	li	a5,11
    8000438e:	02b7e763          	bltu	a5,a1,800043bc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80004392:	02059493          	slli	s1,a1,0x20
    80004396:	9081                	srli	s1,s1,0x20
    80004398:	048a                	slli	s1,s1,0x2
    8000439a:	94aa                	add	s1,s1,a0
    8000439c:	0504a903          	lw	s2,80(s1)
    800043a0:	06091e63          	bnez	s2,8000441c <bmap+0xa2>
      addr = balloc(ip->dev);
    800043a4:	4108                	lw	a0,0(a0)
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	e9c080e7          	jalr	-356(ra) # 80004242 <balloc>
    800043ae:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800043b2:	06090563          	beqz	s2,8000441c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800043b6:	0524a823          	sw	s2,80(s1)
    800043ba:	a08d                	j	8000441c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800043bc:	ff45849b          	addiw	s1,a1,-12
    800043c0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800043c4:	0ff00793          	li	a5,255
    800043c8:	08e7e563          	bltu	a5,a4,80004452 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800043cc:	08052903          	lw	s2,128(a0)
    800043d0:	00091d63          	bnez	s2,800043ea <bmap+0x70>
      addr = balloc(ip->dev);
    800043d4:	4108                	lw	a0,0(a0)
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	e6c080e7          	jalr	-404(ra) # 80004242 <balloc>
    800043de:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800043e2:	02090d63          	beqz	s2,8000441c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800043e6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800043ea:	85ca                	mv	a1,s2
    800043ec:	0009a503          	lw	a0,0(s3)
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	b90080e7          	jalr	-1136(ra) # 80003f80 <bread>
    800043f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800043fa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800043fe:	02049593          	slli	a1,s1,0x20
    80004402:	9181                	srli	a1,a1,0x20
    80004404:	058a                	slli	a1,a1,0x2
    80004406:	00b784b3          	add	s1,a5,a1
    8000440a:	0004a903          	lw	s2,0(s1)
    8000440e:	02090063          	beqz	s2,8000442e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80004412:	8552                	mv	a0,s4
    80004414:	00000097          	auipc	ra,0x0
    80004418:	c9c080e7          	jalr	-868(ra) # 800040b0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000441c:	854a                	mv	a0,s2
    8000441e:	70a2                	ld	ra,40(sp)
    80004420:	7402                	ld	s0,32(sp)
    80004422:	64e2                	ld	s1,24(sp)
    80004424:	6942                	ld	s2,16(sp)
    80004426:	69a2                	ld	s3,8(sp)
    80004428:	6a02                	ld	s4,0(sp)
    8000442a:	6145                	addi	sp,sp,48
    8000442c:	8082                	ret
      addr = balloc(ip->dev);
    8000442e:	0009a503          	lw	a0,0(s3)
    80004432:	00000097          	auipc	ra,0x0
    80004436:	e10080e7          	jalr	-496(ra) # 80004242 <balloc>
    8000443a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000443e:	fc090ae3          	beqz	s2,80004412 <bmap+0x98>
        a[bn] = addr;
    80004442:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004446:	8552                	mv	a0,s4
    80004448:	00001097          	auipc	ra,0x1
    8000444c:	eec080e7          	jalr	-276(ra) # 80005334 <log_write>
    80004450:	b7c9                	j	80004412 <bmap+0x98>
  panic("bmap: out of range");
    80004452:	00005517          	auipc	a0,0x5
    80004456:	32e50513          	addi	a0,a0,814 # 80009780 <syscalls+0x148>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	0ea080e7          	jalr	234(ra) # 80000544 <panic>

0000000080004462 <iget>:
{
    80004462:	7179                	addi	sp,sp,-48
    80004464:	f406                	sd	ra,40(sp)
    80004466:	f022                	sd	s0,32(sp)
    80004468:	ec26                	sd	s1,24(sp)
    8000446a:	e84a                	sd	s2,16(sp)
    8000446c:	e44e                	sd	s3,8(sp)
    8000446e:	e052                	sd	s4,0(sp)
    80004470:	1800                	addi	s0,sp,48
    80004472:	89aa                	mv	s3,a0
    80004474:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004476:	00240517          	auipc	a0,0x240
    8000447a:	20a50513          	addi	a0,a0,522 # 80244680 <itable>
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	998080e7          	jalr	-1640(ra) # 80000e16 <acquire>
  empty = 0;
    80004486:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004488:	00240497          	auipc	s1,0x240
    8000448c:	21048493          	addi	s1,s1,528 # 80244698 <itable+0x18>
    80004490:	00242697          	auipc	a3,0x242
    80004494:	c9868693          	addi	a3,a3,-872 # 80246128 <log>
    80004498:	a039                	j	800044a6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000449a:	02090b63          	beqz	s2,800044d0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000449e:	08848493          	addi	s1,s1,136
    800044a2:	02d48a63          	beq	s1,a3,800044d6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800044a6:	449c                	lw	a5,8(s1)
    800044a8:	fef059e3          	blez	a5,8000449a <iget+0x38>
    800044ac:	4098                	lw	a4,0(s1)
    800044ae:	ff3716e3          	bne	a4,s3,8000449a <iget+0x38>
    800044b2:	40d8                	lw	a4,4(s1)
    800044b4:	ff4713e3          	bne	a4,s4,8000449a <iget+0x38>
      ip->ref++;
    800044b8:	2785                	addiw	a5,a5,1
    800044ba:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800044bc:	00240517          	auipc	a0,0x240
    800044c0:	1c450513          	addi	a0,a0,452 # 80244680 <itable>
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	a06080e7          	jalr	-1530(ra) # 80000eca <release>
      return ip;
    800044cc:	8926                	mv	s2,s1
    800044ce:	a03d                	j	800044fc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800044d0:	f7f9                	bnez	a5,8000449e <iget+0x3c>
    800044d2:	8926                	mv	s2,s1
    800044d4:	b7e9                	j	8000449e <iget+0x3c>
  if(empty == 0)
    800044d6:	02090c63          	beqz	s2,8000450e <iget+0xac>
  ip->dev = dev;
    800044da:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800044de:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800044e2:	4785                	li	a5,1
    800044e4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800044e8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800044ec:	00240517          	auipc	a0,0x240
    800044f0:	19450513          	addi	a0,a0,404 # 80244680 <itable>
    800044f4:	ffffd097          	auipc	ra,0xffffd
    800044f8:	9d6080e7          	jalr	-1578(ra) # 80000eca <release>
}
    800044fc:	854a                	mv	a0,s2
    800044fe:	70a2                	ld	ra,40(sp)
    80004500:	7402                	ld	s0,32(sp)
    80004502:	64e2                	ld	s1,24(sp)
    80004504:	6942                	ld	s2,16(sp)
    80004506:	69a2                	ld	s3,8(sp)
    80004508:	6a02                	ld	s4,0(sp)
    8000450a:	6145                	addi	sp,sp,48
    8000450c:	8082                	ret
    panic("iget: no inodes");
    8000450e:	00005517          	auipc	a0,0x5
    80004512:	28a50513          	addi	a0,a0,650 # 80009798 <syscalls+0x160>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	02e080e7          	jalr	46(ra) # 80000544 <panic>

000000008000451e <fsinit>:
fsinit(int dev) {
    8000451e:	7179                	addi	sp,sp,-48
    80004520:	f406                	sd	ra,40(sp)
    80004522:	f022                	sd	s0,32(sp)
    80004524:	ec26                	sd	s1,24(sp)
    80004526:	e84a                	sd	s2,16(sp)
    80004528:	e44e                	sd	s3,8(sp)
    8000452a:	1800                	addi	s0,sp,48
    8000452c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000452e:	4585                	li	a1,1
    80004530:	00000097          	auipc	ra,0x0
    80004534:	a50080e7          	jalr	-1456(ra) # 80003f80 <bread>
    80004538:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000453a:	00240997          	auipc	s3,0x240
    8000453e:	12698993          	addi	s3,s3,294 # 80244660 <sb>
    80004542:	02000613          	li	a2,32
    80004546:	05850593          	addi	a1,a0,88
    8000454a:	854e                	mv	a0,s3
    8000454c:	ffffd097          	auipc	ra,0xffffd
    80004550:	a26080e7          	jalr	-1498(ra) # 80000f72 <memmove>
  brelse(bp);
    80004554:	8526                	mv	a0,s1
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	b5a080e7          	jalr	-1190(ra) # 800040b0 <brelse>
  if(sb.magic != FSMAGIC)
    8000455e:	0009a703          	lw	a4,0(s3)
    80004562:	102037b7          	lui	a5,0x10203
    80004566:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000456a:	02f71263          	bne	a4,a5,8000458e <fsinit+0x70>
  initlog(dev, &sb);
    8000456e:	00240597          	auipc	a1,0x240
    80004572:	0f258593          	addi	a1,a1,242 # 80244660 <sb>
    80004576:	854a                	mv	a0,s2
    80004578:	00001097          	auipc	ra,0x1
    8000457c:	b40080e7          	jalr	-1216(ra) # 800050b8 <initlog>
}
    80004580:	70a2                	ld	ra,40(sp)
    80004582:	7402                	ld	s0,32(sp)
    80004584:	64e2                	ld	s1,24(sp)
    80004586:	6942                	ld	s2,16(sp)
    80004588:	69a2                	ld	s3,8(sp)
    8000458a:	6145                	addi	sp,sp,48
    8000458c:	8082                	ret
    panic("invalid file system");
    8000458e:	00005517          	auipc	a0,0x5
    80004592:	21a50513          	addi	a0,a0,538 # 800097a8 <syscalls+0x170>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	fae080e7          	jalr	-82(ra) # 80000544 <panic>

000000008000459e <iinit>:
{
    8000459e:	7179                	addi	sp,sp,-48
    800045a0:	f406                	sd	ra,40(sp)
    800045a2:	f022                	sd	s0,32(sp)
    800045a4:	ec26                	sd	s1,24(sp)
    800045a6:	e84a                	sd	s2,16(sp)
    800045a8:	e44e                	sd	s3,8(sp)
    800045aa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800045ac:	00005597          	auipc	a1,0x5
    800045b0:	21458593          	addi	a1,a1,532 # 800097c0 <syscalls+0x188>
    800045b4:	00240517          	auipc	a0,0x240
    800045b8:	0cc50513          	addi	a0,a0,204 # 80244680 <itable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	7ca080e7          	jalr	1994(ra) # 80000d86 <initlock>
  for(i = 0; i < NINODE; i++) {
    800045c4:	00240497          	auipc	s1,0x240
    800045c8:	0e448493          	addi	s1,s1,228 # 802446a8 <itable+0x28>
    800045cc:	00242997          	auipc	s3,0x242
    800045d0:	b6c98993          	addi	s3,s3,-1172 # 80246138 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800045d4:	00005917          	auipc	s2,0x5
    800045d8:	1f490913          	addi	s2,s2,500 # 800097c8 <syscalls+0x190>
    800045dc:	85ca                	mv	a1,s2
    800045de:	8526                	mv	a0,s1
    800045e0:	00001097          	auipc	ra,0x1
    800045e4:	e3a080e7          	jalr	-454(ra) # 8000541a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800045e8:	08848493          	addi	s1,s1,136
    800045ec:	ff3498e3          	bne	s1,s3,800045dc <iinit+0x3e>
}
    800045f0:	70a2                	ld	ra,40(sp)
    800045f2:	7402                	ld	s0,32(sp)
    800045f4:	64e2                	ld	s1,24(sp)
    800045f6:	6942                	ld	s2,16(sp)
    800045f8:	69a2                	ld	s3,8(sp)
    800045fa:	6145                	addi	sp,sp,48
    800045fc:	8082                	ret

00000000800045fe <ialloc>:
{
    800045fe:	715d                	addi	sp,sp,-80
    80004600:	e486                	sd	ra,72(sp)
    80004602:	e0a2                	sd	s0,64(sp)
    80004604:	fc26                	sd	s1,56(sp)
    80004606:	f84a                	sd	s2,48(sp)
    80004608:	f44e                	sd	s3,40(sp)
    8000460a:	f052                	sd	s4,32(sp)
    8000460c:	ec56                	sd	s5,24(sp)
    8000460e:	e85a                	sd	s6,16(sp)
    80004610:	e45e                	sd	s7,8(sp)
    80004612:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004614:	00240717          	auipc	a4,0x240
    80004618:	05872703          	lw	a4,88(a4) # 8024466c <sb+0xc>
    8000461c:	4785                	li	a5,1
    8000461e:	04e7fa63          	bgeu	a5,a4,80004672 <ialloc+0x74>
    80004622:	8aaa                	mv	s5,a0
    80004624:	8bae                	mv	s7,a1
    80004626:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004628:	00240a17          	auipc	s4,0x240
    8000462c:	038a0a13          	addi	s4,s4,56 # 80244660 <sb>
    80004630:	00048b1b          	sext.w	s6,s1
    80004634:	0044d593          	srli	a1,s1,0x4
    80004638:	018a2783          	lw	a5,24(s4)
    8000463c:	9dbd                	addw	a1,a1,a5
    8000463e:	8556                	mv	a0,s5
    80004640:	00000097          	auipc	ra,0x0
    80004644:	940080e7          	jalr	-1728(ra) # 80003f80 <bread>
    80004648:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000464a:	05850993          	addi	s3,a0,88
    8000464e:	00f4f793          	andi	a5,s1,15
    80004652:	079a                	slli	a5,a5,0x6
    80004654:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004656:	00099783          	lh	a5,0(s3)
    8000465a:	c3a1                	beqz	a5,8000469a <ialloc+0x9c>
    brelse(bp);
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	a54080e7          	jalr	-1452(ra) # 800040b0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004664:	0485                	addi	s1,s1,1
    80004666:	00ca2703          	lw	a4,12(s4)
    8000466a:	0004879b          	sext.w	a5,s1
    8000466e:	fce7e1e3          	bltu	a5,a4,80004630 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004672:	00005517          	auipc	a0,0x5
    80004676:	15e50513          	addi	a0,a0,350 # 800097d0 <syscalls+0x198>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	f14080e7          	jalr	-236(ra) # 8000058e <printf>
  return 0;
    80004682:	4501                	li	a0,0
}
    80004684:	60a6                	ld	ra,72(sp)
    80004686:	6406                	ld	s0,64(sp)
    80004688:	74e2                	ld	s1,56(sp)
    8000468a:	7942                	ld	s2,48(sp)
    8000468c:	79a2                	ld	s3,40(sp)
    8000468e:	7a02                	ld	s4,32(sp)
    80004690:	6ae2                	ld	s5,24(sp)
    80004692:	6b42                	ld	s6,16(sp)
    80004694:	6ba2                	ld	s7,8(sp)
    80004696:	6161                	addi	sp,sp,80
    80004698:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000469a:	04000613          	li	a2,64
    8000469e:	4581                	li	a1,0
    800046a0:	854e                	mv	a0,s3
    800046a2:	ffffd097          	auipc	ra,0xffffd
    800046a6:	870080e7          	jalr	-1936(ra) # 80000f12 <memset>
      dip->type = type;
    800046aa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800046ae:	854a                	mv	a0,s2
    800046b0:	00001097          	auipc	ra,0x1
    800046b4:	c84080e7          	jalr	-892(ra) # 80005334 <log_write>
      brelse(bp);
    800046b8:	854a                	mv	a0,s2
    800046ba:	00000097          	auipc	ra,0x0
    800046be:	9f6080e7          	jalr	-1546(ra) # 800040b0 <brelse>
      return iget(dev, inum);
    800046c2:	85da                	mv	a1,s6
    800046c4:	8556                	mv	a0,s5
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	d9c080e7          	jalr	-612(ra) # 80004462 <iget>
    800046ce:	bf5d                	j	80004684 <ialloc+0x86>

00000000800046d0 <iupdate>:
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800046de:	415c                	lw	a5,4(a0)
    800046e0:	0047d79b          	srliw	a5,a5,0x4
    800046e4:	00240597          	auipc	a1,0x240
    800046e8:	f945a583          	lw	a1,-108(a1) # 80244678 <sb+0x18>
    800046ec:	9dbd                	addw	a1,a1,a5
    800046ee:	4108                	lw	a0,0(a0)
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	890080e7          	jalr	-1904(ra) # 80003f80 <bread>
    800046f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800046fa:	05850793          	addi	a5,a0,88
    800046fe:	40c8                	lw	a0,4(s1)
    80004700:	893d                	andi	a0,a0,15
    80004702:	051a                	slli	a0,a0,0x6
    80004704:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004706:	04449703          	lh	a4,68(s1)
    8000470a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000470e:	04649703          	lh	a4,70(s1)
    80004712:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004716:	04849703          	lh	a4,72(s1)
    8000471a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000471e:	04a49703          	lh	a4,74(s1)
    80004722:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004726:	44f8                	lw	a4,76(s1)
    80004728:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000472a:	03400613          	li	a2,52
    8000472e:	05048593          	addi	a1,s1,80
    80004732:	0531                	addi	a0,a0,12
    80004734:	ffffd097          	auipc	ra,0xffffd
    80004738:	83e080e7          	jalr	-1986(ra) # 80000f72 <memmove>
  log_write(bp);
    8000473c:	854a                	mv	a0,s2
    8000473e:	00001097          	auipc	ra,0x1
    80004742:	bf6080e7          	jalr	-1034(ra) # 80005334 <log_write>
  brelse(bp);
    80004746:	854a                	mv	a0,s2
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	968080e7          	jalr	-1688(ra) # 800040b0 <brelse>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <idup>:
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	1000                	addi	s0,sp,32
    80004766:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004768:	00240517          	auipc	a0,0x240
    8000476c:	f1850513          	addi	a0,a0,-232 # 80244680 <itable>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	6a6080e7          	jalr	1702(ra) # 80000e16 <acquire>
  ip->ref++;
    80004778:	449c                	lw	a5,8(s1)
    8000477a:	2785                	addiw	a5,a5,1
    8000477c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000477e:	00240517          	auipc	a0,0x240
    80004782:	f0250513          	addi	a0,a0,-254 # 80244680 <itable>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	744080e7          	jalr	1860(ra) # 80000eca <release>
}
    8000478e:	8526                	mv	a0,s1
    80004790:	60e2                	ld	ra,24(sp)
    80004792:	6442                	ld	s0,16(sp)
    80004794:	64a2                	ld	s1,8(sp)
    80004796:	6105                	addi	sp,sp,32
    80004798:	8082                	ret

000000008000479a <ilock>:
{
    8000479a:	1101                	addi	sp,sp,-32
    8000479c:	ec06                	sd	ra,24(sp)
    8000479e:	e822                	sd	s0,16(sp)
    800047a0:	e426                	sd	s1,8(sp)
    800047a2:	e04a                	sd	s2,0(sp)
    800047a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800047a6:	c115                	beqz	a0,800047ca <ilock+0x30>
    800047a8:	84aa                	mv	s1,a0
    800047aa:	451c                	lw	a5,8(a0)
    800047ac:	00f05f63          	blez	a5,800047ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800047b0:	0541                	addi	a0,a0,16
    800047b2:	00001097          	auipc	ra,0x1
    800047b6:	ca2080e7          	jalr	-862(ra) # 80005454 <acquiresleep>
  if(ip->valid == 0){
    800047ba:	40bc                	lw	a5,64(s1)
    800047bc:	cf99                	beqz	a5,800047da <ilock+0x40>
}
    800047be:	60e2                	ld	ra,24(sp)
    800047c0:	6442                	ld	s0,16(sp)
    800047c2:	64a2                	ld	s1,8(sp)
    800047c4:	6902                	ld	s2,0(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret
    panic("ilock");
    800047ca:	00005517          	auipc	a0,0x5
    800047ce:	01e50513          	addi	a0,a0,30 # 800097e8 <syscalls+0x1b0>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d72080e7          	jalr	-654(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800047da:	40dc                	lw	a5,4(s1)
    800047dc:	0047d79b          	srliw	a5,a5,0x4
    800047e0:	00240597          	auipc	a1,0x240
    800047e4:	e985a583          	lw	a1,-360(a1) # 80244678 <sb+0x18>
    800047e8:	9dbd                	addw	a1,a1,a5
    800047ea:	4088                	lw	a0,0(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	794080e7          	jalr	1940(ra) # 80003f80 <bread>
    800047f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800047f6:	05850593          	addi	a1,a0,88
    800047fa:	40dc                	lw	a5,4(s1)
    800047fc:	8bbd                	andi	a5,a5,15
    800047fe:	079a                	slli	a5,a5,0x6
    80004800:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004802:	00059783          	lh	a5,0(a1)
    80004806:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000480a:	00259783          	lh	a5,2(a1)
    8000480e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004812:	00459783          	lh	a5,4(a1)
    80004816:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000481a:	00659783          	lh	a5,6(a1)
    8000481e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004822:	459c                	lw	a5,8(a1)
    80004824:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004826:	03400613          	li	a2,52
    8000482a:	05b1                	addi	a1,a1,12
    8000482c:	05048513          	addi	a0,s1,80
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	742080e7          	jalr	1858(ra) # 80000f72 <memmove>
    brelse(bp);
    80004838:	854a                	mv	a0,s2
    8000483a:	00000097          	auipc	ra,0x0
    8000483e:	876080e7          	jalr	-1930(ra) # 800040b0 <brelse>
    ip->valid = 1;
    80004842:	4785                	li	a5,1
    80004844:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004846:	04449783          	lh	a5,68(s1)
    8000484a:	fbb5                	bnez	a5,800047be <ilock+0x24>
      panic("ilock: no type");
    8000484c:	00005517          	auipc	a0,0x5
    80004850:	fa450513          	addi	a0,a0,-92 # 800097f0 <syscalls+0x1b8>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cf0080e7          	jalr	-784(ra) # 80000544 <panic>

000000008000485c <iunlock>:
{
    8000485c:	1101                	addi	sp,sp,-32
    8000485e:	ec06                	sd	ra,24(sp)
    80004860:	e822                	sd	s0,16(sp)
    80004862:	e426                	sd	s1,8(sp)
    80004864:	e04a                	sd	s2,0(sp)
    80004866:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004868:	c905                	beqz	a0,80004898 <iunlock+0x3c>
    8000486a:	84aa                	mv	s1,a0
    8000486c:	01050913          	addi	s2,a0,16
    80004870:	854a                	mv	a0,s2
    80004872:	00001097          	auipc	ra,0x1
    80004876:	c7c080e7          	jalr	-900(ra) # 800054ee <holdingsleep>
    8000487a:	cd19                	beqz	a0,80004898 <iunlock+0x3c>
    8000487c:	449c                	lw	a5,8(s1)
    8000487e:	00f05d63          	blez	a5,80004898 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004882:	854a                	mv	a0,s2
    80004884:	00001097          	auipc	ra,0x1
    80004888:	c26080e7          	jalr	-986(ra) # 800054aa <releasesleep>
}
    8000488c:	60e2                	ld	ra,24(sp)
    8000488e:	6442                	ld	s0,16(sp)
    80004890:	64a2                	ld	s1,8(sp)
    80004892:	6902                	ld	s2,0(sp)
    80004894:	6105                	addi	sp,sp,32
    80004896:	8082                	ret
    panic("iunlock");
    80004898:	00005517          	auipc	a0,0x5
    8000489c:	f6850513          	addi	a0,a0,-152 # 80009800 <syscalls+0x1c8>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	ca4080e7          	jalr	-860(ra) # 80000544 <panic>

00000000800048a8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800048a8:	7179                	addi	sp,sp,-48
    800048aa:	f406                	sd	ra,40(sp)
    800048ac:	f022                	sd	s0,32(sp)
    800048ae:	ec26                	sd	s1,24(sp)
    800048b0:	e84a                	sd	s2,16(sp)
    800048b2:	e44e                	sd	s3,8(sp)
    800048b4:	e052                	sd	s4,0(sp)
    800048b6:	1800                	addi	s0,sp,48
    800048b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800048ba:	05050493          	addi	s1,a0,80
    800048be:	08050913          	addi	s2,a0,128
    800048c2:	a021                	j	800048ca <itrunc+0x22>
    800048c4:	0491                	addi	s1,s1,4
    800048c6:	01248d63          	beq	s1,s2,800048e0 <itrunc+0x38>
    if(ip->addrs[i]){
    800048ca:	408c                	lw	a1,0(s1)
    800048cc:	dde5                	beqz	a1,800048c4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800048ce:	0009a503          	lw	a0,0(s3)
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	8f4080e7          	jalr	-1804(ra) # 800041c6 <bfree>
      ip->addrs[i] = 0;
    800048da:	0004a023          	sw	zero,0(s1)
    800048de:	b7dd                	j	800048c4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800048e0:	0809a583          	lw	a1,128(s3)
    800048e4:	e185                	bnez	a1,80004904 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800048e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800048ea:	854e                	mv	a0,s3
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	de4080e7          	jalr	-540(ra) # 800046d0 <iupdate>
}
    800048f4:	70a2                	ld	ra,40(sp)
    800048f6:	7402                	ld	s0,32(sp)
    800048f8:	64e2                	ld	s1,24(sp)
    800048fa:	6942                	ld	s2,16(sp)
    800048fc:	69a2                	ld	s3,8(sp)
    800048fe:	6a02                	ld	s4,0(sp)
    80004900:	6145                	addi	sp,sp,48
    80004902:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004904:	0009a503          	lw	a0,0(s3)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	678080e7          	jalr	1656(ra) # 80003f80 <bread>
    80004910:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004912:	05850493          	addi	s1,a0,88
    80004916:	45850913          	addi	s2,a0,1112
    8000491a:	a811                	j	8000492e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000491c:	0009a503          	lw	a0,0(s3)
    80004920:	00000097          	auipc	ra,0x0
    80004924:	8a6080e7          	jalr	-1882(ra) # 800041c6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004928:	0491                	addi	s1,s1,4
    8000492a:	01248563          	beq	s1,s2,80004934 <itrunc+0x8c>
      if(a[j])
    8000492e:	408c                	lw	a1,0(s1)
    80004930:	dde5                	beqz	a1,80004928 <itrunc+0x80>
    80004932:	b7ed                	j	8000491c <itrunc+0x74>
    brelse(bp);
    80004934:	8552                	mv	a0,s4
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	77a080e7          	jalr	1914(ra) # 800040b0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000493e:	0809a583          	lw	a1,128(s3)
    80004942:	0009a503          	lw	a0,0(s3)
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	880080e7          	jalr	-1920(ra) # 800041c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000494e:	0809a023          	sw	zero,128(s3)
    80004952:	bf51                	j	800048e6 <itrunc+0x3e>

0000000080004954 <iput>:
{
    80004954:	1101                	addi	sp,sp,-32
    80004956:	ec06                	sd	ra,24(sp)
    80004958:	e822                	sd	s0,16(sp)
    8000495a:	e426                	sd	s1,8(sp)
    8000495c:	e04a                	sd	s2,0(sp)
    8000495e:	1000                	addi	s0,sp,32
    80004960:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004962:	00240517          	auipc	a0,0x240
    80004966:	d1e50513          	addi	a0,a0,-738 # 80244680 <itable>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	4ac080e7          	jalr	1196(ra) # 80000e16 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004972:	4498                	lw	a4,8(s1)
    80004974:	4785                	li	a5,1
    80004976:	02f70363          	beq	a4,a5,8000499c <iput+0x48>
  ip->ref--;
    8000497a:	449c                	lw	a5,8(s1)
    8000497c:	37fd                	addiw	a5,a5,-1
    8000497e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004980:	00240517          	auipc	a0,0x240
    80004984:	d0050513          	addi	a0,a0,-768 # 80244680 <itable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	542080e7          	jalr	1346(ra) # 80000eca <release>
}
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6902                	ld	s2,0(sp)
    80004998:	6105                	addi	sp,sp,32
    8000499a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000499c:	40bc                	lw	a5,64(s1)
    8000499e:	dff1                	beqz	a5,8000497a <iput+0x26>
    800049a0:	04a49783          	lh	a5,74(s1)
    800049a4:	fbf9                	bnez	a5,8000497a <iput+0x26>
    acquiresleep(&ip->lock);
    800049a6:	01048913          	addi	s2,s1,16
    800049aa:	854a                	mv	a0,s2
    800049ac:	00001097          	auipc	ra,0x1
    800049b0:	aa8080e7          	jalr	-1368(ra) # 80005454 <acquiresleep>
    release(&itable.lock);
    800049b4:	00240517          	auipc	a0,0x240
    800049b8:	ccc50513          	addi	a0,a0,-820 # 80244680 <itable>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	50e080e7          	jalr	1294(ra) # 80000eca <release>
    itrunc(ip);
    800049c4:	8526                	mv	a0,s1
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	ee2080e7          	jalr	-286(ra) # 800048a8 <itrunc>
    ip->type = 0;
    800049ce:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800049d2:	8526                	mv	a0,s1
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	cfc080e7          	jalr	-772(ra) # 800046d0 <iupdate>
    ip->valid = 0;
    800049dc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800049e0:	854a                	mv	a0,s2
    800049e2:	00001097          	auipc	ra,0x1
    800049e6:	ac8080e7          	jalr	-1336(ra) # 800054aa <releasesleep>
    acquire(&itable.lock);
    800049ea:	00240517          	auipc	a0,0x240
    800049ee:	c9650513          	addi	a0,a0,-874 # 80244680 <itable>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	424080e7          	jalr	1060(ra) # 80000e16 <acquire>
    800049fa:	b741                	j	8000497a <iput+0x26>

00000000800049fc <iunlockput>:
{
    800049fc:	1101                	addi	sp,sp,-32
    800049fe:	ec06                	sd	ra,24(sp)
    80004a00:	e822                	sd	s0,16(sp)
    80004a02:	e426                	sd	s1,8(sp)
    80004a04:	1000                	addi	s0,sp,32
    80004a06:	84aa                	mv	s1,a0
  iunlock(ip);
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	e54080e7          	jalr	-428(ra) # 8000485c <iunlock>
  iput(ip);
    80004a10:	8526                	mv	a0,s1
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	f42080e7          	jalr	-190(ra) # 80004954 <iput>
}
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6105                	addi	sp,sp,32
    80004a22:	8082                	ret

0000000080004a24 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004a24:	1141                	addi	sp,sp,-16
    80004a26:	e422                	sd	s0,8(sp)
    80004a28:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004a2a:	411c                	lw	a5,0(a0)
    80004a2c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004a2e:	415c                	lw	a5,4(a0)
    80004a30:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004a32:	04451783          	lh	a5,68(a0)
    80004a36:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004a3a:	04a51783          	lh	a5,74(a0)
    80004a3e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004a42:	04c56783          	lwu	a5,76(a0)
    80004a46:	e99c                	sd	a5,16(a1)
}
    80004a48:	6422                	ld	s0,8(sp)
    80004a4a:	0141                	addi	sp,sp,16
    80004a4c:	8082                	ret

0000000080004a4e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004a4e:	457c                	lw	a5,76(a0)
    80004a50:	0ed7e963          	bltu	a5,a3,80004b42 <readi+0xf4>
{
    80004a54:	7159                	addi	sp,sp,-112
    80004a56:	f486                	sd	ra,104(sp)
    80004a58:	f0a2                	sd	s0,96(sp)
    80004a5a:	eca6                	sd	s1,88(sp)
    80004a5c:	e8ca                	sd	s2,80(sp)
    80004a5e:	e4ce                	sd	s3,72(sp)
    80004a60:	e0d2                	sd	s4,64(sp)
    80004a62:	fc56                	sd	s5,56(sp)
    80004a64:	f85a                	sd	s6,48(sp)
    80004a66:	f45e                	sd	s7,40(sp)
    80004a68:	f062                	sd	s8,32(sp)
    80004a6a:	ec66                	sd	s9,24(sp)
    80004a6c:	e86a                	sd	s10,16(sp)
    80004a6e:	e46e                	sd	s11,8(sp)
    80004a70:	1880                	addi	s0,sp,112
    80004a72:	8b2a                	mv	s6,a0
    80004a74:	8bae                	mv	s7,a1
    80004a76:	8a32                	mv	s4,a2
    80004a78:	84b6                	mv	s1,a3
    80004a7a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004a7c:	9f35                	addw	a4,a4,a3
    return 0;
    80004a7e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004a80:	0ad76063          	bltu	a4,a3,80004b20 <readi+0xd2>
  if(off + n > ip->size)
    80004a84:	00e7f463          	bgeu	a5,a4,80004a8c <readi+0x3e>
    n = ip->size - off;
    80004a88:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004a8c:	0a0a8963          	beqz	s5,80004b3e <readi+0xf0>
    80004a90:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a92:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004a96:	5c7d                	li	s8,-1
    80004a98:	a82d                	j	80004ad2 <readi+0x84>
    80004a9a:	020d1d93          	slli	s11,s10,0x20
    80004a9e:	020ddd93          	srli	s11,s11,0x20
    80004aa2:	05890613          	addi	a2,s2,88
    80004aa6:	86ee                	mv	a3,s11
    80004aa8:	963a                	add	a2,a2,a4
    80004aaa:	85d2                	mv	a1,s4
    80004aac:	855e                	mv	a0,s7
    80004aae:	ffffe097          	auipc	ra,0xffffe
    80004ab2:	67a080e7          	jalr	1658(ra) # 80003128 <either_copyout>
    80004ab6:	05850d63          	beq	a0,s8,80004b10 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004aba:	854a                	mv	a0,s2
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	5f4080e7          	jalr	1524(ra) # 800040b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004ac4:	013d09bb          	addw	s3,s10,s3
    80004ac8:	009d04bb          	addw	s1,s10,s1
    80004acc:	9a6e                	add	s4,s4,s11
    80004ace:	0559f763          	bgeu	s3,s5,80004b1c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004ad2:	00a4d59b          	srliw	a1,s1,0xa
    80004ad6:	855a                	mv	a0,s6
    80004ad8:	00000097          	auipc	ra,0x0
    80004adc:	8a2080e7          	jalr	-1886(ra) # 8000437a <bmap>
    80004ae0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004ae4:	cd85                	beqz	a1,80004b1c <readi+0xce>
    bp = bread(ip->dev, addr);
    80004ae6:	000b2503          	lw	a0,0(s6)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	496080e7          	jalr	1174(ra) # 80003f80 <bread>
    80004af2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004af4:	3ff4f713          	andi	a4,s1,1023
    80004af8:	40ec87bb          	subw	a5,s9,a4
    80004afc:	413a86bb          	subw	a3,s5,s3
    80004b00:	8d3e                	mv	s10,a5
    80004b02:	2781                	sext.w	a5,a5
    80004b04:	0006861b          	sext.w	a2,a3
    80004b08:	f8f679e3          	bgeu	a2,a5,80004a9a <readi+0x4c>
    80004b0c:	8d36                	mv	s10,a3
    80004b0e:	b771                	j	80004a9a <readi+0x4c>
      brelse(bp);
    80004b10:	854a                	mv	a0,s2
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	59e080e7          	jalr	1438(ra) # 800040b0 <brelse>
      tot = -1;
    80004b1a:	59fd                	li	s3,-1
  }
  return tot;
    80004b1c:	0009851b          	sext.w	a0,s3
}
    80004b20:	70a6                	ld	ra,104(sp)
    80004b22:	7406                	ld	s0,96(sp)
    80004b24:	64e6                	ld	s1,88(sp)
    80004b26:	6946                	ld	s2,80(sp)
    80004b28:	69a6                	ld	s3,72(sp)
    80004b2a:	6a06                	ld	s4,64(sp)
    80004b2c:	7ae2                	ld	s5,56(sp)
    80004b2e:	7b42                	ld	s6,48(sp)
    80004b30:	7ba2                	ld	s7,40(sp)
    80004b32:	7c02                	ld	s8,32(sp)
    80004b34:	6ce2                	ld	s9,24(sp)
    80004b36:	6d42                	ld	s10,16(sp)
    80004b38:	6da2                	ld	s11,8(sp)
    80004b3a:	6165                	addi	sp,sp,112
    80004b3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004b3e:	89d6                	mv	s3,s5
    80004b40:	bff1                	j	80004b1c <readi+0xce>
    return 0;
    80004b42:	4501                	li	a0,0
}
    80004b44:	8082                	ret

0000000080004b46 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004b46:	457c                	lw	a5,76(a0)
    80004b48:	10d7e863          	bltu	a5,a3,80004c58 <writei+0x112>
{
    80004b4c:	7159                	addi	sp,sp,-112
    80004b4e:	f486                	sd	ra,104(sp)
    80004b50:	f0a2                	sd	s0,96(sp)
    80004b52:	eca6                	sd	s1,88(sp)
    80004b54:	e8ca                	sd	s2,80(sp)
    80004b56:	e4ce                	sd	s3,72(sp)
    80004b58:	e0d2                	sd	s4,64(sp)
    80004b5a:	fc56                	sd	s5,56(sp)
    80004b5c:	f85a                	sd	s6,48(sp)
    80004b5e:	f45e                	sd	s7,40(sp)
    80004b60:	f062                	sd	s8,32(sp)
    80004b62:	ec66                	sd	s9,24(sp)
    80004b64:	e86a                	sd	s10,16(sp)
    80004b66:	e46e                	sd	s11,8(sp)
    80004b68:	1880                	addi	s0,sp,112
    80004b6a:	8aaa                	mv	s5,a0
    80004b6c:	8bae                	mv	s7,a1
    80004b6e:	8a32                	mv	s4,a2
    80004b70:	8936                	mv	s2,a3
    80004b72:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004b74:	00e687bb          	addw	a5,a3,a4
    80004b78:	0ed7e263          	bltu	a5,a3,80004c5c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004b7c:	00043737          	lui	a4,0x43
    80004b80:	0ef76063          	bltu	a4,a5,80004c60 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004b84:	0c0b0863          	beqz	s6,80004c54 <writei+0x10e>
    80004b88:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004b8a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004b8e:	5c7d                	li	s8,-1
    80004b90:	a091                	j	80004bd4 <writei+0x8e>
    80004b92:	020d1d93          	slli	s11,s10,0x20
    80004b96:	020ddd93          	srli	s11,s11,0x20
    80004b9a:	05848513          	addi	a0,s1,88
    80004b9e:	86ee                	mv	a3,s11
    80004ba0:	8652                	mv	a2,s4
    80004ba2:	85de                	mv	a1,s7
    80004ba4:	953a                	add	a0,a0,a4
    80004ba6:	ffffe097          	auipc	ra,0xffffe
    80004baa:	5d8080e7          	jalr	1496(ra) # 8000317e <either_copyin>
    80004bae:	07850263          	beq	a0,s8,80004c12 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	00000097          	auipc	ra,0x0
    80004bb8:	780080e7          	jalr	1920(ra) # 80005334 <log_write>
    brelse(bp);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	4f2080e7          	jalr	1266(ra) # 800040b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004bc6:	013d09bb          	addw	s3,s10,s3
    80004bca:	012d093b          	addw	s2,s10,s2
    80004bce:	9a6e                	add	s4,s4,s11
    80004bd0:	0569f663          	bgeu	s3,s6,80004c1c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004bd4:	00a9559b          	srliw	a1,s2,0xa
    80004bd8:	8556                	mv	a0,s5
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	7a0080e7          	jalr	1952(ra) # 8000437a <bmap>
    80004be2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004be6:	c99d                	beqz	a1,80004c1c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004be8:	000aa503          	lw	a0,0(s5)
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	394080e7          	jalr	916(ra) # 80003f80 <bread>
    80004bf4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004bf6:	3ff97713          	andi	a4,s2,1023
    80004bfa:	40ec87bb          	subw	a5,s9,a4
    80004bfe:	413b06bb          	subw	a3,s6,s3
    80004c02:	8d3e                	mv	s10,a5
    80004c04:	2781                	sext.w	a5,a5
    80004c06:	0006861b          	sext.w	a2,a3
    80004c0a:	f8f674e3          	bgeu	a2,a5,80004b92 <writei+0x4c>
    80004c0e:	8d36                	mv	s10,a3
    80004c10:	b749                	j	80004b92 <writei+0x4c>
      brelse(bp);
    80004c12:	8526                	mv	a0,s1
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	49c080e7          	jalr	1180(ra) # 800040b0 <brelse>
  }

  if(off > ip->size)
    80004c1c:	04caa783          	lw	a5,76(s5)
    80004c20:	0127f463          	bgeu	a5,s2,80004c28 <writei+0xe2>
    ip->size = off;
    80004c24:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004c28:	8556                	mv	a0,s5
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	aa6080e7          	jalr	-1370(ra) # 800046d0 <iupdate>

  return tot;
    80004c32:	0009851b          	sext.w	a0,s3
}
    80004c36:	70a6                	ld	ra,104(sp)
    80004c38:	7406                	ld	s0,96(sp)
    80004c3a:	64e6                	ld	s1,88(sp)
    80004c3c:	6946                	ld	s2,80(sp)
    80004c3e:	69a6                	ld	s3,72(sp)
    80004c40:	6a06                	ld	s4,64(sp)
    80004c42:	7ae2                	ld	s5,56(sp)
    80004c44:	7b42                	ld	s6,48(sp)
    80004c46:	7ba2                	ld	s7,40(sp)
    80004c48:	7c02                	ld	s8,32(sp)
    80004c4a:	6ce2                	ld	s9,24(sp)
    80004c4c:	6d42                	ld	s10,16(sp)
    80004c4e:	6da2                	ld	s11,8(sp)
    80004c50:	6165                	addi	sp,sp,112
    80004c52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004c54:	89da                	mv	s3,s6
    80004c56:	bfc9                	j	80004c28 <writei+0xe2>
    return -1;
    80004c58:	557d                	li	a0,-1
}
    80004c5a:	8082                	ret
    return -1;
    80004c5c:	557d                	li	a0,-1
    80004c5e:	bfe1                	j	80004c36 <writei+0xf0>
    return -1;
    80004c60:	557d                	li	a0,-1
    80004c62:	bfd1                	j	80004c36 <writei+0xf0>

0000000080004c64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004c64:	1141                	addi	sp,sp,-16
    80004c66:	e406                	sd	ra,8(sp)
    80004c68:	e022                	sd	s0,0(sp)
    80004c6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004c6c:	4639                	li	a2,14
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	37c080e7          	jalr	892(ra) # 80000fea <strncmp>
}
    80004c76:	60a2                	ld	ra,8(sp)
    80004c78:	6402                	ld	s0,0(sp)
    80004c7a:	0141                	addi	sp,sp,16
    80004c7c:	8082                	ret

0000000080004c7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004c7e:	7139                	addi	sp,sp,-64
    80004c80:	fc06                	sd	ra,56(sp)
    80004c82:	f822                	sd	s0,48(sp)
    80004c84:	f426                	sd	s1,40(sp)
    80004c86:	f04a                	sd	s2,32(sp)
    80004c88:	ec4e                	sd	s3,24(sp)
    80004c8a:	e852                	sd	s4,16(sp)
    80004c8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004c8e:	04451703          	lh	a4,68(a0)
    80004c92:	4785                	li	a5,1
    80004c94:	00f71a63          	bne	a4,a5,80004ca8 <dirlookup+0x2a>
    80004c98:	892a                	mv	s2,a0
    80004c9a:	89ae                	mv	s3,a1
    80004c9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c9e:	457c                	lw	a5,76(a0)
    80004ca0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004ca2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ca4:	e79d                	bnez	a5,80004cd2 <dirlookup+0x54>
    80004ca6:	a8a5                	j	80004d1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004ca8:	00005517          	auipc	a0,0x5
    80004cac:	b6050513          	addi	a0,a0,-1184 # 80009808 <syscalls+0x1d0>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	894080e7          	jalr	-1900(ra) # 80000544 <panic>
      panic("dirlookup read");
    80004cb8:	00005517          	auipc	a0,0x5
    80004cbc:	b6850513          	addi	a0,a0,-1176 # 80009820 <syscalls+0x1e8>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	884080e7          	jalr	-1916(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004cc8:	24c1                	addiw	s1,s1,16
    80004cca:	04c92783          	lw	a5,76(s2)
    80004cce:	04f4f763          	bgeu	s1,a5,80004d1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004cd2:	4741                	li	a4,16
    80004cd4:	86a6                	mv	a3,s1
    80004cd6:	fc040613          	addi	a2,s0,-64
    80004cda:	4581                	li	a1,0
    80004cdc:	854a                	mv	a0,s2
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	d70080e7          	jalr	-656(ra) # 80004a4e <readi>
    80004ce6:	47c1                	li	a5,16
    80004ce8:	fcf518e3          	bne	a0,a5,80004cb8 <dirlookup+0x3a>
    if(de.inum == 0)
    80004cec:	fc045783          	lhu	a5,-64(s0)
    80004cf0:	dfe1                	beqz	a5,80004cc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004cf2:	fc240593          	addi	a1,s0,-62
    80004cf6:	854e                	mv	a0,s3
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	f6c080e7          	jalr	-148(ra) # 80004c64 <namecmp>
    80004d00:	f561                	bnez	a0,80004cc8 <dirlookup+0x4a>
      if(poff)
    80004d02:	000a0463          	beqz	s4,80004d0a <dirlookup+0x8c>
        *poff = off;
    80004d06:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004d0a:	fc045583          	lhu	a1,-64(s0)
    80004d0e:	00092503          	lw	a0,0(s2)
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	750080e7          	jalr	1872(ra) # 80004462 <iget>
    80004d1a:	a011                	j	80004d1e <dirlookup+0xa0>
  return 0;
    80004d1c:	4501                	li	a0,0
}
    80004d1e:	70e2                	ld	ra,56(sp)
    80004d20:	7442                	ld	s0,48(sp)
    80004d22:	74a2                	ld	s1,40(sp)
    80004d24:	7902                	ld	s2,32(sp)
    80004d26:	69e2                	ld	s3,24(sp)
    80004d28:	6a42                	ld	s4,16(sp)
    80004d2a:	6121                	addi	sp,sp,64
    80004d2c:	8082                	ret

0000000080004d2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004d2e:	711d                	addi	sp,sp,-96
    80004d30:	ec86                	sd	ra,88(sp)
    80004d32:	e8a2                	sd	s0,80(sp)
    80004d34:	e4a6                	sd	s1,72(sp)
    80004d36:	e0ca                	sd	s2,64(sp)
    80004d38:	fc4e                	sd	s3,56(sp)
    80004d3a:	f852                	sd	s4,48(sp)
    80004d3c:	f456                	sd	s5,40(sp)
    80004d3e:	f05a                	sd	s6,32(sp)
    80004d40:	ec5e                	sd	s7,24(sp)
    80004d42:	e862                	sd	s8,16(sp)
    80004d44:	e466                	sd	s9,8(sp)
    80004d46:	1080                	addi	s0,sp,96
    80004d48:	84aa                	mv	s1,a0
    80004d4a:	8b2e                	mv	s6,a1
    80004d4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004d4e:	00054703          	lbu	a4,0(a0)
    80004d52:	02f00793          	li	a5,47
    80004d56:	02f70363          	beq	a4,a5,80004d7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	0a8080e7          	jalr	168(ra) # 80001e02 <myproc>
    80004d62:	15053503          	ld	a0,336(a0)
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	9f6080e7          	jalr	-1546(ra) # 8000475c <idup>
    80004d6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004d70:	02f00913          	li	s2,47
  len = path - s;
    80004d74:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004d76:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004d78:	4c05                	li	s8,1
    80004d7a:	a865                	j	80004e32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004d7c:	4585                	li	a1,1
    80004d7e:	4505                	li	a0,1
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	6e2080e7          	jalr	1762(ra) # 80004462 <iget>
    80004d88:	89aa                	mv	s3,a0
    80004d8a:	b7dd                	j	80004d70 <namex+0x42>
      iunlockput(ip);
    80004d8c:	854e                	mv	a0,s3
    80004d8e:	00000097          	auipc	ra,0x0
    80004d92:	c6e080e7          	jalr	-914(ra) # 800049fc <iunlockput>
      return 0;
    80004d96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004d98:	854e                	mv	a0,s3
    80004d9a:	60e6                	ld	ra,88(sp)
    80004d9c:	6446                	ld	s0,80(sp)
    80004d9e:	64a6                	ld	s1,72(sp)
    80004da0:	6906                	ld	s2,64(sp)
    80004da2:	79e2                	ld	s3,56(sp)
    80004da4:	7a42                	ld	s4,48(sp)
    80004da6:	7aa2                	ld	s5,40(sp)
    80004da8:	7b02                	ld	s6,32(sp)
    80004daa:	6be2                	ld	s7,24(sp)
    80004dac:	6c42                	ld	s8,16(sp)
    80004dae:	6ca2                	ld	s9,8(sp)
    80004db0:	6125                	addi	sp,sp,96
    80004db2:	8082                	ret
      iunlock(ip);
    80004db4:	854e                	mv	a0,s3
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	aa6080e7          	jalr	-1370(ra) # 8000485c <iunlock>
      return ip;
    80004dbe:	bfe9                	j	80004d98 <namex+0x6a>
      iunlockput(ip);
    80004dc0:	854e                	mv	a0,s3
    80004dc2:	00000097          	auipc	ra,0x0
    80004dc6:	c3a080e7          	jalr	-966(ra) # 800049fc <iunlockput>
      return 0;
    80004dca:	89d2                	mv	s3,s4
    80004dcc:	b7f1                	j	80004d98 <namex+0x6a>
  len = path - s;
    80004dce:	40b48633          	sub	a2,s1,a1
    80004dd2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004dd6:	094cd463          	bge	s9,s4,80004e5e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004dda:	4639                	li	a2,14
    80004ddc:	8556                	mv	a0,s5
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	194080e7          	jalr	404(ra) # 80000f72 <memmove>
  while(*path == '/')
    80004de6:	0004c783          	lbu	a5,0(s1)
    80004dea:	01279763          	bne	a5,s2,80004df8 <namex+0xca>
    path++;
    80004dee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004df0:	0004c783          	lbu	a5,0(s1)
    80004df4:	ff278de3          	beq	a5,s2,80004dee <namex+0xc0>
    ilock(ip);
    80004df8:	854e                	mv	a0,s3
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	9a0080e7          	jalr	-1632(ra) # 8000479a <ilock>
    if(ip->type != T_DIR){
    80004e02:	04499783          	lh	a5,68(s3)
    80004e06:	f98793e3          	bne	a5,s8,80004d8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004e0a:	000b0563          	beqz	s6,80004e14 <namex+0xe6>
    80004e0e:	0004c783          	lbu	a5,0(s1)
    80004e12:	d3cd                	beqz	a5,80004db4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004e14:	865e                	mv	a2,s7
    80004e16:	85d6                	mv	a1,s5
    80004e18:	854e                	mv	a0,s3
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	e64080e7          	jalr	-412(ra) # 80004c7e <dirlookup>
    80004e22:	8a2a                	mv	s4,a0
    80004e24:	dd51                	beqz	a0,80004dc0 <namex+0x92>
    iunlockput(ip);
    80004e26:	854e                	mv	a0,s3
    80004e28:	00000097          	auipc	ra,0x0
    80004e2c:	bd4080e7          	jalr	-1068(ra) # 800049fc <iunlockput>
    ip = next;
    80004e30:	89d2                	mv	s3,s4
  while(*path == '/')
    80004e32:	0004c783          	lbu	a5,0(s1)
    80004e36:	05279763          	bne	a5,s2,80004e84 <namex+0x156>
    path++;
    80004e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004e3c:	0004c783          	lbu	a5,0(s1)
    80004e40:	ff278de3          	beq	a5,s2,80004e3a <namex+0x10c>
  if(*path == 0)
    80004e44:	c79d                	beqz	a5,80004e72 <namex+0x144>
    path++;
    80004e46:	85a6                	mv	a1,s1
  len = path - s;
    80004e48:	8a5e                	mv	s4,s7
    80004e4a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004e4c:	01278963          	beq	a5,s2,80004e5e <namex+0x130>
    80004e50:	dfbd                	beqz	a5,80004dce <namex+0xa0>
    path++;
    80004e52:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004e54:	0004c783          	lbu	a5,0(s1)
    80004e58:	ff279ce3          	bne	a5,s2,80004e50 <namex+0x122>
    80004e5c:	bf8d                	j	80004dce <namex+0xa0>
    memmove(name, s, len);
    80004e5e:	2601                	sext.w	a2,a2
    80004e60:	8556                	mv	a0,s5
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	110080e7          	jalr	272(ra) # 80000f72 <memmove>
    name[len] = 0;
    80004e6a:	9a56                	add	s4,s4,s5
    80004e6c:	000a0023          	sb	zero,0(s4)
    80004e70:	bf9d                	j	80004de6 <namex+0xb8>
  if(nameiparent){
    80004e72:	f20b03e3          	beqz	s6,80004d98 <namex+0x6a>
    iput(ip);
    80004e76:	854e                	mv	a0,s3
    80004e78:	00000097          	auipc	ra,0x0
    80004e7c:	adc080e7          	jalr	-1316(ra) # 80004954 <iput>
    return 0;
    80004e80:	4981                	li	s3,0
    80004e82:	bf19                	j	80004d98 <namex+0x6a>
  if(*path == 0)
    80004e84:	d7fd                	beqz	a5,80004e72 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004e86:	0004c783          	lbu	a5,0(s1)
    80004e8a:	85a6                	mv	a1,s1
    80004e8c:	b7d1                	j	80004e50 <namex+0x122>

0000000080004e8e <dirlink>:
{
    80004e8e:	7139                	addi	sp,sp,-64
    80004e90:	fc06                	sd	ra,56(sp)
    80004e92:	f822                	sd	s0,48(sp)
    80004e94:	f426                	sd	s1,40(sp)
    80004e96:	f04a                	sd	s2,32(sp)
    80004e98:	ec4e                	sd	s3,24(sp)
    80004e9a:	e852                	sd	s4,16(sp)
    80004e9c:	0080                	addi	s0,sp,64
    80004e9e:	892a                	mv	s2,a0
    80004ea0:	8a2e                	mv	s4,a1
    80004ea2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ea4:	4601                	li	a2,0
    80004ea6:	00000097          	auipc	ra,0x0
    80004eaa:	dd8080e7          	jalr	-552(ra) # 80004c7e <dirlookup>
    80004eae:	e93d                	bnez	a0,80004f24 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004eb0:	04c92483          	lw	s1,76(s2)
    80004eb4:	c49d                	beqz	s1,80004ee2 <dirlink+0x54>
    80004eb6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004eb8:	4741                	li	a4,16
    80004eba:	86a6                	mv	a3,s1
    80004ebc:	fc040613          	addi	a2,s0,-64
    80004ec0:	4581                	li	a1,0
    80004ec2:	854a                	mv	a0,s2
    80004ec4:	00000097          	auipc	ra,0x0
    80004ec8:	b8a080e7          	jalr	-1142(ra) # 80004a4e <readi>
    80004ecc:	47c1                	li	a5,16
    80004ece:	06f51163          	bne	a0,a5,80004f30 <dirlink+0xa2>
    if(de.inum == 0)
    80004ed2:	fc045783          	lhu	a5,-64(s0)
    80004ed6:	c791                	beqz	a5,80004ee2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ed8:	24c1                	addiw	s1,s1,16
    80004eda:	04c92783          	lw	a5,76(s2)
    80004ede:	fcf4ede3          	bltu	s1,a5,80004eb8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004ee2:	4639                	li	a2,14
    80004ee4:	85d2                	mv	a1,s4
    80004ee6:	fc240513          	addi	a0,s0,-62
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	13c080e7          	jalr	316(ra) # 80001026 <strncpy>
  de.inum = inum;
    80004ef2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ef6:	4741                	li	a4,16
    80004ef8:	86a6                	mv	a3,s1
    80004efa:	fc040613          	addi	a2,s0,-64
    80004efe:	4581                	li	a1,0
    80004f00:	854a                	mv	a0,s2
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	c44080e7          	jalr	-956(ra) # 80004b46 <writei>
    80004f0a:	1541                	addi	a0,a0,-16
    80004f0c:	00a03533          	snez	a0,a0
    80004f10:	40a00533          	neg	a0,a0
}
    80004f14:	70e2                	ld	ra,56(sp)
    80004f16:	7442                	ld	s0,48(sp)
    80004f18:	74a2                	ld	s1,40(sp)
    80004f1a:	7902                	ld	s2,32(sp)
    80004f1c:	69e2                	ld	s3,24(sp)
    80004f1e:	6a42                	ld	s4,16(sp)
    80004f20:	6121                	addi	sp,sp,64
    80004f22:	8082                	ret
    iput(ip);
    80004f24:	00000097          	auipc	ra,0x0
    80004f28:	a30080e7          	jalr	-1488(ra) # 80004954 <iput>
    return -1;
    80004f2c:	557d                	li	a0,-1
    80004f2e:	b7dd                	j	80004f14 <dirlink+0x86>
      panic("dirlink read");
    80004f30:	00005517          	auipc	a0,0x5
    80004f34:	90050513          	addi	a0,a0,-1792 # 80009830 <syscalls+0x1f8>
    80004f38:	ffffb097          	auipc	ra,0xffffb
    80004f3c:	60c080e7          	jalr	1548(ra) # 80000544 <panic>

0000000080004f40 <namei>:

struct inode*
namei(char *path)
{
    80004f40:	1101                	addi	sp,sp,-32
    80004f42:	ec06                	sd	ra,24(sp)
    80004f44:	e822                	sd	s0,16(sp)
    80004f46:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004f48:	fe040613          	addi	a2,s0,-32
    80004f4c:	4581                	li	a1,0
    80004f4e:	00000097          	auipc	ra,0x0
    80004f52:	de0080e7          	jalr	-544(ra) # 80004d2e <namex>
}
    80004f56:	60e2                	ld	ra,24(sp)
    80004f58:	6442                	ld	s0,16(sp)
    80004f5a:	6105                	addi	sp,sp,32
    80004f5c:	8082                	ret

0000000080004f5e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004f5e:	1141                	addi	sp,sp,-16
    80004f60:	e406                	sd	ra,8(sp)
    80004f62:	e022                	sd	s0,0(sp)
    80004f64:	0800                	addi	s0,sp,16
    80004f66:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004f68:	4585                	li	a1,1
    80004f6a:	00000097          	auipc	ra,0x0
    80004f6e:	dc4080e7          	jalr	-572(ra) # 80004d2e <namex>
}
    80004f72:	60a2                	ld	ra,8(sp)
    80004f74:	6402                	ld	s0,0(sp)
    80004f76:	0141                	addi	sp,sp,16
    80004f78:	8082                	ret

0000000080004f7a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004f7a:	1101                	addi	sp,sp,-32
    80004f7c:	ec06                	sd	ra,24(sp)
    80004f7e:	e822                	sd	s0,16(sp)
    80004f80:	e426                	sd	s1,8(sp)
    80004f82:	e04a                	sd	s2,0(sp)
    80004f84:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004f86:	00241917          	auipc	s2,0x241
    80004f8a:	1a290913          	addi	s2,s2,418 # 80246128 <log>
    80004f8e:	01892583          	lw	a1,24(s2)
    80004f92:	02892503          	lw	a0,40(s2)
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	fea080e7          	jalr	-22(ra) # 80003f80 <bread>
    80004f9e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004fa0:	02c92683          	lw	a3,44(s2)
    80004fa4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004fa6:	02d05763          	blez	a3,80004fd4 <write_head+0x5a>
    80004faa:	00241797          	auipc	a5,0x241
    80004fae:	1ae78793          	addi	a5,a5,430 # 80246158 <log+0x30>
    80004fb2:	05c50713          	addi	a4,a0,92
    80004fb6:	36fd                	addiw	a3,a3,-1
    80004fb8:	1682                	slli	a3,a3,0x20
    80004fba:	9281                	srli	a3,a3,0x20
    80004fbc:	068a                	slli	a3,a3,0x2
    80004fbe:	00241617          	auipc	a2,0x241
    80004fc2:	19e60613          	addi	a2,a2,414 # 8024615c <log+0x34>
    80004fc6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004fc8:	4390                	lw	a2,0(a5)
    80004fca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004fcc:	0791                	addi	a5,a5,4
    80004fce:	0711                	addi	a4,a4,4
    80004fd0:	fed79ce3          	bne	a5,a3,80004fc8 <write_head+0x4e>
  }
  bwrite(buf);
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	09c080e7          	jalr	156(ra) # 80004072 <bwrite>
  brelse(buf);
    80004fde:	8526                	mv	a0,s1
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	0d0080e7          	jalr	208(ra) # 800040b0 <brelse>
}
    80004fe8:	60e2                	ld	ra,24(sp)
    80004fea:	6442                	ld	s0,16(sp)
    80004fec:	64a2                	ld	s1,8(sp)
    80004fee:	6902                	ld	s2,0(sp)
    80004ff0:	6105                	addi	sp,sp,32
    80004ff2:	8082                	ret

0000000080004ff4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ff4:	00241797          	auipc	a5,0x241
    80004ff8:	1607a783          	lw	a5,352(a5) # 80246154 <log+0x2c>
    80004ffc:	0af05d63          	blez	a5,800050b6 <install_trans+0xc2>
{
    80005000:	7139                	addi	sp,sp,-64
    80005002:	fc06                	sd	ra,56(sp)
    80005004:	f822                	sd	s0,48(sp)
    80005006:	f426                	sd	s1,40(sp)
    80005008:	f04a                	sd	s2,32(sp)
    8000500a:	ec4e                	sd	s3,24(sp)
    8000500c:	e852                	sd	s4,16(sp)
    8000500e:	e456                	sd	s5,8(sp)
    80005010:	e05a                	sd	s6,0(sp)
    80005012:	0080                	addi	s0,sp,64
    80005014:	8b2a                	mv	s6,a0
    80005016:	00241a97          	auipc	s5,0x241
    8000501a:	142a8a93          	addi	s5,s5,322 # 80246158 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000501e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005020:	00241997          	auipc	s3,0x241
    80005024:	10898993          	addi	s3,s3,264 # 80246128 <log>
    80005028:	a035                	j	80005054 <install_trans+0x60>
      bunpin(dbuf);
    8000502a:	8526                	mv	a0,s1
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	15e080e7          	jalr	350(ra) # 8000418a <bunpin>
    brelse(lbuf);
    80005034:	854a                	mv	a0,s2
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	07a080e7          	jalr	122(ra) # 800040b0 <brelse>
    brelse(dbuf);
    8000503e:	8526                	mv	a0,s1
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	070080e7          	jalr	112(ra) # 800040b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005048:	2a05                	addiw	s4,s4,1
    8000504a:	0a91                	addi	s5,s5,4
    8000504c:	02c9a783          	lw	a5,44(s3)
    80005050:	04fa5963          	bge	s4,a5,800050a2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005054:	0189a583          	lw	a1,24(s3)
    80005058:	014585bb          	addw	a1,a1,s4
    8000505c:	2585                	addiw	a1,a1,1
    8000505e:	0289a503          	lw	a0,40(s3)
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	f1e080e7          	jalr	-226(ra) # 80003f80 <bread>
    8000506a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000506c:	000aa583          	lw	a1,0(s5)
    80005070:	0289a503          	lw	a0,40(s3)
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	f0c080e7          	jalr	-244(ra) # 80003f80 <bread>
    8000507c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000507e:	40000613          	li	a2,1024
    80005082:	05890593          	addi	a1,s2,88
    80005086:	05850513          	addi	a0,a0,88
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	ee8080e7          	jalr	-280(ra) # 80000f72 <memmove>
    bwrite(dbuf);  // write dst to disk
    80005092:	8526                	mv	a0,s1
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	fde080e7          	jalr	-34(ra) # 80004072 <bwrite>
    if(recovering == 0)
    8000509c:	f80b1ce3          	bnez	s6,80005034 <install_trans+0x40>
    800050a0:	b769                	j	8000502a <install_trans+0x36>
}
    800050a2:	70e2                	ld	ra,56(sp)
    800050a4:	7442                	ld	s0,48(sp)
    800050a6:	74a2                	ld	s1,40(sp)
    800050a8:	7902                	ld	s2,32(sp)
    800050aa:	69e2                	ld	s3,24(sp)
    800050ac:	6a42                	ld	s4,16(sp)
    800050ae:	6aa2                	ld	s5,8(sp)
    800050b0:	6b02                	ld	s6,0(sp)
    800050b2:	6121                	addi	sp,sp,64
    800050b4:	8082                	ret
    800050b6:	8082                	ret

00000000800050b8 <initlog>:
{
    800050b8:	7179                	addi	sp,sp,-48
    800050ba:	f406                	sd	ra,40(sp)
    800050bc:	f022                	sd	s0,32(sp)
    800050be:	ec26                	sd	s1,24(sp)
    800050c0:	e84a                	sd	s2,16(sp)
    800050c2:	e44e                	sd	s3,8(sp)
    800050c4:	1800                	addi	s0,sp,48
    800050c6:	892a                	mv	s2,a0
    800050c8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800050ca:	00241497          	auipc	s1,0x241
    800050ce:	05e48493          	addi	s1,s1,94 # 80246128 <log>
    800050d2:	00004597          	auipc	a1,0x4
    800050d6:	76e58593          	addi	a1,a1,1902 # 80009840 <syscalls+0x208>
    800050da:	8526                	mv	a0,s1
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	caa080e7          	jalr	-854(ra) # 80000d86 <initlock>
  log.start = sb->logstart;
    800050e4:	0149a583          	lw	a1,20(s3)
    800050e8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800050ea:	0109a783          	lw	a5,16(s3)
    800050ee:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800050f0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800050f4:	854a                	mv	a0,s2
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	e8a080e7          	jalr	-374(ra) # 80003f80 <bread>
  log.lh.n = lh->n;
    800050fe:	4d3c                	lw	a5,88(a0)
    80005100:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005102:	02f05563          	blez	a5,8000512c <initlog+0x74>
    80005106:	05c50713          	addi	a4,a0,92
    8000510a:	00241697          	auipc	a3,0x241
    8000510e:	04e68693          	addi	a3,a3,78 # 80246158 <log+0x30>
    80005112:	37fd                	addiw	a5,a5,-1
    80005114:	1782                	slli	a5,a5,0x20
    80005116:	9381                	srli	a5,a5,0x20
    80005118:	078a                	slli	a5,a5,0x2
    8000511a:	06050613          	addi	a2,a0,96
    8000511e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80005120:	4310                	lw	a2,0(a4)
    80005122:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80005124:	0711                	addi	a4,a4,4
    80005126:	0691                	addi	a3,a3,4
    80005128:	fef71ce3          	bne	a4,a5,80005120 <initlog+0x68>
  brelse(buf);
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	f84080e7          	jalr	-124(ra) # 800040b0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005134:	4505                	li	a0,1
    80005136:	00000097          	auipc	ra,0x0
    8000513a:	ebe080e7          	jalr	-322(ra) # 80004ff4 <install_trans>
  log.lh.n = 0;
    8000513e:	00241797          	auipc	a5,0x241
    80005142:	0007ab23          	sw	zero,22(a5) # 80246154 <log+0x2c>
  write_head(); // clear the log
    80005146:	00000097          	auipc	ra,0x0
    8000514a:	e34080e7          	jalr	-460(ra) # 80004f7a <write_head>
}
    8000514e:	70a2                	ld	ra,40(sp)
    80005150:	7402                	ld	s0,32(sp)
    80005152:	64e2                	ld	s1,24(sp)
    80005154:	6942                	ld	s2,16(sp)
    80005156:	69a2                	ld	s3,8(sp)
    80005158:	6145                	addi	sp,sp,48
    8000515a:	8082                	ret

000000008000515c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000515c:	1101                	addi	sp,sp,-32
    8000515e:	ec06                	sd	ra,24(sp)
    80005160:	e822                	sd	s0,16(sp)
    80005162:	e426                	sd	s1,8(sp)
    80005164:	e04a                	sd	s2,0(sp)
    80005166:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80005168:	00241517          	auipc	a0,0x241
    8000516c:	fc050513          	addi	a0,a0,-64 # 80246128 <log>
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	ca6080e7          	jalr	-858(ra) # 80000e16 <acquire>
  while(1){
    if(log.committing){
    80005178:	00241497          	auipc	s1,0x241
    8000517c:	fb048493          	addi	s1,s1,-80 # 80246128 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005180:	4979                	li	s2,30
    80005182:	a039                	j	80005190 <begin_op+0x34>
      sleep(&log, &log.lock);
    80005184:	85a6                	mv	a1,s1
    80005186:	8526                	mv	a0,s1
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	9bc080e7          	jalr	-1604(ra) # 80002b44 <sleep>
    if(log.committing){
    80005190:	50dc                	lw	a5,36(s1)
    80005192:	fbed                	bnez	a5,80005184 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005194:	509c                	lw	a5,32(s1)
    80005196:	0017871b          	addiw	a4,a5,1
    8000519a:	0007069b          	sext.w	a3,a4
    8000519e:	0027179b          	slliw	a5,a4,0x2
    800051a2:	9fb9                	addw	a5,a5,a4
    800051a4:	0017979b          	slliw	a5,a5,0x1
    800051a8:	54d8                	lw	a4,44(s1)
    800051aa:	9fb9                	addw	a5,a5,a4
    800051ac:	00f95963          	bge	s2,a5,800051be <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800051b0:	85a6                	mv	a1,s1
    800051b2:	8526                	mv	a0,s1
    800051b4:	ffffe097          	auipc	ra,0xffffe
    800051b8:	990080e7          	jalr	-1648(ra) # 80002b44 <sleep>
    800051bc:	bfd1                	j	80005190 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800051be:	00241517          	auipc	a0,0x241
    800051c2:	f6a50513          	addi	a0,a0,-150 # 80246128 <log>
    800051c6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	d02080e7          	jalr	-766(ra) # 80000eca <release>
      break;
    }
  }
}
    800051d0:	60e2                	ld	ra,24(sp)
    800051d2:	6442                	ld	s0,16(sp)
    800051d4:	64a2                	ld	s1,8(sp)
    800051d6:	6902                	ld	s2,0(sp)
    800051d8:	6105                	addi	sp,sp,32
    800051da:	8082                	ret

00000000800051dc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800051dc:	7139                	addi	sp,sp,-64
    800051de:	fc06                	sd	ra,56(sp)
    800051e0:	f822                	sd	s0,48(sp)
    800051e2:	f426                	sd	s1,40(sp)
    800051e4:	f04a                	sd	s2,32(sp)
    800051e6:	ec4e                	sd	s3,24(sp)
    800051e8:	e852                	sd	s4,16(sp)
    800051ea:	e456                	sd	s5,8(sp)
    800051ec:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800051ee:	00241497          	auipc	s1,0x241
    800051f2:	f3a48493          	addi	s1,s1,-198 # 80246128 <log>
    800051f6:	8526                	mv	a0,s1
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	c1e080e7          	jalr	-994(ra) # 80000e16 <acquire>
  log.outstanding -= 1;
    80005200:	509c                	lw	a5,32(s1)
    80005202:	37fd                	addiw	a5,a5,-1
    80005204:	0007891b          	sext.w	s2,a5
    80005208:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000520a:	50dc                	lw	a5,36(s1)
    8000520c:	efb9                	bnez	a5,8000526a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000520e:	06091663          	bnez	s2,8000527a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80005212:	00241497          	auipc	s1,0x241
    80005216:	f1648493          	addi	s1,s1,-234 # 80246128 <log>
    8000521a:	4785                	li	a5,1
    8000521c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	caa080e7          	jalr	-854(ra) # 80000eca <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005228:	54dc                	lw	a5,44(s1)
    8000522a:	06f04763          	bgtz	a5,80005298 <end_op+0xbc>
    acquire(&log.lock);
    8000522e:	00241497          	auipc	s1,0x241
    80005232:	efa48493          	addi	s1,s1,-262 # 80246128 <log>
    80005236:	8526                	mv	a0,s1
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	bde080e7          	jalr	-1058(ra) # 80000e16 <acquire>
    log.committing = 0;
    80005240:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	bda080e7          	jalr	-1062(ra) # 80002e20 <wakeup>
    release(&log.lock);
    8000524e:	8526                	mv	a0,s1
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	c7a080e7          	jalr	-902(ra) # 80000eca <release>
}
    80005258:	70e2                	ld	ra,56(sp)
    8000525a:	7442                	ld	s0,48(sp)
    8000525c:	74a2                	ld	s1,40(sp)
    8000525e:	7902                	ld	s2,32(sp)
    80005260:	69e2                	ld	s3,24(sp)
    80005262:	6a42                	ld	s4,16(sp)
    80005264:	6aa2                	ld	s5,8(sp)
    80005266:	6121                	addi	sp,sp,64
    80005268:	8082                	ret
    panic("log.committing");
    8000526a:	00004517          	auipc	a0,0x4
    8000526e:	5de50513          	addi	a0,a0,1502 # 80009848 <syscalls+0x210>
    80005272:	ffffb097          	auipc	ra,0xffffb
    80005276:	2d2080e7          	jalr	722(ra) # 80000544 <panic>
    wakeup(&log);
    8000527a:	00241497          	auipc	s1,0x241
    8000527e:	eae48493          	addi	s1,s1,-338 # 80246128 <log>
    80005282:	8526                	mv	a0,s1
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	b9c080e7          	jalr	-1124(ra) # 80002e20 <wakeup>
  release(&log.lock);
    8000528c:	8526                	mv	a0,s1
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	c3c080e7          	jalr	-964(ra) # 80000eca <release>
  if(do_commit){
    80005296:	b7c9                	j	80005258 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005298:	00241a97          	auipc	s5,0x241
    8000529c:	ec0a8a93          	addi	s5,s5,-320 # 80246158 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800052a0:	00241a17          	auipc	s4,0x241
    800052a4:	e88a0a13          	addi	s4,s4,-376 # 80246128 <log>
    800052a8:	018a2583          	lw	a1,24(s4)
    800052ac:	012585bb          	addw	a1,a1,s2
    800052b0:	2585                	addiw	a1,a1,1
    800052b2:	028a2503          	lw	a0,40(s4)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	cca080e7          	jalr	-822(ra) # 80003f80 <bread>
    800052be:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800052c0:	000aa583          	lw	a1,0(s5)
    800052c4:	028a2503          	lw	a0,40(s4)
    800052c8:	fffff097          	auipc	ra,0xfffff
    800052cc:	cb8080e7          	jalr	-840(ra) # 80003f80 <bread>
    800052d0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800052d2:	40000613          	li	a2,1024
    800052d6:	05850593          	addi	a1,a0,88
    800052da:	05848513          	addi	a0,s1,88
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	c94080e7          	jalr	-876(ra) # 80000f72 <memmove>
    bwrite(to);  // write the log
    800052e6:	8526                	mv	a0,s1
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	d8a080e7          	jalr	-630(ra) # 80004072 <bwrite>
    brelse(from);
    800052f0:	854e                	mv	a0,s3
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	dbe080e7          	jalr	-578(ra) # 800040b0 <brelse>
    brelse(to);
    800052fa:	8526                	mv	a0,s1
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	db4080e7          	jalr	-588(ra) # 800040b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005304:	2905                	addiw	s2,s2,1
    80005306:	0a91                	addi	s5,s5,4
    80005308:	02ca2783          	lw	a5,44(s4)
    8000530c:	f8f94ee3          	blt	s2,a5,800052a8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005310:	00000097          	auipc	ra,0x0
    80005314:	c6a080e7          	jalr	-918(ra) # 80004f7a <write_head>
    install_trans(0); // Now install writes to home locations
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	cda080e7          	jalr	-806(ra) # 80004ff4 <install_trans>
    log.lh.n = 0;
    80005322:	00241797          	auipc	a5,0x241
    80005326:	e207a923          	sw	zero,-462(a5) # 80246154 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	c50080e7          	jalr	-944(ra) # 80004f7a <write_head>
    80005332:	bdf5                	j	8000522e <end_op+0x52>

0000000080005334 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005334:	1101                	addi	sp,sp,-32
    80005336:	ec06                	sd	ra,24(sp)
    80005338:	e822                	sd	s0,16(sp)
    8000533a:	e426                	sd	s1,8(sp)
    8000533c:	e04a                	sd	s2,0(sp)
    8000533e:	1000                	addi	s0,sp,32
    80005340:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005342:	00241917          	auipc	s2,0x241
    80005346:	de690913          	addi	s2,s2,-538 # 80246128 <log>
    8000534a:	854a                	mv	a0,s2
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	aca080e7          	jalr	-1334(ra) # 80000e16 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005354:	02c92603          	lw	a2,44(s2)
    80005358:	47f5                	li	a5,29
    8000535a:	06c7c563          	blt	a5,a2,800053c4 <log_write+0x90>
    8000535e:	00241797          	auipc	a5,0x241
    80005362:	de67a783          	lw	a5,-538(a5) # 80246144 <log+0x1c>
    80005366:	37fd                	addiw	a5,a5,-1
    80005368:	04f65e63          	bge	a2,a5,800053c4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000536c:	00241797          	auipc	a5,0x241
    80005370:	ddc7a783          	lw	a5,-548(a5) # 80246148 <log+0x20>
    80005374:	06f05063          	blez	a5,800053d4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005378:	4781                	li	a5,0
    8000537a:	06c05563          	blez	a2,800053e4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000537e:	44cc                	lw	a1,12(s1)
    80005380:	00241717          	auipc	a4,0x241
    80005384:	dd870713          	addi	a4,a4,-552 # 80246158 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005388:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000538a:	4314                	lw	a3,0(a4)
    8000538c:	04b68c63          	beq	a3,a1,800053e4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005390:	2785                	addiw	a5,a5,1
    80005392:	0711                	addi	a4,a4,4
    80005394:	fef61be3          	bne	a2,a5,8000538a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005398:	0621                	addi	a2,a2,8
    8000539a:	060a                	slli	a2,a2,0x2
    8000539c:	00241797          	auipc	a5,0x241
    800053a0:	d8c78793          	addi	a5,a5,-628 # 80246128 <log>
    800053a4:	963e                	add	a2,a2,a5
    800053a6:	44dc                	lw	a5,12(s1)
    800053a8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800053aa:	8526                	mv	a0,s1
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	da2080e7          	jalr	-606(ra) # 8000414e <bpin>
    log.lh.n++;
    800053b4:	00241717          	auipc	a4,0x241
    800053b8:	d7470713          	addi	a4,a4,-652 # 80246128 <log>
    800053bc:	575c                	lw	a5,44(a4)
    800053be:	2785                	addiw	a5,a5,1
    800053c0:	d75c                	sw	a5,44(a4)
    800053c2:	a835                	j	800053fe <log_write+0xca>
    panic("too big a transaction");
    800053c4:	00004517          	auipc	a0,0x4
    800053c8:	49450513          	addi	a0,a0,1172 # 80009858 <syscalls+0x220>
    800053cc:	ffffb097          	auipc	ra,0xffffb
    800053d0:	178080e7          	jalr	376(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800053d4:	00004517          	auipc	a0,0x4
    800053d8:	49c50513          	addi	a0,a0,1180 # 80009870 <syscalls+0x238>
    800053dc:	ffffb097          	auipc	ra,0xffffb
    800053e0:	168080e7          	jalr	360(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800053e4:	00878713          	addi	a4,a5,8
    800053e8:	00271693          	slli	a3,a4,0x2
    800053ec:	00241717          	auipc	a4,0x241
    800053f0:	d3c70713          	addi	a4,a4,-708 # 80246128 <log>
    800053f4:	9736                	add	a4,a4,a3
    800053f6:	44d4                	lw	a3,12(s1)
    800053f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800053fa:	faf608e3          	beq	a2,a5,800053aa <log_write+0x76>
  }
  release(&log.lock);
    800053fe:	00241517          	auipc	a0,0x241
    80005402:	d2a50513          	addi	a0,a0,-726 # 80246128 <log>
    80005406:	ffffc097          	auipc	ra,0xffffc
    8000540a:	ac4080e7          	jalr	-1340(ra) # 80000eca <release>
}
    8000540e:	60e2                	ld	ra,24(sp)
    80005410:	6442                	ld	s0,16(sp)
    80005412:	64a2                	ld	s1,8(sp)
    80005414:	6902                	ld	s2,0(sp)
    80005416:	6105                	addi	sp,sp,32
    80005418:	8082                	ret

000000008000541a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000541a:	1101                	addi	sp,sp,-32
    8000541c:	ec06                	sd	ra,24(sp)
    8000541e:	e822                	sd	s0,16(sp)
    80005420:	e426                	sd	s1,8(sp)
    80005422:	e04a                	sd	s2,0(sp)
    80005424:	1000                	addi	s0,sp,32
    80005426:	84aa                	mv	s1,a0
    80005428:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000542a:	00004597          	auipc	a1,0x4
    8000542e:	46658593          	addi	a1,a1,1126 # 80009890 <syscalls+0x258>
    80005432:	0521                	addi	a0,a0,8
    80005434:	ffffc097          	auipc	ra,0xffffc
    80005438:	952080e7          	jalr	-1710(ra) # 80000d86 <initlock>
  lk->name = name;
    8000543c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005440:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005444:	0204a423          	sw	zero,40(s1)
}
    80005448:	60e2                	ld	ra,24(sp)
    8000544a:	6442                	ld	s0,16(sp)
    8000544c:	64a2                	ld	s1,8(sp)
    8000544e:	6902                	ld	s2,0(sp)
    80005450:	6105                	addi	sp,sp,32
    80005452:	8082                	ret

0000000080005454 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005454:	1101                	addi	sp,sp,-32
    80005456:	ec06                	sd	ra,24(sp)
    80005458:	e822                	sd	s0,16(sp)
    8000545a:	e426                	sd	s1,8(sp)
    8000545c:	e04a                	sd	s2,0(sp)
    8000545e:	1000                	addi	s0,sp,32
    80005460:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005462:	00850913          	addi	s2,a0,8
    80005466:	854a                	mv	a0,s2
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	9ae080e7          	jalr	-1618(ra) # 80000e16 <acquire>
  while (lk->locked) {
    80005470:	409c                	lw	a5,0(s1)
    80005472:	cb89                	beqz	a5,80005484 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005474:	85ca                	mv	a1,s2
    80005476:	8526                	mv	a0,s1
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	6cc080e7          	jalr	1740(ra) # 80002b44 <sleep>
  while (lk->locked) {
    80005480:	409c                	lw	a5,0(s1)
    80005482:	fbed                	bnez	a5,80005474 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005484:	4785                	li	a5,1
    80005486:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	97a080e7          	jalr	-1670(ra) # 80001e02 <myproc>
    80005490:	591c                	lw	a5,48(a0)
    80005492:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005494:	854a                	mv	a0,s2
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	a34080e7          	jalr	-1484(ra) # 80000eca <release>
}
    8000549e:	60e2                	ld	ra,24(sp)
    800054a0:	6442                	ld	s0,16(sp)
    800054a2:	64a2                	ld	s1,8(sp)
    800054a4:	6902                	ld	s2,0(sp)
    800054a6:	6105                	addi	sp,sp,32
    800054a8:	8082                	ret

00000000800054aa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800054aa:	1101                	addi	sp,sp,-32
    800054ac:	ec06                	sd	ra,24(sp)
    800054ae:	e822                	sd	s0,16(sp)
    800054b0:	e426                	sd	s1,8(sp)
    800054b2:	e04a                	sd	s2,0(sp)
    800054b4:	1000                	addi	s0,sp,32
    800054b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800054b8:	00850913          	addi	s2,a0,8
    800054bc:	854a                	mv	a0,s2
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	958080e7          	jalr	-1704(ra) # 80000e16 <acquire>
  lk->locked = 0;
    800054c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800054ca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	950080e7          	jalr	-1712(ra) # 80002e20 <wakeup>
  release(&lk->lk);
    800054d8:	854a                	mv	a0,s2
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	9f0080e7          	jalr	-1552(ra) # 80000eca <release>
}
    800054e2:	60e2                	ld	ra,24(sp)
    800054e4:	6442                	ld	s0,16(sp)
    800054e6:	64a2                	ld	s1,8(sp)
    800054e8:	6902                	ld	s2,0(sp)
    800054ea:	6105                	addi	sp,sp,32
    800054ec:	8082                	ret

00000000800054ee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800054ee:	7179                	addi	sp,sp,-48
    800054f0:	f406                	sd	ra,40(sp)
    800054f2:	f022                	sd	s0,32(sp)
    800054f4:	ec26                	sd	s1,24(sp)
    800054f6:	e84a                	sd	s2,16(sp)
    800054f8:	e44e                	sd	s3,8(sp)
    800054fa:	1800                	addi	s0,sp,48
    800054fc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800054fe:	00850913          	addi	s2,a0,8
    80005502:	854a                	mv	a0,s2
    80005504:	ffffc097          	auipc	ra,0xffffc
    80005508:	912080e7          	jalr	-1774(ra) # 80000e16 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000550c:	409c                	lw	a5,0(s1)
    8000550e:	ef99                	bnez	a5,8000552c <holdingsleep+0x3e>
    80005510:	4481                	li	s1,0
  release(&lk->lk);
    80005512:	854a                	mv	a0,s2
    80005514:	ffffc097          	auipc	ra,0xffffc
    80005518:	9b6080e7          	jalr	-1610(ra) # 80000eca <release>
  return r;
}
    8000551c:	8526                	mv	a0,s1
    8000551e:	70a2                	ld	ra,40(sp)
    80005520:	7402                	ld	s0,32(sp)
    80005522:	64e2                	ld	s1,24(sp)
    80005524:	6942                	ld	s2,16(sp)
    80005526:	69a2                	ld	s3,8(sp)
    80005528:	6145                	addi	sp,sp,48
    8000552a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000552c:	0284a983          	lw	s3,40(s1)
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	8d2080e7          	jalr	-1838(ra) # 80001e02 <myproc>
    80005538:	5904                	lw	s1,48(a0)
    8000553a:	413484b3          	sub	s1,s1,s3
    8000553e:	0014b493          	seqz	s1,s1
    80005542:	bfc1                	j	80005512 <holdingsleep+0x24>

0000000080005544 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005544:	1141                	addi	sp,sp,-16
    80005546:	e406                	sd	ra,8(sp)
    80005548:	e022                	sd	s0,0(sp)
    8000554a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000554c:	00004597          	auipc	a1,0x4
    80005550:	35458593          	addi	a1,a1,852 # 800098a0 <syscalls+0x268>
    80005554:	00241517          	auipc	a0,0x241
    80005558:	d1c50513          	addi	a0,a0,-740 # 80246270 <ftable>
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	82a080e7          	jalr	-2006(ra) # 80000d86 <initlock>
}
    80005564:	60a2                	ld	ra,8(sp)
    80005566:	6402                	ld	s0,0(sp)
    80005568:	0141                	addi	sp,sp,16
    8000556a:	8082                	ret

000000008000556c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000556c:	1101                	addi	sp,sp,-32
    8000556e:	ec06                	sd	ra,24(sp)
    80005570:	e822                	sd	s0,16(sp)
    80005572:	e426                	sd	s1,8(sp)
    80005574:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005576:	00241517          	auipc	a0,0x241
    8000557a:	cfa50513          	addi	a0,a0,-774 # 80246270 <ftable>
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	898080e7          	jalr	-1896(ra) # 80000e16 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005586:	00241497          	auipc	s1,0x241
    8000558a:	d0248493          	addi	s1,s1,-766 # 80246288 <ftable+0x18>
    8000558e:	00242717          	auipc	a4,0x242
    80005592:	c9a70713          	addi	a4,a4,-870 # 80247228 <disk>
    if(f->ref == 0){
    80005596:	40dc                	lw	a5,4(s1)
    80005598:	cf99                	beqz	a5,800055b6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000559a:	02848493          	addi	s1,s1,40
    8000559e:	fee49ce3          	bne	s1,a4,80005596 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800055a2:	00241517          	auipc	a0,0x241
    800055a6:	cce50513          	addi	a0,a0,-818 # 80246270 <ftable>
    800055aa:	ffffc097          	auipc	ra,0xffffc
    800055ae:	920080e7          	jalr	-1760(ra) # 80000eca <release>
  return 0;
    800055b2:	4481                	li	s1,0
    800055b4:	a819                	j	800055ca <filealloc+0x5e>
      f->ref = 1;
    800055b6:	4785                	li	a5,1
    800055b8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800055ba:	00241517          	auipc	a0,0x241
    800055be:	cb650513          	addi	a0,a0,-842 # 80246270 <ftable>
    800055c2:	ffffc097          	auipc	ra,0xffffc
    800055c6:	908080e7          	jalr	-1784(ra) # 80000eca <release>
}
    800055ca:	8526                	mv	a0,s1
    800055cc:	60e2                	ld	ra,24(sp)
    800055ce:	6442                	ld	s0,16(sp)
    800055d0:	64a2                	ld	s1,8(sp)
    800055d2:	6105                	addi	sp,sp,32
    800055d4:	8082                	ret

00000000800055d6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800055d6:	1101                	addi	sp,sp,-32
    800055d8:	ec06                	sd	ra,24(sp)
    800055da:	e822                	sd	s0,16(sp)
    800055dc:	e426                	sd	s1,8(sp)
    800055de:	1000                	addi	s0,sp,32
    800055e0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800055e2:	00241517          	auipc	a0,0x241
    800055e6:	c8e50513          	addi	a0,a0,-882 # 80246270 <ftable>
    800055ea:	ffffc097          	auipc	ra,0xffffc
    800055ee:	82c080e7          	jalr	-2004(ra) # 80000e16 <acquire>
  if(f->ref < 1)
    800055f2:	40dc                	lw	a5,4(s1)
    800055f4:	02f05263          	blez	a5,80005618 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800055f8:	2785                	addiw	a5,a5,1
    800055fa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800055fc:	00241517          	auipc	a0,0x241
    80005600:	c7450513          	addi	a0,a0,-908 # 80246270 <ftable>
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	8c6080e7          	jalr	-1850(ra) # 80000eca <release>
  return f;
}
    8000560c:	8526                	mv	a0,s1
    8000560e:	60e2                	ld	ra,24(sp)
    80005610:	6442                	ld	s0,16(sp)
    80005612:	64a2                	ld	s1,8(sp)
    80005614:	6105                	addi	sp,sp,32
    80005616:	8082                	ret
    panic("filedup");
    80005618:	00004517          	auipc	a0,0x4
    8000561c:	29050513          	addi	a0,a0,656 # 800098a8 <syscalls+0x270>
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	f24080e7          	jalr	-220(ra) # 80000544 <panic>

0000000080005628 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005628:	7139                	addi	sp,sp,-64
    8000562a:	fc06                	sd	ra,56(sp)
    8000562c:	f822                	sd	s0,48(sp)
    8000562e:	f426                	sd	s1,40(sp)
    80005630:	f04a                	sd	s2,32(sp)
    80005632:	ec4e                	sd	s3,24(sp)
    80005634:	e852                	sd	s4,16(sp)
    80005636:	e456                	sd	s5,8(sp)
    80005638:	0080                	addi	s0,sp,64
    8000563a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000563c:	00241517          	auipc	a0,0x241
    80005640:	c3450513          	addi	a0,a0,-972 # 80246270 <ftable>
    80005644:	ffffb097          	auipc	ra,0xffffb
    80005648:	7d2080e7          	jalr	2002(ra) # 80000e16 <acquire>
  if(f->ref < 1)
    8000564c:	40dc                	lw	a5,4(s1)
    8000564e:	06f05163          	blez	a5,800056b0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005652:	37fd                	addiw	a5,a5,-1
    80005654:	0007871b          	sext.w	a4,a5
    80005658:	c0dc                	sw	a5,4(s1)
    8000565a:	06e04363          	bgtz	a4,800056c0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000565e:	0004a903          	lw	s2,0(s1)
    80005662:	0094ca83          	lbu	s5,9(s1)
    80005666:	0104ba03          	ld	s4,16(s1)
    8000566a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000566e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005672:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005676:	00241517          	auipc	a0,0x241
    8000567a:	bfa50513          	addi	a0,a0,-1030 # 80246270 <ftable>
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	84c080e7          	jalr	-1972(ra) # 80000eca <release>

  if(ff.type == FD_PIPE){
    80005686:	4785                	li	a5,1
    80005688:	04f90d63          	beq	s2,a5,800056e2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000568c:	3979                	addiw	s2,s2,-2
    8000568e:	4785                	li	a5,1
    80005690:	0527e063          	bltu	a5,s2,800056d0 <fileclose+0xa8>
    begin_op();
    80005694:	00000097          	auipc	ra,0x0
    80005698:	ac8080e7          	jalr	-1336(ra) # 8000515c <begin_op>
    iput(ff.ip);
    8000569c:	854e                	mv	a0,s3
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	2b6080e7          	jalr	694(ra) # 80004954 <iput>
    end_op();
    800056a6:	00000097          	auipc	ra,0x0
    800056aa:	b36080e7          	jalr	-1226(ra) # 800051dc <end_op>
    800056ae:	a00d                	j	800056d0 <fileclose+0xa8>
    panic("fileclose");
    800056b0:	00004517          	auipc	a0,0x4
    800056b4:	20050513          	addi	a0,a0,512 # 800098b0 <syscalls+0x278>
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	e8c080e7          	jalr	-372(ra) # 80000544 <panic>
    release(&ftable.lock);
    800056c0:	00241517          	auipc	a0,0x241
    800056c4:	bb050513          	addi	a0,a0,-1104 # 80246270 <ftable>
    800056c8:	ffffc097          	auipc	ra,0xffffc
    800056cc:	802080e7          	jalr	-2046(ra) # 80000eca <release>
  }
}
    800056d0:	70e2                	ld	ra,56(sp)
    800056d2:	7442                	ld	s0,48(sp)
    800056d4:	74a2                	ld	s1,40(sp)
    800056d6:	7902                	ld	s2,32(sp)
    800056d8:	69e2                	ld	s3,24(sp)
    800056da:	6a42                	ld	s4,16(sp)
    800056dc:	6aa2                	ld	s5,8(sp)
    800056de:	6121                	addi	sp,sp,64
    800056e0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800056e2:	85d6                	mv	a1,s5
    800056e4:	8552                	mv	a0,s4
    800056e6:	00000097          	auipc	ra,0x0
    800056ea:	34c080e7          	jalr	844(ra) # 80005a32 <pipeclose>
    800056ee:	b7cd                	j	800056d0 <fileclose+0xa8>

00000000800056f0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800056f0:	715d                	addi	sp,sp,-80
    800056f2:	e486                	sd	ra,72(sp)
    800056f4:	e0a2                	sd	s0,64(sp)
    800056f6:	fc26                	sd	s1,56(sp)
    800056f8:	f84a                	sd	s2,48(sp)
    800056fa:	f44e                	sd	s3,40(sp)
    800056fc:	0880                	addi	s0,sp,80
    800056fe:	84aa                	mv	s1,a0
    80005700:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005702:	ffffc097          	auipc	ra,0xffffc
    80005706:	700080e7          	jalr	1792(ra) # 80001e02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000570a:	409c                	lw	a5,0(s1)
    8000570c:	37f9                	addiw	a5,a5,-2
    8000570e:	4705                	li	a4,1
    80005710:	04f76763          	bltu	a4,a5,8000575e <filestat+0x6e>
    80005714:	892a                	mv	s2,a0
    ilock(f->ip);
    80005716:	6c88                	ld	a0,24(s1)
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	082080e7          	jalr	130(ra) # 8000479a <ilock>
    stati(f->ip, &st);
    80005720:	fb840593          	addi	a1,s0,-72
    80005724:	6c88                	ld	a0,24(s1)
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	2fe080e7          	jalr	766(ra) # 80004a24 <stati>
    iunlock(f->ip);
    8000572e:	6c88                	ld	a0,24(s1)
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	12c080e7          	jalr	300(ra) # 8000485c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005738:	46e1                	li	a3,24
    8000573a:	fb840613          	addi	a2,s0,-72
    8000573e:	85ce                	mv	a1,s3
    80005740:	05093503          	ld	a0,80(s2)
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	178080e7          	jalr	376(ra) # 800018bc <copyout>
    8000574c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005750:	60a6                	ld	ra,72(sp)
    80005752:	6406                	ld	s0,64(sp)
    80005754:	74e2                	ld	s1,56(sp)
    80005756:	7942                	ld	s2,48(sp)
    80005758:	79a2                	ld	s3,40(sp)
    8000575a:	6161                	addi	sp,sp,80
    8000575c:	8082                	ret
  return -1;
    8000575e:	557d                	li	a0,-1
    80005760:	bfc5                	j	80005750 <filestat+0x60>

0000000080005762 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005762:	7179                	addi	sp,sp,-48
    80005764:	f406                	sd	ra,40(sp)
    80005766:	f022                	sd	s0,32(sp)
    80005768:	ec26                	sd	s1,24(sp)
    8000576a:	e84a                	sd	s2,16(sp)
    8000576c:	e44e                	sd	s3,8(sp)
    8000576e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005770:	00854783          	lbu	a5,8(a0)
    80005774:	c3d5                	beqz	a5,80005818 <fileread+0xb6>
    80005776:	84aa                	mv	s1,a0
    80005778:	89ae                	mv	s3,a1
    8000577a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000577c:	411c                	lw	a5,0(a0)
    8000577e:	4705                	li	a4,1
    80005780:	04e78963          	beq	a5,a4,800057d2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005784:	470d                	li	a4,3
    80005786:	04e78d63          	beq	a5,a4,800057e0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000578a:	4709                	li	a4,2
    8000578c:	06e79e63          	bne	a5,a4,80005808 <fileread+0xa6>
    ilock(f->ip);
    80005790:	6d08                	ld	a0,24(a0)
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	008080e7          	jalr	8(ra) # 8000479a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000579a:	874a                	mv	a4,s2
    8000579c:	5094                	lw	a3,32(s1)
    8000579e:	864e                	mv	a2,s3
    800057a0:	4585                	li	a1,1
    800057a2:	6c88                	ld	a0,24(s1)
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	2aa080e7          	jalr	682(ra) # 80004a4e <readi>
    800057ac:	892a                	mv	s2,a0
    800057ae:	00a05563          	blez	a0,800057b8 <fileread+0x56>
      f->off += r;
    800057b2:	509c                	lw	a5,32(s1)
    800057b4:	9fa9                	addw	a5,a5,a0
    800057b6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800057b8:	6c88                	ld	a0,24(s1)
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	0a2080e7          	jalr	162(ra) # 8000485c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800057c2:	854a                	mv	a0,s2
    800057c4:	70a2                	ld	ra,40(sp)
    800057c6:	7402                	ld	s0,32(sp)
    800057c8:	64e2                	ld	s1,24(sp)
    800057ca:	6942                	ld	s2,16(sp)
    800057cc:	69a2                	ld	s3,8(sp)
    800057ce:	6145                	addi	sp,sp,48
    800057d0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800057d2:	6908                	ld	a0,16(a0)
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	3ce080e7          	jalr	974(ra) # 80005ba2 <piperead>
    800057dc:	892a                	mv	s2,a0
    800057de:	b7d5                	j	800057c2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800057e0:	02451783          	lh	a5,36(a0)
    800057e4:	03079693          	slli	a3,a5,0x30
    800057e8:	92c1                	srli	a3,a3,0x30
    800057ea:	4725                	li	a4,9
    800057ec:	02d76863          	bltu	a4,a3,8000581c <fileread+0xba>
    800057f0:	0792                	slli	a5,a5,0x4
    800057f2:	00241717          	auipc	a4,0x241
    800057f6:	9de70713          	addi	a4,a4,-1570 # 802461d0 <devsw>
    800057fa:	97ba                	add	a5,a5,a4
    800057fc:	639c                	ld	a5,0(a5)
    800057fe:	c38d                	beqz	a5,80005820 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005800:	4505                	li	a0,1
    80005802:	9782                	jalr	a5
    80005804:	892a                	mv	s2,a0
    80005806:	bf75                	j	800057c2 <fileread+0x60>
    panic("fileread");
    80005808:	00004517          	auipc	a0,0x4
    8000580c:	0b850513          	addi	a0,a0,184 # 800098c0 <syscalls+0x288>
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	d34080e7          	jalr	-716(ra) # 80000544 <panic>
    return -1;
    80005818:	597d                	li	s2,-1
    8000581a:	b765                	j	800057c2 <fileread+0x60>
      return -1;
    8000581c:	597d                	li	s2,-1
    8000581e:	b755                	j	800057c2 <fileread+0x60>
    80005820:	597d                	li	s2,-1
    80005822:	b745                	j	800057c2 <fileread+0x60>

0000000080005824 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005824:	715d                	addi	sp,sp,-80
    80005826:	e486                	sd	ra,72(sp)
    80005828:	e0a2                	sd	s0,64(sp)
    8000582a:	fc26                	sd	s1,56(sp)
    8000582c:	f84a                	sd	s2,48(sp)
    8000582e:	f44e                	sd	s3,40(sp)
    80005830:	f052                	sd	s4,32(sp)
    80005832:	ec56                	sd	s5,24(sp)
    80005834:	e85a                	sd	s6,16(sp)
    80005836:	e45e                	sd	s7,8(sp)
    80005838:	e062                	sd	s8,0(sp)
    8000583a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000583c:	00954783          	lbu	a5,9(a0)
    80005840:	10078663          	beqz	a5,8000594c <filewrite+0x128>
    80005844:	892a                	mv	s2,a0
    80005846:	8aae                	mv	s5,a1
    80005848:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000584a:	411c                	lw	a5,0(a0)
    8000584c:	4705                	li	a4,1
    8000584e:	02e78263          	beq	a5,a4,80005872 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005852:	470d                	li	a4,3
    80005854:	02e78663          	beq	a5,a4,80005880 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005858:	4709                	li	a4,2
    8000585a:	0ee79163          	bne	a5,a4,8000593c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000585e:	0ac05d63          	blez	a2,80005918 <filewrite+0xf4>
    int i = 0;
    80005862:	4981                	li	s3,0
    80005864:	6b05                	lui	s6,0x1
    80005866:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000586a:	6b85                	lui	s7,0x1
    8000586c:	c00b8b9b          	addiw	s7,s7,-1024
    80005870:	a861                	j	80005908 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005872:	6908                	ld	a0,16(a0)
    80005874:	00000097          	auipc	ra,0x0
    80005878:	22e080e7          	jalr	558(ra) # 80005aa2 <pipewrite>
    8000587c:	8a2a                	mv	s4,a0
    8000587e:	a045                	j	8000591e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005880:	02451783          	lh	a5,36(a0)
    80005884:	03079693          	slli	a3,a5,0x30
    80005888:	92c1                	srli	a3,a3,0x30
    8000588a:	4725                	li	a4,9
    8000588c:	0cd76263          	bltu	a4,a3,80005950 <filewrite+0x12c>
    80005890:	0792                	slli	a5,a5,0x4
    80005892:	00241717          	auipc	a4,0x241
    80005896:	93e70713          	addi	a4,a4,-1730 # 802461d0 <devsw>
    8000589a:	97ba                	add	a5,a5,a4
    8000589c:	679c                	ld	a5,8(a5)
    8000589e:	cbdd                	beqz	a5,80005954 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800058a0:	4505                	li	a0,1
    800058a2:	9782                	jalr	a5
    800058a4:	8a2a                	mv	s4,a0
    800058a6:	a8a5                	j	8000591e <filewrite+0xfa>
    800058a8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	8b0080e7          	jalr	-1872(ra) # 8000515c <begin_op>
      ilock(f->ip);
    800058b4:	01893503          	ld	a0,24(s2)
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	ee2080e7          	jalr	-286(ra) # 8000479a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800058c0:	8762                	mv	a4,s8
    800058c2:	02092683          	lw	a3,32(s2)
    800058c6:	01598633          	add	a2,s3,s5
    800058ca:	4585                	li	a1,1
    800058cc:	01893503          	ld	a0,24(s2)
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	276080e7          	jalr	630(ra) # 80004b46 <writei>
    800058d8:	84aa                	mv	s1,a0
    800058da:	00a05763          	blez	a0,800058e8 <filewrite+0xc4>
        f->off += r;
    800058de:	02092783          	lw	a5,32(s2)
    800058e2:	9fa9                	addw	a5,a5,a0
    800058e4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800058e8:	01893503          	ld	a0,24(s2)
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	f70080e7          	jalr	-144(ra) # 8000485c <iunlock>
      end_op();
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	8e8080e7          	jalr	-1816(ra) # 800051dc <end_op>

      if(r != n1){
    800058fc:	009c1f63          	bne	s8,s1,8000591a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005900:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005904:	0149db63          	bge	s3,s4,8000591a <filewrite+0xf6>
      int n1 = n - i;
    80005908:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000590c:	84be                	mv	s1,a5
    8000590e:	2781                	sext.w	a5,a5
    80005910:	f8fb5ce3          	bge	s6,a5,800058a8 <filewrite+0x84>
    80005914:	84de                	mv	s1,s7
    80005916:	bf49                	j	800058a8 <filewrite+0x84>
    int i = 0;
    80005918:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000591a:	013a1f63          	bne	s4,s3,80005938 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000591e:	8552                	mv	a0,s4
    80005920:	60a6                	ld	ra,72(sp)
    80005922:	6406                	ld	s0,64(sp)
    80005924:	74e2                	ld	s1,56(sp)
    80005926:	7942                	ld	s2,48(sp)
    80005928:	79a2                	ld	s3,40(sp)
    8000592a:	7a02                	ld	s4,32(sp)
    8000592c:	6ae2                	ld	s5,24(sp)
    8000592e:	6b42                	ld	s6,16(sp)
    80005930:	6ba2                	ld	s7,8(sp)
    80005932:	6c02                	ld	s8,0(sp)
    80005934:	6161                	addi	sp,sp,80
    80005936:	8082                	ret
    ret = (i == n ? n : -1);
    80005938:	5a7d                	li	s4,-1
    8000593a:	b7d5                	j	8000591e <filewrite+0xfa>
    panic("filewrite");
    8000593c:	00004517          	auipc	a0,0x4
    80005940:	f9450513          	addi	a0,a0,-108 # 800098d0 <syscalls+0x298>
    80005944:	ffffb097          	auipc	ra,0xffffb
    80005948:	c00080e7          	jalr	-1024(ra) # 80000544 <panic>
    return -1;
    8000594c:	5a7d                	li	s4,-1
    8000594e:	bfc1                	j	8000591e <filewrite+0xfa>
      return -1;
    80005950:	5a7d                	li	s4,-1
    80005952:	b7f1                	j	8000591e <filewrite+0xfa>
    80005954:	5a7d                	li	s4,-1
    80005956:	b7e1                	j	8000591e <filewrite+0xfa>

0000000080005958 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005958:	7179                	addi	sp,sp,-48
    8000595a:	f406                	sd	ra,40(sp)
    8000595c:	f022                	sd	s0,32(sp)
    8000595e:	ec26                	sd	s1,24(sp)
    80005960:	e84a                	sd	s2,16(sp)
    80005962:	e44e                	sd	s3,8(sp)
    80005964:	e052                	sd	s4,0(sp)
    80005966:	1800                	addi	s0,sp,48
    80005968:	84aa                	mv	s1,a0
    8000596a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000596c:	0005b023          	sd	zero,0(a1)
    80005970:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005974:	00000097          	auipc	ra,0x0
    80005978:	bf8080e7          	jalr	-1032(ra) # 8000556c <filealloc>
    8000597c:	e088                	sd	a0,0(s1)
    8000597e:	c551                	beqz	a0,80005a0a <pipealloc+0xb2>
    80005980:	00000097          	auipc	ra,0x0
    80005984:	bec080e7          	jalr	-1044(ra) # 8000556c <filealloc>
    80005988:	00aa3023          	sd	a0,0(s4)
    8000598c:	c92d                	beqz	a0,800059fe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000598e:	ffffb097          	auipc	ra,0xffffb
    80005992:	38c080e7          	jalr	908(ra) # 80000d1a <kalloc>
    80005996:	892a                	mv	s2,a0
    80005998:	c125                	beqz	a0,800059f8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000599a:	4985                	li	s3,1
    8000599c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800059a0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800059a4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800059a8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800059ac:	00004597          	auipc	a1,0x4
    800059b0:	b8458593          	addi	a1,a1,-1148 # 80009530 <states.1902+0x1f0>
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	3d2080e7          	jalr	978(ra) # 80000d86 <initlock>
  (*f0)->type = FD_PIPE;
    800059bc:	609c                	ld	a5,0(s1)
    800059be:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800059c2:	609c                	ld	a5,0(s1)
    800059c4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800059c8:	609c                	ld	a5,0(s1)
    800059ca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800059ce:	609c                	ld	a5,0(s1)
    800059d0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800059d4:	000a3783          	ld	a5,0(s4)
    800059d8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800059dc:	000a3783          	ld	a5,0(s4)
    800059e0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800059e4:	000a3783          	ld	a5,0(s4)
    800059e8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800059ec:	000a3783          	ld	a5,0(s4)
    800059f0:	0127b823          	sd	s2,16(a5)
  return 0;
    800059f4:	4501                	li	a0,0
    800059f6:	a025                	j	80005a1e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800059f8:	6088                	ld	a0,0(s1)
    800059fa:	e501                	bnez	a0,80005a02 <pipealloc+0xaa>
    800059fc:	a039                	j	80005a0a <pipealloc+0xb2>
    800059fe:	6088                	ld	a0,0(s1)
    80005a00:	c51d                	beqz	a0,80005a2e <pipealloc+0xd6>
    fileclose(*f0);
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	c26080e7          	jalr	-986(ra) # 80005628 <fileclose>
  if(*f1)
    80005a0a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005a0e:	557d                	li	a0,-1
  if(*f1)
    80005a10:	c799                	beqz	a5,80005a1e <pipealloc+0xc6>
    fileclose(*f1);
    80005a12:	853e                	mv	a0,a5
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	c14080e7          	jalr	-1004(ra) # 80005628 <fileclose>
  return -1;
    80005a1c:	557d                	li	a0,-1
}
    80005a1e:	70a2                	ld	ra,40(sp)
    80005a20:	7402                	ld	s0,32(sp)
    80005a22:	64e2                	ld	s1,24(sp)
    80005a24:	6942                	ld	s2,16(sp)
    80005a26:	69a2                	ld	s3,8(sp)
    80005a28:	6a02                	ld	s4,0(sp)
    80005a2a:	6145                	addi	sp,sp,48
    80005a2c:	8082                	ret
  return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	b7fd                	j	80005a1e <pipealloc+0xc6>

0000000080005a32 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005a32:	1101                	addi	sp,sp,-32
    80005a34:	ec06                	sd	ra,24(sp)
    80005a36:	e822                	sd	s0,16(sp)
    80005a38:	e426                	sd	s1,8(sp)
    80005a3a:	e04a                	sd	s2,0(sp)
    80005a3c:	1000                	addi	s0,sp,32
    80005a3e:	84aa                	mv	s1,a0
    80005a40:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	3d4080e7          	jalr	980(ra) # 80000e16 <acquire>
  if(writable){
    80005a4a:	02090d63          	beqz	s2,80005a84 <pipeclose+0x52>
    pi->writeopen = 0;
    80005a4e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005a52:	21848513          	addi	a0,s1,536
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	3ca080e7          	jalr	970(ra) # 80002e20 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005a5e:	2204b783          	ld	a5,544(s1)
    80005a62:	eb95                	bnez	a5,80005a96 <pipeclose+0x64>
    release(&pi->lock);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	464080e7          	jalr	1124(ra) # 80000eca <release>
    kfree((char*)pi);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	122080e7          	jalr	290(ra) # 80000b92 <kfree>
  } else
    release(&pi->lock);
}
    80005a78:	60e2                	ld	ra,24(sp)
    80005a7a:	6442                	ld	s0,16(sp)
    80005a7c:	64a2                	ld	s1,8(sp)
    80005a7e:	6902                	ld	s2,0(sp)
    80005a80:	6105                	addi	sp,sp,32
    80005a82:	8082                	ret
    pi->readopen = 0;
    80005a84:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005a88:	21c48513          	addi	a0,s1,540
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	394080e7          	jalr	916(ra) # 80002e20 <wakeup>
    80005a94:	b7e9                	j	80005a5e <pipeclose+0x2c>
    release(&pi->lock);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	432080e7          	jalr	1074(ra) # 80000eca <release>
}
    80005aa0:	bfe1                	j	80005a78 <pipeclose+0x46>

0000000080005aa2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005aa2:	7159                	addi	sp,sp,-112
    80005aa4:	f486                	sd	ra,104(sp)
    80005aa6:	f0a2                	sd	s0,96(sp)
    80005aa8:	eca6                	sd	s1,88(sp)
    80005aaa:	e8ca                	sd	s2,80(sp)
    80005aac:	e4ce                	sd	s3,72(sp)
    80005aae:	e0d2                	sd	s4,64(sp)
    80005ab0:	fc56                	sd	s5,56(sp)
    80005ab2:	f85a                	sd	s6,48(sp)
    80005ab4:	f45e                	sd	s7,40(sp)
    80005ab6:	f062                	sd	s8,32(sp)
    80005ab8:	ec66                	sd	s9,24(sp)
    80005aba:	1880                	addi	s0,sp,112
    80005abc:	84aa                	mv	s1,a0
    80005abe:	8aae                	mv	s5,a1
    80005ac0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005ac2:	ffffc097          	auipc	ra,0xffffc
    80005ac6:	340080e7          	jalr	832(ra) # 80001e02 <myproc>
    80005aca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005acc:	8526                	mv	a0,s1
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	348080e7          	jalr	840(ra) # 80000e16 <acquire>
  while(i < n){
    80005ad6:	0d405463          	blez	s4,80005b9e <pipewrite+0xfc>
    80005ada:	8ba6                	mv	s7,s1
  int i = 0;
    80005adc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005ade:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005ae0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005ae4:	21c48c13          	addi	s8,s1,540
    80005ae8:	a08d                	j	80005b4a <pipewrite+0xa8>
      release(&pi->lock);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	3de080e7          	jalr	990(ra) # 80000eca <release>
      return -1;
    80005af4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005af6:	854a                	mv	a0,s2
    80005af8:	70a6                	ld	ra,104(sp)
    80005afa:	7406                	ld	s0,96(sp)
    80005afc:	64e6                	ld	s1,88(sp)
    80005afe:	6946                	ld	s2,80(sp)
    80005b00:	69a6                	ld	s3,72(sp)
    80005b02:	6a06                	ld	s4,64(sp)
    80005b04:	7ae2                	ld	s5,56(sp)
    80005b06:	7b42                	ld	s6,48(sp)
    80005b08:	7ba2                	ld	s7,40(sp)
    80005b0a:	7c02                	ld	s8,32(sp)
    80005b0c:	6ce2                	ld	s9,24(sp)
    80005b0e:	6165                	addi	sp,sp,112
    80005b10:	8082                	ret
      wakeup(&pi->nread);
    80005b12:	8566                	mv	a0,s9
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	30c080e7          	jalr	780(ra) # 80002e20 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005b1c:	85de                	mv	a1,s7
    80005b1e:	8562                	mv	a0,s8
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	024080e7          	jalr	36(ra) # 80002b44 <sleep>
    80005b28:	a839                	j	80005b46 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005b2a:	21c4a783          	lw	a5,540(s1)
    80005b2e:	0017871b          	addiw	a4,a5,1
    80005b32:	20e4ae23          	sw	a4,540(s1)
    80005b36:	1ff7f793          	andi	a5,a5,511
    80005b3a:	97a6                	add	a5,a5,s1
    80005b3c:	f9f44703          	lbu	a4,-97(s0)
    80005b40:	00e78c23          	sb	a4,24(a5)
      i++;
    80005b44:	2905                	addiw	s2,s2,1
  while(i < n){
    80005b46:	05495063          	bge	s2,s4,80005b86 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005b4a:	2204a783          	lw	a5,544(s1)
    80005b4e:	dfd1                	beqz	a5,80005aea <pipewrite+0x48>
    80005b50:	854e                	mv	a0,s3
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	5a4080e7          	jalr	1444(ra) # 800030f6 <killed>
    80005b5a:	f941                	bnez	a0,80005aea <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005b5c:	2184a783          	lw	a5,536(s1)
    80005b60:	21c4a703          	lw	a4,540(s1)
    80005b64:	2007879b          	addiw	a5,a5,512
    80005b68:	faf705e3          	beq	a4,a5,80005b12 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005b6c:	4685                	li	a3,1
    80005b6e:	01590633          	add	a2,s2,s5
    80005b72:	f9f40593          	addi	a1,s0,-97
    80005b76:	0509b503          	ld	a0,80(s3)
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	e06080e7          	jalr	-506(ra) # 80001980 <copyin>
    80005b82:	fb6514e3          	bne	a0,s6,80005b2a <pipewrite+0x88>
  wakeup(&pi->nread);
    80005b86:	21848513          	addi	a0,s1,536
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	296080e7          	jalr	662(ra) # 80002e20 <wakeup>
  release(&pi->lock);
    80005b92:	8526                	mv	a0,s1
    80005b94:	ffffb097          	auipc	ra,0xffffb
    80005b98:	336080e7          	jalr	822(ra) # 80000eca <release>
  return i;
    80005b9c:	bfa9                	j	80005af6 <pipewrite+0x54>
  int i = 0;
    80005b9e:	4901                	li	s2,0
    80005ba0:	b7dd                	j	80005b86 <pipewrite+0xe4>

0000000080005ba2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005ba2:	715d                	addi	sp,sp,-80
    80005ba4:	e486                	sd	ra,72(sp)
    80005ba6:	e0a2                	sd	s0,64(sp)
    80005ba8:	fc26                	sd	s1,56(sp)
    80005baa:	f84a                	sd	s2,48(sp)
    80005bac:	f44e                	sd	s3,40(sp)
    80005bae:	f052                	sd	s4,32(sp)
    80005bb0:	ec56                	sd	s5,24(sp)
    80005bb2:	e85a                	sd	s6,16(sp)
    80005bb4:	0880                	addi	s0,sp,80
    80005bb6:	84aa                	mv	s1,a0
    80005bb8:	892e                	mv	s2,a1
    80005bba:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	246080e7          	jalr	582(ra) # 80001e02 <myproc>
    80005bc4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005bc6:	8b26                	mv	s6,s1
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffb097          	auipc	ra,0xffffb
    80005bce:	24c080e7          	jalr	588(ra) # 80000e16 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005bd2:	2184a703          	lw	a4,536(s1)
    80005bd6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005bda:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005bde:	02f71763          	bne	a4,a5,80005c0c <piperead+0x6a>
    80005be2:	2244a783          	lw	a5,548(s1)
    80005be6:	c39d                	beqz	a5,80005c0c <piperead+0x6a>
    if(killed(pr)){
    80005be8:	8552                	mv	a0,s4
    80005bea:	ffffd097          	auipc	ra,0xffffd
    80005bee:	50c080e7          	jalr	1292(ra) # 800030f6 <killed>
    80005bf2:	e941                	bnez	a0,80005c82 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005bf4:	85da                	mv	a1,s6
    80005bf6:	854e                	mv	a0,s3
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	f4c080e7          	jalr	-180(ra) # 80002b44 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005c00:	2184a703          	lw	a4,536(s1)
    80005c04:	21c4a783          	lw	a5,540(s1)
    80005c08:	fcf70de3          	beq	a4,a5,80005be2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c0c:	09505263          	blez	s5,80005c90 <piperead+0xee>
    80005c10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005c12:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005c14:	2184a783          	lw	a5,536(s1)
    80005c18:	21c4a703          	lw	a4,540(s1)
    80005c1c:	02f70d63          	beq	a4,a5,80005c56 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005c20:	0017871b          	addiw	a4,a5,1
    80005c24:	20e4ac23          	sw	a4,536(s1)
    80005c28:	1ff7f793          	andi	a5,a5,511
    80005c2c:	97a6                	add	a5,a5,s1
    80005c2e:	0187c783          	lbu	a5,24(a5)
    80005c32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005c36:	4685                	li	a3,1
    80005c38:	fbf40613          	addi	a2,s0,-65
    80005c3c:	85ca                	mv	a1,s2
    80005c3e:	050a3503          	ld	a0,80(s4)
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	c7a080e7          	jalr	-902(ra) # 800018bc <copyout>
    80005c4a:	01650663          	beq	a0,s6,80005c56 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c4e:	2985                	addiw	s3,s3,1
    80005c50:	0905                	addi	s2,s2,1
    80005c52:	fd3a91e3          	bne	s5,s3,80005c14 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005c56:	21c48513          	addi	a0,s1,540
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	1c6080e7          	jalr	454(ra) # 80002e20 <wakeup>
  release(&pi->lock);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffb097          	auipc	ra,0xffffb
    80005c68:	266080e7          	jalr	614(ra) # 80000eca <release>
  return i;
}
    80005c6c:	854e                	mv	a0,s3
    80005c6e:	60a6                	ld	ra,72(sp)
    80005c70:	6406                	ld	s0,64(sp)
    80005c72:	74e2                	ld	s1,56(sp)
    80005c74:	7942                	ld	s2,48(sp)
    80005c76:	79a2                	ld	s3,40(sp)
    80005c78:	7a02                	ld	s4,32(sp)
    80005c7a:	6ae2                	ld	s5,24(sp)
    80005c7c:	6b42                	ld	s6,16(sp)
    80005c7e:	6161                	addi	sp,sp,80
    80005c80:	8082                	ret
      release(&pi->lock);
    80005c82:	8526                	mv	a0,s1
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	246080e7          	jalr	582(ra) # 80000eca <release>
      return -1;
    80005c8c:	59fd                	li	s3,-1
    80005c8e:	bff9                	j	80005c6c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c90:	4981                	li	s3,0
    80005c92:	b7d1                	j	80005c56 <piperead+0xb4>

0000000080005c94 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005c94:	1141                	addi	sp,sp,-16
    80005c96:	e422                	sd	s0,8(sp)
    80005c98:	0800                	addi	s0,sp,16
    80005c9a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005c9c:	8905                	andi	a0,a0,1
    80005c9e:	c111                	beqz	a0,80005ca2 <flags2perm+0xe>
      perm = PTE_X;
    80005ca0:	4521                	li	a0,8
    if(flags & 0x2)
    80005ca2:	8b89                	andi	a5,a5,2
    80005ca4:	c399                	beqz	a5,80005caa <flags2perm+0x16>
      perm |= PTE_W;
    80005ca6:	00456513          	ori	a0,a0,4
    return perm;
}
    80005caa:	6422                	ld	s0,8(sp)
    80005cac:	0141                	addi	sp,sp,16
    80005cae:	8082                	ret

0000000080005cb0 <exec>:

int
exec(char *path, char **argv)
{
    80005cb0:	df010113          	addi	sp,sp,-528
    80005cb4:	20113423          	sd	ra,520(sp)
    80005cb8:	20813023          	sd	s0,512(sp)
    80005cbc:	ffa6                	sd	s1,504(sp)
    80005cbe:	fbca                	sd	s2,496(sp)
    80005cc0:	f7ce                	sd	s3,488(sp)
    80005cc2:	f3d2                	sd	s4,480(sp)
    80005cc4:	efd6                	sd	s5,472(sp)
    80005cc6:	ebda                	sd	s6,464(sp)
    80005cc8:	e7de                	sd	s7,456(sp)
    80005cca:	e3e2                	sd	s8,448(sp)
    80005ccc:	ff66                	sd	s9,440(sp)
    80005cce:	fb6a                	sd	s10,432(sp)
    80005cd0:	f76e                	sd	s11,424(sp)
    80005cd2:	0c00                	addi	s0,sp,528
    80005cd4:	84aa                	mv	s1,a0
    80005cd6:	dea43c23          	sd	a0,-520(s0)
    80005cda:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005cde:	ffffc097          	auipc	ra,0xffffc
    80005ce2:	124080e7          	jalr	292(ra) # 80001e02 <myproc>
    80005ce6:	892a                	mv	s2,a0

  begin_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	474080e7          	jalr	1140(ra) # 8000515c <begin_op>

  if((ip = namei(path)) == 0){
    80005cf0:	8526                	mv	a0,s1
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	24e080e7          	jalr	590(ra) # 80004f40 <namei>
    80005cfa:	c92d                	beqz	a0,80005d6c <exec+0xbc>
    80005cfc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	a9c080e7          	jalr	-1380(ra) # 8000479a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005d06:	04000713          	li	a4,64
    80005d0a:	4681                	li	a3,0
    80005d0c:	e5040613          	addi	a2,s0,-432
    80005d10:	4581                	li	a1,0
    80005d12:	8526                	mv	a0,s1
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	d3a080e7          	jalr	-710(ra) # 80004a4e <readi>
    80005d1c:	04000793          	li	a5,64
    80005d20:	00f51a63          	bne	a0,a5,80005d34 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005d24:	e5042703          	lw	a4,-432(s0)
    80005d28:	464c47b7          	lui	a5,0x464c4
    80005d2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005d30:	04f70463          	beq	a4,a5,80005d78 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	cc6080e7          	jalr	-826(ra) # 800049fc <iunlockput>
    end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	49e080e7          	jalr	1182(ra) # 800051dc <end_op>
  }
  return -1;
    80005d46:	557d                	li	a0,-1
}
    80005d48:	20813083          	ld	ra,520(sp)
    80005d4c:	20013403          	ld	s0,512(sp)
    80005d50:	74fe                	ld	s1,504(sp)
    80005d52:	795e                	ld	s2,496(sp)
    80005d54:	79be                	ld	s3,488(sp)
    80005d56:	7a1e                	ld	s4,480(sp)
    80005d58:	6afe                	ld	s5,472(sp)
    80005d5a:	6b5e                	ld	s6,464(sp)
    80005d5c:	6bbe                	ld	s7,456(sp)
    80005d5e:	6c1e                	ld	s8,448(sp)
    80005d60:	7cfa                	ld	s9,440(sp)
    80005d62:	7d5a                	ld	s10,432(sp)
    80005d64:	7dba                	ld	s11,424(sp)
    80005d66:	21010113          	addi	sp,sp,528
    80005d6a:	8082                	ret
    end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	470080e7          	jalr	1136(ra) # 800051dc <end_op>
    return -1;
    80005d74:	557d                	li	a0,-1
    80005d76:	bfc9                	j	80005d48 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005d78:	854a                	mv	a0,s2
    80005d7a:	ffffc097          	auipc	ra,0xffffc
    80005d7e:	20a080e7          	jalr	522(ra) # 80001f84 <proc_pagetable>
    80005d82:	8baa                	mv	s7,a0
    80005d84:	d945                	beqz	a0,80005d34 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d86:	e7042983          	lw	s3,-400(s0)
    80005d8a:	e8845783          	lhu	a5,-376(s0)
    80005d8e:	c7ad                	beqz	a5,80005df8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005d90:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d92:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005d94:	6c85                	lui	s9,0x1
    80005d96:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005d9a:	def43823          	sd	a5,-528(s0)
    80005d9e:	ac0d                	j	80005fd0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005da0:	00004517          	auipc	a0,0x4
    80005da4:	b4050513          	addi	a0,a0,-1216 # 800098e0 <syscalls+0x2a8>
    80005da8:	ffffa097          	auipc	ra,0xffffa
    80005dac:	79c080e7          	jalr	1948(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005db0:	8756                	mv	a4,s5
    80005db2:	012d86bb          	addw	a3,s11,s2
    80005db6:	4581                	li	a1,0
    80005db8:	8526                	mv	a0,s1
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	c94080e7          	jalr	-876(ra) # 80004a4e <readi>
    80005dc2:	2501                	sext.w	a0,a0
    80005dc4:	1aaa9a63          	bne	s5,a0,80005f78 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005dc8:	6785                	lui	a5,0x1
    80005dca:	0127893b          	addw	s2,a5,s2
    80005dce:	77fd                	lui	a5,0xfffff
    80005dd0:	01478a3b          	addw	s4,a5,s4
    80005dd4:	1f897563          	bgeu	s2,s8,80005fbe <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005dd8:	02091593          	slli	a1,s2,0x20
    80005ddc:	9181                	srli	a1,a1,0x20
    80005dde:	95ea                	add	a1,a1,s10
    80005de0:	855e                	mv	a0,s7
    80005de2:	ffffb097          	auipc	ra,0xffffb
    80005de6:	4c2080e7          	jalr	1218(ra) # 800012a4 <walkaddr>
    80005dea:	862a                	mv	a2,a0
    if(pa == 0)
    80005dec:	d955                	beqz	a0,80005da0 <exec+0xf0>
      n = PGSIZE;
    80005dee:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005df0:	fd9a70e3          	bgeu	s4,s9,80005db0 <exec+0x100>
      n = sz - i;
    80005df4:	8ad2                	mv	s5,s4
    80005df6:	bf6d                	j	80005db0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005df8:	4a01                	li	s4,0
  iunlockput(ip);
    80005dfa:	8526                	mv	a0,s1
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	c00080e7          	jalr	-1024(ra) # 800049fc <iunlockput>
  end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	3d8080e7          	jalr	984(ra) # 800051dc <end_op>
  p = myproc();
    80005e0c:	ffffc097          	auipc	ra,0xffffc
    80005e10:	ff6080e7          	jalr	-10(ra) # 80001e02 <myproc>
    80005e14:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005e16:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005e1a:	6785                	lui	a5,0x1
    80005e1c:	17fd                	addi	a5,a5,-1
    80005e1e:	9a3e                	add	s4,s4,a5
    80005e20:	757d                	lui	a0,0xfffff
    80005e22:	00aa77b3          	and	a5,s4,a0
    80005e26:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005e2a:	4691                	li	a3,4
    80005e2c:	6609                	lui	a2,0x2
    80005e2e:	963e                	add	a2,a2,a5
    80005e30:	85be                	mv	a1,a5
    80005e32:	855e                	mv	a0,s7
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	824080e7          	jalr	-2012(ra) # 80001658 <uvmalloc>
    80005e3c:	8b2a                	mv	s6,a0
  ip = 0;
    80005e3e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005e40:	12050c63          	beqz	a0,80005f78 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005e44:	75f9                	lui	a1,0xffffe
    80005e46:	95aa                	add	a1,a1,a0
    80005e48:	855e                	mv	a0,s7
    80005e4a:	ffffc097          	auipc	ra,0xffffc
    80005e4e:	a40080e7          	jalr	-1472(ra) # 8000188a <uvmclear>
  stackbase = sp - PGSIZE;
    80005e52:	7c7d                	lui	s8,0xfffff
    80005e54:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005e56:	e0043783          	ld	a5,-512(s0)
    80005e5a:	6388                	ld	a0,0(a5)
    80005e5c:	c535                	beqz	a0,80005ec8 <exec+0x218>
    80005e5e:	e9040993          	addi	s3,s0,-368
    80005e62:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005e66:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005e68:	ffffb097          	auipc	ra,0xffffb
    80005e6c:	22e080e7          	jalr	558(ra) # 80001096 <strlen>
    80005e70:	2505                	addiw	a0,a0,1
    80005e72:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005e76:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005e7a:	13896663          	bltu	s2,s8,80005fa6 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005e7e:	e0043d83          	ld	s11,-512(s0)
    80005e82:	000dba03          	ld	s4,0(s11)
    80005e86:	8552                	mv	a0,s4
    80005e88:	ffffb097          	auipc	ra,0xffffb
    80005e8c:	20e080e7          	jalr	526(ra) # 80001096 <strlen>
    80005e90:	0015069b          	addiw	a3,a0,1
    80005e94:	8652                	mv	a2,s4
    80005e96:	85ca                	mv	a1,s2
    80005e98:	855e                	mv	a0,s7
    80005e9a:	ffffc097          	auipc	ra,0xffffc
    80005e9e:	a22080e7          	jalr	-1502(ra) # 800018bc <copyout>
    80005ea2:	10054663          	bltz	a0,80005fae <exec+0x2fe>
    ustack[argc] = sp;
    80005ea6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005eaa:	0485                	addi	s1,s1,1
    80005eac:	008d8793          	addi	a5,s11,8
    80005eb0:	e0f43023          	sd	a5,-512(s0)
    80005eb4:	008db503          	ld	a0,8(s11)
    80005eb8:	c911                	beqz	a0,80005ecc <exec+0x21c>
    if(argc >= MAXARG)
    80005eba:	09a1                	addi	s3,s3,8
    80005ebc:	fb3c96e3          	bne	s9,s3,80005e68 <exec+0x1b8>
  sz = sz1;
    80005ec0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ec4:	4481                	li	s1,0
    80005ec6:	a84d                	j	80005f78 <exec+0x2c8>
  sp = sz;
    80005ec8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005eca:	4481                	li	s1,0
  ustack[argc] = 0;
    80005ecc:	00349793          	slli	a5,s1,0x3
    80005ed0:	f9040713          	addi	a4,s0,-112
    80005ed4:	97ba                	add	a5,a5,a4
    80005ed6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005eda:	00148693          	addi	a3,s1,1
    80005ede:	068e                	slli	a3,a3,0x3
    80005ee0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005ee4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005ee8:	01897663          	bgeu	s2,s8,80005ef4 <exec+0x244>
  sz = sz1;
    80005eec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ef0:	4481                	li	s1,0
    80005ef2:	a059                	j	80005f78 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005ef4:	e9040613          	addi	a2,s0,-368
    80005ef8:	85ca                	mv	a1,s2
    80005efa:	855e                	mv	a0,s7
    80005efc:	ffffc097          	auipc	ra,0xffffc
    80005f00:	9c0080e7          	jalr	-1600(ra) # 800018bc <copyout>
    80005f04:	0a054963          	bltz	a0,80005fb6 <exec+0x306>
  p->trapframe->a1 = sp;
    80005f08:	058ab783          	ld	a5,88(s5)
    80005f0c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005f10:	df843783          	ld	a5,-520(s0)
    80005f14:	0007c703          	lbu	a4,0(a5)
    80005f18:	cf11                	beqz	a4,80005f34 <exec+0x284>
    80005f1a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005f1c:	02f00693          	li	a3,47
    80005f20:	a039                	j	80005f2e <exec+0x27e>
      last = s+1;
    80005f22:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005f26:	0785                	addi	a5,a5,1
    80005f28:	fff7c703          	lbu	a4,-1(a5)
    80005f2c:	c701                	beqz	a4,80005f34 <exec+0x284>
    if(*s == '/')
    80005f2e:	fed71ce3          	bne	a4,a3,80005f26 <exec+0x276>
    80005f32:	bfc5                	j	80005f22 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005f34:	4641                	li	a2,16
    80005f36:	df843583          	ld	a1,-520(s0)
    80005f3a:	158a8513          	addi	a0,s5,344
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	126080e7          	jalr	294(ra) # 80001064 <safestrcpy>
  oldpagetable = p->pagetable;
    80005f46:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005f4a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005f4e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005f52:	058ab783          	ld	a5,88(s5)
    80005f56:	e6843703          	ld	a4,-408(s0)
    80005f5a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005f5c:	058ab783          	ld	a5,88(s5)
    80005f60:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005f64:	85ea                	mv	a1,s10
    80005f66:	ffffc097          	auipc	ra,0xffffc
    80005f6a:	0ba080e7          	jalr	186(ra) # 80002020 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005f6e:	0004851b          	sext.w	a0,s1
    80005f72:	bbd9                	j	80005d48 <exec+0x98>
    80005f74:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005f78:	e0843583          	ld	a1,-504(s0)
    80005f7c:	855e                	mv	a0,s7
    80005f7e:	ffffc097          	auipc	ra,0xffffc
    80005f82:	0a2080e7          	jalr	162(ra) # 80002020 <proc_freepagetable>
  if(ip){
    80005f86:	da0497e3          	bnez	s1,80005d34 <exec+0x84>
  return -1;
    80005f8a:	557d                	li	a0,-1
    80005f8c:	bb75                	j	80005d48 <exec+0x98>
    80005f8e:	e1443423          	sd	s4,-504(s0)
    80005f92:	b7dd                	j	80005f78 <exec+0x2c8>
    80005f94:	e1443423          	sd	s4,-504(s0)
    80005f98:	b7c5                	j	80005f78 <exec+0x2c8>
    80005f9a:	e1443423          	sd	s4,-504(s0)
    80005f9e:	bfe9                	j	80005f78 <exec+0x2c8>
    80005fa0:	e1443423          	sd	s4,-504(s0)
    80005fa4:	bfd1                	j	80005f78 <exec+0x2c8>
  sz = sz1;
    80005fa6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005faa:	4481                	li	s1,0
    80005fac:	b7f1                	j	80005f78 <exec+0x2c8>
  sz = sz1;
    80005fae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005fb2:	4481                	li	s1,0
    80005fb4:	b7d1                	j	80005f78 <exec+0x2c8>
  sz = sz1;
    80005fb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005fba:	4481                	li	s1,0
    80005fbc:	bf75                	j	80005f78 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005fbe:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005fc2:	2b05                	addiw	s6,s6,1
    80005fc4:	0389899b          	addiw	s3,s3,56
    80005fc8:	e8845783          	lhu	a5,-376(s0)
    80005fcc:	e2fb57e3          	bge	s6,a5,80005dfa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005fd0:	2981                	sext.w	s3,s3
    80005fd2:	03800713          	li	a4,56
    80005fd6:	86ce                	mv	a3,s3
    80005fd8:	e1840613          	addi	a2,s0,-488
    80005fdc:	4581                	li	a1,0
    80005fde:	8526                	mv	a0,s1
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	a6e080e7          	jalr	-1426(ra) # 80004a4e <readi>
    80005fe8:	03800793          	li	a5,56
    80005fec:	f8f514e3          	bne	a0,a5,80005f74 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005ff0:	e1842783          	lw	a5,-488(s0)
    80005ff4:	4705                	li	a4,1
    80005ff6:	fce796e3          	bne	a5,a4,80005fc2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005ffa:	e4043903          	ld	s2,-448(s0)
    80005ffe:	e3843783          	ld	a5,-456(s0)
    80006002:	f8f966e3          	bltu	s2,a5,80005f8e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006006:	e2843783          	ld	a5,-472(s0)
    8000600a:	993e                	add	s2,s2,a5
    8000600c:	f8f964e3          	bltu	s2,a5,80005f94 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80006010:	df043703          	ld	a4,-528(s0)
    80006014:	8ff9                	and	a5,a5,a4
    80006016:	f3d1                	bnez	a5,80005f9a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80006018:	e1c42503          	lw	a0,-484(s0)
    8000601c:	00000097          	auipc	ra,0x0
    80006020:	c78080e7          	jalr	-904(ra) # 80005c94 <flags2perm>
    80006024:	86aa                	mv	a3,a0
    80006026:	864a                	mv	a2,s2
    80006028:	85d2                	mv	a1,s4
    8000602a:	855e                	mv	a0,s7
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	62c080e7          	jalr	1580(ra) # 80001658 <uvmalloc>
    80006034:	e0a43423          	sd	a0,-504(s0)
    80006038:	d525                	beqz	a0,80005fa0 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000603a:	e2843d03          	ld	s10,-472(s0)
    8000603e:	e2042d83          	lw	s11,-480(s0)
    80006042:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80006046:	f60c0ce3          	beqz	s8,80005fbe <exec+0x30e>
    8000604a:	8a62                	mv	s4,s8
    8000604c:	4901                	li	s2,0
    8000604e:	b369                	j	80005dd8 <exec+0x128>

0000000080006050 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006050:	7179                	addi	sp,sp,-48
    80006052:	f406                	sd	ra,40(sp)
    80006054:	f022                	sd	s0,32(sp)
    80006056:	ec26                	sd	s1,24(sp)
    80006058:	e84a                	sd	s2,16(sp)
    8000605a:	1800                	addi	s0,sp,48
    8000605c:	892e                	mv	s2,a1
    8000605e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80006060:	fdc40593          	addi	a1,s0,-36
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	960080e7          	jalr	-1696(ra) # 800039c4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000606c:	fdc42703          	lw	a4,-36(s0)
    80006070:	47bd                	li	a5,15
    80006072:	02e7eb63          	bltu	a5,a4,800060a8 <argfd+0x58>
    80006076:	ffffc097          	auipc	ra,0xffffc
    8000607a:	d8c080e7          	jalr	-628(ra) # 80001e02 <myproc>
    8000607e:	fdc42703          	lw	a4,-36(s0)
    80006082:	01a70793          	addi	a5,a4,26
    80006086:	078e                	slli	a5,a5,0x3
    80006088:	953e                	add	a0,a0,a5
    8000608a:	611c                	ld	a5,0(a0)
    8000608c:	c385                	beqz	a5,800060ac <argfd+0x5c>
    return -1;
  if(pfd)
    8000608e:	00090463          	beqz	s2,80006096 <argfd+0x46>
    *pfd = fd;
    80006092:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80006096:	4501                	li	a0,0
  if(pf)
    80006098:	c091                	beqz	s1,8000609c <argfd+0x4c>
    *pf = f;
    8000609a:	e09c                	sd	a5,0(s1)
}
    8000609c:	70a2                	ld	ra,40(sp)
    8000609e:	7402                	ld	s0,32(sp)
    800060a0:	64e2                	ld	s1,24(sp)
    800060a2:	6942                	ld	s2,16(sp)
    800060a4:	6145                	addi	sp,sp,48
    800060a6:	8082                	ret
    return -1;
    800060a8:	557d                	li	a0,-1
    800060aa:	bfcd                	j	8000609c <argfd+0x4c>
    800060ac:	557d                	li	a0,-1
    800060ae:	b7fd                	j	8000609c <argfd+0x4c>

00000000800060b0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800060b0:	1101                	addi	sp,sp,-32
    800060b2:	ec06                	sd	ra,24(sp)
    800060b4:	e822                	sd	s0,16(sp)
    800060b6:	e426                	sd	s1,8(sp)
    800060b8:	1000                	addi	s0,sp,32
    800060ba:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	d46080e7          	jalr	-698(ra) # 80001e02 <myproc>
    800060c4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800060c6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7fdb7d68>
    800060ca:	4501                	li	a0,0
    800060cc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800060ce:	6398                	ld	a4,0(a5)
    800060d0:	cb19                	beqz	a4,800060e6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800060d2:	2505                	addiw	a0,a0,1
    800060d4:	07a1                	addi	a5,a5,8
    800060d6:	fed51ce3          	bne	a0,a3,800060ce <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800060da:	557d                	li	a0,-1
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret
      p->ofile[fd] = f;
    800060e6:	01a50793          	addi	a5,a0,26
    800060ea:	078e                	slli	a5,a5,0x3
    800060ec:	963e                	add	a2,a2,a5
    800060ee:	e204                	sd	s1,0(a2)
      return fd;
    800060f0:	b7f5                	j	800060dc <fdalloc+0x2c>

00000000800060f2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800060f2:	715d                	addi	sp,sp,-80
    800060f4:	e486                	sd	ra,72(sp)
    800060f6:	e0a2                	sd	s0,64(sp)
    800060f8:	fc26                	sd	s1,56(sp)
    800060fa:	f84a                	sd	s2,48(sp)
    800060fc:	f44e                	sd	s3,40(sp)
    800060fe:	f052                	sd	s4,32(sp)
    80006100:	ec56                	sd	s5,24(sp)
    80006102:	e85a                	sd	s6,16(sp)
    80006104:	0880                	addi	s0,sp,80
    80006106:	8b2e                	mv	s6,a1
    80006108:	89b2                	mv	s3,a2
    8000610a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000610c:	fb040593          	addi	a1,s0,-80
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	e4e080e7          	jalr	-434(ra) # 80004f5e <nameiparent>
    80006118:	84aa                	mv	s1,a0
    8000611a:	16050063          	beqz	a0,8000627a <create+0x188>
    return 0;

  ilock(dp);
    8000611e:	ffffe097          	auipc	ra,0xffffe
    80006122:	67c080e7          	jalr	1660(ra) # 8000479a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006126:	4601                	li	a2,0
    80006128:	fb040593          	addi	a1,s0,-80
    8000612c:	8526                	mv	a0,s1
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	b50080e7          	jalr	-1200(ra) # 80004c7e <dirlookup>
    80006136:	8aaa                	mv	s5,a0
    80006138:	c931                	beqz	a0,8000618c <create+0x9a>
    iunlockput(dp);
    8000613a:	8526                	mv	a0,s1
    8000613c:	fffff097          	auipc	ra,0xfffff
    80006140:	8c0080e7          	jalr	-1856(ra) # 800049fc <iunlockput>
    ilock(ip);
    80006144:	8556                	mv	a0,s5
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	654080e7          	jalr	1620(ra) # 8000479a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000614e:	000b059b          	sext.w	a1,s6
    80006152:	4789                	li	a5,2
    80006154:	02f59563          	bne	a1,a5,8000617e <create+0x8c>
    80006158:	044ad783          	lhu	a5,68(s5)
    8000615c:	37f9                	addiw	a5,a5,-2
    8000615e:	17c2                	slli	a5,a5,0x30
    80006160:	93c1                	srli	a5,a5,0x30
    80006162:	4705                	li	a4,1
    80006164:	00f76d63          	bltu	a4,a5,8000617e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80006168:	8556                	mv	a0,s5
    8000616a:	60a6                	ld	ra,72(sp)
    8000616c:	6406                	ld	s0,64(sp)
    8000616e:	74e2                	ld	s1,56(sp)
    80006170:	7942                	ld	s2,48(sp)
    80006172:	79a2                	ld	s3,40(sp)
    80006174:	7a02                	ld	s4,32(sp)
    80006176:	6ae2                	ld	s5,24(sp)
    80006178:	6b42                	ld	s6,16(sp)
    8000617a:	6161                	addi	sp,sp,80
    8000617c:	8082                	ret
    iunlockput(ip);
    8000617e:	8556                	mv	a0,s5
    80006180:	fffff097          	auipc	ra,0xfffff
    80006184:	87c080e7          	jalr	-1924(ra) # 800049fc <iunlockput>
    return 0;
    80006188:	4a81                	li	s5,0
    8000618a:	bff9                	j	80006168 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000618c:	85da                	mv	a1,s6
    8000618e:	4088                	lw	a0,0(s1)
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	46e080e7          	jalr	1134(ra) # 800045fe <ialloc>
    80006198:	8a2a                	mv	s4,a0
    8000619a:	c921                	beqz	a0,800061ea <create+0xf8>
  ilock(ip);
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	5fe080e7          	jalr	1534(ra) # 8000479a <ilock>
  ip->major = major;
    800061a4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800061a8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800061ac:	4785                	li	a5,1
    800061ae:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800061b2:	8552                	mv	a0,s4
    800061b4:	ffffe097          	auipc	ra,0xffffe
    800061b8:	51c080e7          	jalr	1308(ra) # 800046d0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800061bc:	000b059b          	sext.w	a1,s6
    800061c0:	4785                	li	a5,1
    800061c2:	02f58b63          	beq	a1,a5,800061f8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800061c6:	004a2603          	lw	a2,4(s4)
    800061ca:	fb040593          	addi	a1,s0,-80
    800061ce:	8526                	mv	a0,s1
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	cbe080e7          	jalr	-834(ra) # 80004e8e <dirlink>
    800061d8:	06054f63          	bltz	a0,80006256 <create+0x164>
  iunlockput(dp);
    800061dc:	8526                	mv	a0,s1
    800061de:	fffff097          	auipc	ra,0xfffff
    800061e2:	81e080e7          	jalr	-2018(ra) # 800049fc <iunlockput>
  return ip;
    800061e6:	8ad2                	mv	s5,s4
    800061e8:	b741                	j	80006168 <create+0x76>
    iunlockput(dp);
    800061ea:	8526                	mv	a0,s1
    800061ec:	fffff097          	auipc	ra,0xfffff
    800061f0:	810080e7          	jalr	-2032(ra) # 800049fc <iunlockput>
    return 0;
    800061f4:	8ad2                	mv	s5,s4
    800061f6:	bf8d                	j	80006168 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800061f8:	004a2603          	lw	a2,4(s4)
    800061fc:	00003597          	auipc	a1,0x3
    80006200:	70458593          	addi	a1,a1,1796 # 80009900 <syscalls+0x2c8>
    80006204:	8552                	mv	a0,s4
    80006206:	fffff097          	auipc	ra,0xfffff
    8000620a:	c88080e7          	jalr	-888(ra) # 80004e8e <dirlink>
    8000620e:	04054463          	bltz	a0,80006256 <create+0x164>
    80006212:	40d0                	lw	a2,4(s1)
    80006214:	00003597          	auipc	a1,0x3
    80006218:	6f458593          	addi	a1,a1,1780 # 80009908 <syscalls+0x2d0>
    8000621c:	8552                	mv	a0,s4
    8000621e:	fffff097          	auipc	ra,0xfffff
    80006222:	c70080e7          	jalr	-912(ra) # 80004e8e <dirlink>
    80006226:	02054863          	bltz	a0,80006256 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000622a:	004a2603          	lw	a2,4(s4)
    8000622e:	fb040593          	addi	a1,s0,-80
    80006232:	8526                	mv	a0,s1
    80006234:	fffff097          	auipc	ra,0xfffff
    80006238:	c5a080e7          	jalr	-934(ra) # 80004e8e <dirlink>
    8000623c:	00054d63          	bltz	a0,80006256 <create+0x164>
    dp->nlink++;  // for ".."
    80006240:	04a4d783          	lhu	a5,74(s1)
    80006244:	2785                	addiw	a5,a5,1
    80006246:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000624a:	8526                	mv	a0,s1
    8000624c:	ffffe097          	auipc	ra,0xffffe
    80006250:	484080e7          	jalr	1156(ra) # 800046d0 <iupdate>
    80006254:	b761                	j	800061dc <create+0xea>
  ip->nlink = 0;
    80006256:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000625a:	8552                	mv	a0,s4
    8000625c:	ffffe097          	auipc	ra,0xffffe
    80006260:	474080e7          	jalr	1140(ra) # 800046d0 <iupdate>
  iunlockput(ip);
    80006264:	8552                	mv	a0,s4
    80006266:	ffffe097          	auipc	ra,0xffffe
    8000626a:	796080e7          	jalr	1942(ra) # 800049fc <iunlockput>
  iunlockput(dp);
    8000626e:	8526                	mv	a0,s1
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	78c080e7          	jalr	1932(ra) # 800049fc <iunlockput>
  return 0;
    80006278:	bdc5                	j	80006168 <create+0x76>
    return 0;
    8000627a:	8aaa                	mv	s5,a0
    8000627c:	b5f5                	j	80006168 <create+0x76>

000000008000627e <sys_dup>:
{
    8000627e:	7179                	addi	sp,sp,-48
    80006280:	f406                	sd	ra,40(sp)
    80006282:	f022                	sd	s0,32(sp)
    80006284:	ec26                	sd	s1,24(sp)
    80006286:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80006288:	fd840613          	addi	a2,s0,-40
    8000628c:	4581                	li	a1,0
    8000628e:	4501                	li	a0,0
    80006290:	00000097          	auipc	ra,0x0
    80006294:	dc0080e7          	jalr	-576(ra) # 80006050 <argfd>
    return -1;
    80006298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000629a:	02054363          	bltz	a0,800062c0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000629e:	fd843503          	ld	a0,-40(s0)
    800062a2:	00000097          	auipc	ra,0x0
    800062a6:	e0e080e7          	jalr	-498(ra) # 800060b0 <fdalloc>
    800062aa:	84aa                	mv	s1,a0
    return -1;
    800062ac:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800062ae:	00054963          	bltz	a0,800062c0 <sys_dup+0x42>
  filedup(f);
    800062b2:	fd843503          	ld	a0,-40(s0)
    800062b6:	fffff097          	auipc	ra,0xfffff
    800062ba:	320080e7          	jalr	800(ra) # 800055d6 <filedup>
  return fd;
    800062be:	87a6                	mv	a5,s1
}
    800062c0:	853e                	mv	a0,a5
    800062c2:	70a2                	ld	ra,40(sp)
    800062c4:	7402                	ld	s0,32(sp)
    800062c6:	64e2                	ld	s1,24(sp)
    800062c8:	6145                	addi	sp,sp,48
    800062ca:	8082                	ret

00000000800062cc <sys_read>:
{
    800062cc:	7179                	addi	sp,sp,-48
    800062ce:	f406                	sd	ra,40(sp)
    800062d0:	f022                	sd	s0,32(sp)
    800062d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800062d4:	fd840593          	addi	a1,s0,-40
    800062d8:	4505                	li	a0,1
    800062da:	ffffd097          	auipc	ra,0xffffd
    800062de:	70a080e7          	jalr	1802(ra) # 800039e4 <argaddr>
  argint(2, &n);
    800062e2:	fe440593          	addi	a1,s0,-28
    800062e6:	4509                	li	a0,2
    800062e8:	ffffd097          	auipc	ra,0xffffd
    800062ec:	6dc080e7          	jalr	1756(ra) # 800039c4 <argint>
  if(argfd(0, 0, &f) < 0)
    800062f0:	fe840613          	addi	a2,s0,-24
    800062f4:	4581                	li	a1,0
    800062f6:	4501                	li	a0,0
    800062f8:	00000097          	auipc	ra,0x0
    800062fc:	d58080e7          	jalr	-680(ra) # 80006050 <argfd>
    80006300:	87aa                	mv	a5,a0
    return -1;
    80006302:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80006304:	0007cc63          	bltz	a5,8000631c <sys_read+0x50>
  return fileread(f, p, n);
    80006308:	fe442603          	lw	a2,-28(s0)
    8000630c:	fd843583          	ld	a1,-40(s0)
    80006310:	fe843503          	ld	a0,-24(s0)
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	44e080e7          	jalr	1102(ra) # 80005762 <fileread>
}
    8000631c:	70a2                	ld	ra,40(sp)
    8000631e:	7402                	ld	s0,32(sp)
    80006320:	6145                	addi	sp,sp,48
    80006322:	8082                	ret

0000000080006324 <sys_write>:
{
    80006324:	7179                	addi	sp,sp,-48
    80006326:	f406                	sd	ra,40(sp)
    80006328:	f022                	sd	s0,32(sp)
    8000632a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000632c:	fd840593          	addi	a1,s0,-40
    80006330:	4505                	li	a0,1
    80006332:	ffffd097          	auipc	ra,0xffffd
    80006336:	6b2080e7          	jalr	1714(ra) # 800039e4 <argaddr>
  argint(2, &n);
    8000633a:	fe440593          	addi	a1,s0,-28
    8000633e:	4509                	li	a0,2
    80006340:	ffffd097          	auipc	ra,0xffffd
    80006344:	684080e7          	jalr	1668(ra) # 800039c4 <argint>
  if(argfd(0, 0, &f) < 0)
    80006348:	fe840613          	addi	a2,s0,-24
    8000634c:	4581                	li	a1,0
    8000634e:	4501                	li	a0,0
    80006350:	00000097          	auipc	ra,0x0
    80006354:	d00080e7          	jalr	-768(ra) # 80006050 <argfd>
    80006358:	87aa                	mv	a5,a0
    return -1;
    8000635a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000635c:	0007cc63          	bltz	a5,80006374 <sys_write+0x50>
  return filewrite(f, p, n);
    80006360:	fe442603          	lw	a2,-28(s0)
    80006364:	fd843583          	ld	a1,-40(s0)
    80006368:	fe843503          	ld	a0,-24(s0)
    8000636c:	fffff097          	auipc	ra,0xfffff
    80006370:	4b8080e7          	jalr	1208(ra) # 80005824 <filewrite>
}
    80006374:	70a2                	ld	ra,40(sp)
    80006376:	7402                	ld	s0,32(sp)
    80006378:	6145                	addi	sp,sp,48
    8000637a:	8082                	ret

000000008000637c <sys_close>:
{
    8000637c:	1101                	addi	sp,sp,-32
    8000637e:	ec06                	sd	ra,24(sp)
    80006380:	e822                	sd	s0,16(sp)
    80006382:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006384:	fe040613          	addi	a2,s0,-32
    80006388:	fec40593          	addi	a1,s0,-20
    8000638c:	4501                	li	a0,0
    8000638e:	00000097          	auipc	ra,0x0
    80006392:	cc2080e7          	jalr	-830(ra) # 80006050 <argfd>
    return -1;
    80006396:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006398:	02054463          	bltz	a0,800063c0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000639c:	ffffc097          	auipc	ra,0xffffc
    800063a0:	a66080e7          	jalr	-1434(ra) # 80001e02 <myproc>
    800063a4:	fec42783          	lw	a5,-20(s0)
    800063a8:	07e9                	addi	a5,a5,26
    800063aa:	078e                	slli	a5,a5,0x3
    800063ac:	97aa                	add	a5,a5,a0
    800063ae:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800063b2:	fe043503          	ld	a0,-32(s0)
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	272080e7          	jalr	626(ra) # 80005628 <fileclose>
  return 0;
    800063be:	4781                	li	a5,0
}
    800063c0:	853e                	mv	a0,a5
    800063c2:	60e2                	ld	ra,24(sp)
    800063c4:	6442                	ld	s0,16(sp)
    800063c6:	6105                	addi	sp,sp,32
    800063c8:	8082                	ret

00000000800063ca <sys_fstat>:
{
    800063ca:	1101                	addi	sp,sp,-32
    800063cc:	ec06                	sd	ra,24(sp)
    800063ce:	e822                	sd	s0,16(sp)
    800063d0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800063d2:	fe040593          	addi	a1,s0,-32
    800063d6:	4505                	li	a0,1
    800063d8:	ffffd097          	auipc	ra,0xffffd
    800063dc:	60c080e7          	jalr	1548(ra) # 800039e4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800063e0:	fe840613          	addi	a2,s0,-24
    800063e4:	4581                	li	a1,0
    800063e6:	4501                	li	a0,0
    800063e8:	00000097          	auipc	ra,0x0
    800063ec:	c68080e7          	jalr	-920(ra) # 80006050 <argfd>
    800063f0:	87aa                	mv	a5,a0
    return -1;
    800063f2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800063f4:	0007ca63          	bltz	a5,80006408 <sys_fstat+0x3e>
  return filestat(f, st);
    800063f8:	fe043583          	ld	a1,-32(s0)
    800063fc:	fe843503          	ld	a0,-24(s0)
    80006400:	fffff097          	auipc	ra,0xfffff
    80006404:	2f0080e7          	jalr	752(ra) # 800056f0 <filestat>
}
    80006408:	60e2                	ld	ra,24(sp)
    8000640a:	6442                	ld	s0,16(sp)
    8000640c:	6105                	addi	sp,sp,32
    8000640e:	8082                	ret

0000000080006410 <sys_link>:
{
    80006410:	7169                	addi	sp,sp,-304
    80006412:	f606                	sd	ra,296(sp)
    80006414:	f222                	sd	s0,288(sp)
    80006416:	ee26                	sd	s1,280(sp)
    80006418:	ea4a                	sd	s2,272(sp)
    8000641a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000641c:	08000613          	li	a2,128
    80006420:	ed040593          	addi	a1,s0,-304
    80006424:	4501                	li	a0,0
    80006426:	ffffd097          	auipc	ra,0xffffd
    8000642a:	5de080e7          	jalr	1502(ra) # 80003a04 <argstr>
    return -1;
    8000642e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006430:	10054e63          	bltz	a0,8000654c <sys_link+0x13c>
    80006434:	08000613          	li	a2,128
    80006438:	f5040593          	addi	a1,s0,-176
    8000643c:	4505                	li	a0,1
    8000643e:	ffffd097          	auipc	ra,0xffffd
    80006442:	5c6080e7          	jalr	1478(ra) # 80003a04 <argstr>
    return -1;
    80006446:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006448:	10054263          	bltz	a0,8000654c <sys_link+0x13c>
  begin_op();
    8000644c:	fffff097          	auipc	ra,0xfffff
    80006450:	d10080e7          	jalr	-752(ra) # 8000515c <begin_op>
  if((ip = namei(old)) == 0){
    80006454:	ed040513          	addi	a0,s0,-304
    80006458:	fffff097          	auipc	ra,0xfffff
    8000645c:	ae8080e7          	jalr	-1304(ra) # 80004f40 <namei>
    80006460:	84aa                	mv	s1,a0
    80006462:	c551                	beqz	a0,800064ee <sys_link+0xde>
  ilock(ip);
    80006464:	ffffe097          	auipc	ra,0xffffe
    80006468:	336080e7          	jalr	822(ra) # 8000479a <ilock>
  if(ip->type == T_DIR){
    8000646c:	04449703          	lh	a4,68(s1)
    80006470:	4785                	li	a5,1
    80006472:	08f70463          	beq	a4,a5,800064fa <sys_link+0xea>
  ip->nlink++;
    80006476:	04a4d783          	lhu	a5,74(s1)
    8000647a:	2785                	addiw	a5,a5,1
    8000647c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006480:	8526                	mv	a0,s1
    80006482:	ffffe097          	auipc	ra,0xffffe
    80006486:	24e080e7          	jalr	590(ra) # 800046d0 <iupdate>
  iunlock(ip);
    8000648a:	8526                	mv	a0,s1
    8000648c:	ffffe097          	auipc	ra,0xffffe
    80006490:	3d0080e7          	jalr	976(ra) # 8000485c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006494:	fd040593          	addi	a1,s0,-48
    80006498:	f5040513          	addi	a0,s0,-176
    8000649c:	fffff097          	auipc	ra,0xfffff
    800064a0:	ac2080e7          	jalr	-1342(ra) # 80004f5e <nameiparent>
    800064a4:	892a                	mv	s2,a0
    800064a6:	c935                	beqz	a0,8000651a <sys_link+0x10a>
  ilock(dp);
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	2f2080e7          	jalr	754(ra) # 8000479a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800064b0:	00092703          	lw	a4,0(s2)
    800064b4:	409c                	lw	a5,0(s1)
    800064b6:	04f71d63          	bne	a4,a5,80006510 <sys_link+0x100>
    800064ba:	40d0                	lw	a2,4(s1)
    800064bc:	fd040593          	addi	a1,s0,-48
    800064c0:	854a                	mv	a0,s2
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	9cc080e7          	jalr	-1588(ra) # 80004e8e <dirlink>
    800064ca:	04054363          	bltz	a0,80006510 <sys_link+0x100>
  iunlockput(dp);
    800064ce:	854a                	mv	a0,s2
    800064d0:	ffffe097          	auipc	ra,0xffffe
    800064d4:	52c080e7          	jalr	1324(ra) # 800049fc <iunlockput>
  iput(ip);
    800064d8:	8526                	mv	a0,s1
    800064da:	ffffe097          	auipc	ra,0xffffe
    800064de:	47a080e7          	jalr	1146(ra) # 80004954 <iput>
  end_op();
    800064e2:	fffff097          	auipc	ra,0xfffff
    800064e6:	cfa080e7          	jalr	-774(ra) # 800051dc <end_op>
  return 0;
    800064ea:	4781                	li	a5,0
    800064ec:	a085                	j	8000654c <sys_link+0x13c>
    end_op();
    800064ee:	fffff097          	auipc	ra,0xfffff
    800064f2:	cee080e7          	jalr	-786(ra) # 800051dc <end_op>
    return -1;
    800064f6:	57fd                	li	a5,-1
    800064f8:	a891                	j	8000654c <sys_link+0x13c>
    iunlockput(ip);
    800064fa:	8526                	mv	a0,s1
    800064fc:	ffffe097          	auipc	ra,0xffffe
    80006500:	500080e7          	jalr	1280(ra) # 800049fc <iunlockput>
    end_op();
    80006504:	fffff097          	auipc	ra,0xfffff
    80006508:	cd8080e7          	jalr	-808(ra) # 800051dc <end_op>
    return -1;
    8000650c:	57fd                	li	a5,-1
    8000650e:	a83d                	j	8000654c <sys_link+0x13c>
    iunlockput(dp);
    80006510:	854a                	mv	a0,s2
    80006512:	ffffe097          	auipc	ra,0xffffe
    80006516:	4ea080e7          	jalr	1258(ra) # 800049fc <iunlockput>
  ilock(ip);
    8000651a:	8526                	mv	a0,s1
    8000651c:	ffffe097          	auipc	ra,0xffffe
    80006520:	27e080e7          	jalr	638(ra) # 8000479a <ilock>
  ip->nlink--;
    80006524:	04a4d783          	lhu	a5,74(s1)
    80006528:	37fd                	addiw	a5,a5,-1
    8000652a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000652e:	8526                	mv	a0,s1
    80006530:	ffffe097          	auipc	ra,0xffffe
    80006534:	1a0080e7          	jalr	416(ra) # 800046d0 <iupdate>
  iunlockput(ip);
    80006538:	8526                	mv	a0,s1
    8000653a:	ffffe097          	auipc	ra,0xffffe
    8000653e:	4c2080e7          	jalr	1218(ra) # 800049fc <iunlockput>
  end_op();
    80006542:	fffff097          	auipc	ra,0xfffff
    80006546:	c9a080e7          	jalr	-870(ra) # 800051dc <end_op>
  return -1;
    8000654a:	57fd                	li	a5,-1
}
    8000654c:	853e                	mv	a0,a5
    8000654e:	70b2                	ld	ra,296(sp)
    80006550:	7412                	ld	s0,288(sp)
    80006552:	64f2                	ld	s1,280(sp)
    80006554:	6952                	ld	s2,272(sp)
    80006556:	6155                	addi	sp,sp,304
    80006558:	8082                	ret

000000008000655a <sys_unlink>:
{
    8000655a:	7151                	addi	sp,sp,-240
    8000655c:	f586                	sd	ra,232(sp)
    8000655e:	f1a2                	sd	s0,224(sp)
    80006560:	eda6                	sd	s1,216(sp)
    80006562:	e9ca                	sd	s2,208(sp)
    80006564:	e5ce                	sd	s3,200(sp)
    80006566:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006568:	08000613          	li	a2,128
    8000656c:	f3040593          	addi	a1,s0,-208
    80006570:	4501                	li	a0,0
    80006572:	ffffd097          	auipc	ra,0xffffd
    80006576:	492080e7          	jalr	1170(ra) # 80003a04 <argstr>
    8000657a:	18054163          	bltz	a0,800066fc <sys_unlink+0x1a2>
  begin_op();
    8000657e:	fffff097          	auipc	ra,0xfffff
    80006582:	bde080e7          	jalr	-1058(ra) # 8000515c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006586:	fb040593          	addi	a1,s0,-80
    8000658a:	f3040513          	addi	a0,s0,-208
    8000658e:	fffff097          	auipc	ra,0xfffff
    80006592:	9d0080e7          	jalr	-1584(ra) # 80004f5e <nameiparent>
    80006596:	84aa                	mv	s1,a0
    80006598:	c979                	beqz	a0,8000666e <sys_unlink+0x114>
  ilock(dp);
    8000659a:	ffffe097          	auipc	ra,0xffffe
    8000659e:	200080e7          	jalr	512(ra) # 8000479a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800065a2:	00003597          	auipc	a1,0x3
    800065a6:	35e58593          	addi	a1,a1,862 # 80009900 <syscalls+0x2c8>
    800065aa:	fb040513          	addi	a0,s0,-80
    800065ae:	ffffe097          	auipc	ra,0xffffe
    800065b2:	6b6080e7          	jalr	1718(ra) # 80004c64 <namecmp>
    800065b6:	14050a63          	beqz	a0,8000670a <sys_unlink+0x1b0>
    800065ba:	00003597          	auipc	a1,0x3
    800065be:	34e58593          	addi	a1,a1,846 # 80009908 <syscalls+0x2d0>
    800065c2:	fb040513          	addi	a0,s0,-80
    800065c6:	ffffe097          	auipc	ra,0xffffe
    800065ca:	69e080e7          	jalr	1694(ra) # 80004c64 <namecmp>
    800065ce:	12050e63          	beqz	a0,8000670a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800065d2:	f2c40613          	addi	a2,s0,-212
    800065d6:	fb040593          	addi	a1,s0,-80
    800065da:	8526                	mv	a0,s1
    800065dc:	ffffe097          	auipc	ra,0xffffe
    800065e0:	6a2080e7          	jalr	1698(ra) # 80004c7e <dirlookup>
    800065e4:	892a                	mv	s2,a0
    800065e6:	12050263          	beqz	a0,8000670a <sys_unlink+0x1b0>
  ilock(ip);
    800065ea:	ffffe097          	auipc	ra,0xffffe
    800065ee:	1b0080e7          	jalr	432(ra) # 8000479a <ilock>
  if(ip->nlink < 1)
    800065f2:	04a91783          	lh	a5,74(s2)
    800065f6:	08f05263          	blez	a5,8000667a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800065fa:	04491703          	lh	a4,68(s2)
    800065fe:	4785                	li	a5,1
    80006600:	08f70563          	beq	a4,a5,8000668a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006604:	4641                	li	a2,16
    80006606:	4581                	li	a1,0
    80006608:	fc040513          	addi	a0,s0,-64
    8000660c:	ffffb097          	auipc	ra,0xffffb
    80006610:	906080e7          	jalr	-1786(ra) # 80000f12 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006614:	4741                	li	a4,16
    80006616:	f2c42683          	lw	a3,-212(s0)
    8000661a:	fc040613          	addi	a2,s0,-64
    8000661e:	4581                	li	a1,0
    80006620:	8526                	mv	a0,s1
    80006622:	ffffe097          	auipc	ra,0xffffe
    80006626:	524080e7          	jalr	1316(ra) # 80004b46 <writei>
    8000662a:	47c1                	li	a5,16
    8000662c:	0af51563          	bne	a0,a5,800066d6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006630:	04491703          	lh	a4,68(s2)
    80006634:	4785                	li	a5,1
    80006636:	0af70863          	beq	a4,a5,800066e6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000663a:	8526                	mv	a0,s1
    8000663c:	ffffe097          	auipc	ra,0xffffe
    80006640:	3c0080e7          	jalr	960(ra) # 800049fc <iunlockput>
  ip->nlink--;
    80006644:	04a95783          	lhu	a5,74(s2)
    80006648:	37fd                	addiw	a5,a5,-1
    8000664a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000664e:	854a                	mv	a0,s2
    80006650:	ffffe097          	auipc	ra,0xffffe
    80006654:	080080e7          	jalr	128(ra) # 800046d0 <iupdate>
  iunlockput(ip);
    80006658:	854a                	mv	a0,s2
    8000665a:	ffffe097          	auipc	ra,0xffffe
    8000665e:	3a2080e7          	jalr	930(ra) # 800049fc <iunlockput>
  end_op();
    80006662:	fffff097          	auipc	ra,0xfffff
    80006666:	b7a080e7          	jalr	-1158(ra) # 800051dc <end_op>
  return 0;
    8000666a:	4501                	li	a0,0
    8000666c:	a84d                	j	8000671e <sys_unlink+0x1c4>
    end_op();
    8000666e:	fffff097          	auipc	ra,0xfffff
    80006672:	b6e080e7          	jalr	-1170(ra) # 800051dc <end_op>
    return -1;
    80006676:	557d                	li	a0,-1
    80006678:	a05d                	j	8000671e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000667a:	00003517          	auipc	a0,0x3
    8000667e:	29650513          	addi	a0,a0,662 # 80009910 <syscalls+0x2d8>
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	ec2080e7          	jalr	-318(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000668a:	04c92703          	lw	a4,76(s2)
    8000668e:	02000793          	li	a5,32
    80006692:	f6e7f9e3          	bgeu	a5,a4,80006604 <sys_unlink+0xaa>
    80006696:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000669a:	4741                	li	a4,16
    8000669c:	86ce                	mv	a3,s3
    8000669e:	f1840613          	addi	a2,s0,-232
    800066a2:	4581                	li	a1,0
    800066a4:	854a                	mv	a0,s2
    800066a6:	ffffe097          	auipc	ra,0xffffe
    800066aa:	3a8080e7          	jalr	936(ra) # 80004a4e <readi>
    800066ae:	47c1                	li	a5,16
    800066b0:	00f51b63          	bne	a0,a5,800066c6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800066b4:	f1845783          	lhu	a5,-232(s0)
    800066b8:	e7a1                	bnez	a5,80006700 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800066ba:	29c1                	addiw	s3,s3,16
    800066bc:	04c92783          	lw	a5,76(s2)
    800066c0:	fcf9ede3          	bltu	s3,a5,8000669a <sys_unlink+0x140>
    800066c4:	b781                	j	80006604 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800066c6:	00003517          	auipc	a0,0x3
    800066ca:	26250513          	addi	a0,a0,610 # 80009928 <syscalls+0x2f0>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	e76080e7          	jalr	-394(ra) # 80000544 <panic>
    panic("unlink: writei");
    800066d6:	00003517          	auipc	a0,0x3
    800066da:	26a50513          	addi	a0,a0,618 # 80009940 <syscalls+0x308>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e66080e7          	jalr	-410(ra) # 80000544 <panic>
    dp->nlink--;
    800066e6:	04a4d783          	lhu	a5,74(s1)
    800066ea:	37fd                	addiw	a5,a5,-1
    800066ec:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800066f0:	8526                	mv	a0,s1
    800066f2:	ffffe097          	auipc	ra,0xffffe
    800066f6:	fde080e7          	jalr	-34(ra) # 800046d0 <iupdate>
    800066fa:	b781                	j	8000663a <sys_unlink+0xe0>
    return -1;
    800066fc:	557d                	li	a0,-1
    800066fe:	a005                	j	8000671e <sys_unlink+0x1c4>
    iunlockput(ip);
    80006700:	854a                	mv	a0,s2
    80006702:	ffffe097          	auipc	ra,0xffffe
    80006706:	2fa080e7          	jalr	762(ra) # 800049fc <iunlockput>
  iunlockput(dp);
    8000670a:	8526                	mv	a0,s1
    8000670c:	ffffe097          	auipc	ra,0xffffe
    80006710:	2f0080e7          	jalr	752(ra) # 800049fc <iunlockput>
  end_op();
    80006714:	fffff097          	auipc	ra,0xfffff
    80006718:	ac8080e7          	jalr	-1336(ra) # 800051dc <end_op>
  return -1;
    8000671c:	557d                	li	a0,-1
}
    8000671e:	70ae                	ld	ra,232(sp)
    80006720:	740e                	ld	s0,224(sp)
    80006722:	64ee                	ld	s1,216(sp)
    80006724:	694e                	ld	s2,208(sp)
    80006726:	69ae                	ld	s3,200(sp)
    80006728:	616d                	addi	sp,sp,240
    8000672a:	8082                	ret

000000008000672c <sys_open>:

uint64
sys_open(void)
{
    8000672c:	7131                	addi	sp,sp,-192
    8000672e:	fd06                	sd	ra,184(sp)
    80006730:	f922                	sd	s0,176(sp)
    80006732:	f526                	sd	s1,168(sp)
    80006734:	f14a                	sd	s2,160(sp)
    80006736:	ed4e                	sd	s3,152(sp)
    80006738:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000673a:	f4c40593          	addi	a1,s0,-180
    8000673e:	4505                	li	a0,1
    80006740:	ffffd097          	auipc	ra,0xffffd
    80006744:	284080e7          	jalr	644(ra) # 800039c4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006748:	08000613          	li	a2,128
    8000674c:	f5040593          	addi	a1,s0,-176
    80006750:	4501                	li	a0,0
    80006752:	ffffd097          	auipc	ra,0xffffd
    80006756:	2b2080e7          	jalr	690(ra) # 80003a04 <argstr>
    8000675a:	87aa                	mv	a5,a0
    return -1;
    8000675c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000675e:	0a07c963          	bltz	a5,80006810 <sys_open+0xe4>

  begin_op();
    80006762:	fffff097          	auipc	ra,0xfffff
    80006766:	9fa080e7          	jalr	-1542(ra) # 8000515c <begin_op>

  if(omode & O_CREATE){
    8000676a:	f4c42783          	lw	a5,-180(s0)
    8000676e:	2007f793          	andi	a5,a5,512
    80006772:	cfc5                	beqz	a5,8000682a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006774:	4681                	li	a3,0
    80006776:	4601                	li	a2,0
    80006778:	4589                	li	a1,2
    8000677a:	f5040513          	addi	a0,s0,-176
    8000677e:	00000097          	auipc	ra,0x0
    80006782:	974080e7          	jalr	-1676(ra) # 800060f2 <create>
    80006786:	84aa                	mv	s1,a0
    if(ip == 0){
    80006788:	c959                	beqz	a0,8000681e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000678a:	04449703          	lh	a4,68(s1)
    8000678e:	478d                	li	a5,3
    80006790:	00f71763          	bne	a4,a5,8000679e <sys_open+0x72>
    80006794:	0464d703          	lhu	a4,70(s1)
    80006798:	47a5                	li	a5,9
    8000679a:	0ce7ed63          	bltu	a5,a4,80006874 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000679e:	fffff097          	auipc	ra,0xfffff
    800067a2:	dce080e7          	jalr	-562(ra) # 8000556c <filealloc>
    800067a6:	89aa                	mv	s3,a0
    800067a8:	10050363          	beqz	a0,800068ae <sys_open+0x182>
    800067ac:	00000097          	auipc	ra,0x0
    800067b0:	904080e7          	jalr	-1788(ra) # 800060b0 <fdalloc>
    800067b4:	892a                	mv	s2,a0
    800067b6:	0e054763          	bltz	a0,800068a4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800067ba:	04449703          	lh	a4,68(s1)
    800067be:	478d                	li	a5,3
    800067c0:	0cf70563          	beq	a4,a5,8000688a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800067c4:	4789                	li	a5,2
    800067c6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800067ca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800067ce:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800067d2:	f4c42783          	lw	a5,-180(s0)
    800067d6:	0017c713          	xori	a4,a5,1
    800067da:	8b05                	andi	a4,a4,1
    800067dc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800067e0:	0037f713          	andi	a4,a5,3
    800067e4:	00e03733          	snez	a4,a4
    800067e8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800067ec:	4007f793          	andi	a5,a5,1024
    800067f0:	c791                	beqz	a5,800067fc <sys_open+0xd0>
    800067f2:	04449703          	lh	a4,68(s1)
    800067f6:	4789                	li	a5,2
    800067f8:	0af70063          	beq	a4,a5,80006898 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800067fc:	8526                	mv	a0,s1
    800067fe:	ffffe097          	auipc	ra,0xffffe
    80006802:	05e080e7          	jalr	94(ra) # 8000485c <iunlock>
  end_op();
    80006806:	fffff097          	auipc	ra,0xfffff
    8000680a:	9d6080e7          	jalr	-1578(ra) # 800051dc <end_op>

  return fd;
    8000680e:	854a                	mv	a0,s2
}
    80006810:	70ea                	ld	ra,184(sp)
    80006812:	744a                	ld	s0,176(sp)
    80006814:	74aa                	ld	s1,168(sp)
    80006816:	790a                	ld	s2,160(sp)
    80006818:	69ea                	ld	s3,152(sp)
    8000681a:	6129                	addi	sp,sp,192
    8000681c:	8082                	ret
      end_op();
    8000681e:	fffff097          	auipc	ra,0xfffff
    80006822:	9be080e7          	jalr	-1602(ra) # 800051dc <end_op>
      return -1;
    80006826:	557d                	li	a0,-1
    80006828:	b7e5                	j	80006810 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000682a:	f5040513          	addi	a0,s0,-176
    8000682e:	ffffe097          	auipc	ra,0xffffe
    80006832:	712080e7          	jalr	1810(ra) # 80004f40 <namei>
    80006836:	84aa                	mv	s1,a0
    80006838:	c905                	beqz	a0,80006868 <sys_open+0x13c>
    ilock(ip);
    8000683a:	ffffe097          	auipc	ra,0xffffe
    8000683e:	f60080e7          	jalr	-160(ra) # 8000479a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006842:	04449703          	lh	a4,68(s1)
    80006846:	4785                	li	a5,1
    80006848:	f4f711e3          	bne	a4,a5,8000678a <sys_open+0x5e>
    8000684c:	f4c42783          	lw	a5,-180(s0)
    80006850:	d7b9                	beqz	a5,8000679e <sys_open+0x72>
      iunlockput(ip);
    80006852:	8526                	mv	a0,s1
    80006854:	ffffe097          	auipc	ra,0xffffe
    80006858:	1a8080e7          	jalr	424(ra) # 800049fc <iunlockput>
      end_op();
    8000685c:	fffff097          	auipc	ra,0xfffff
    80006860:	980080e7          	jalr	-1664(ra) # 800051dc <end_op>
      return -1;
    80006864:	557d                	li	a0,-1
    80006866:	b76d                	j	80006810 <sys_open+0xe4>
      end_op();
    80006868:	fffff097          	auipc	ra,0xfffff
    8000686c:	974080e7          	jalr	-1676(ra) # 800051dc <end_op>
      return -1;
    80006870:	557d                	li	a0,-1
    80006872:	bf79                	j	80006810 <sys_open+0xe4>
    iunlockput(ip);
    80006874:	8526                	mv	a0,s1
    80006876:	ffffe097          	auipc	ra,0xffffe
    8000687a:	186080e7          	jalr	390(ra) # 800049fc <iunlockput>
    end_op();
    8000687e:	fffff097          	auipc	ra,0xfffff
    80006882:	95e080e7          	jalr	-1698(ra) # 800051dc <end_op>
    return -1;
    80006886:	557d                	li	a0,-1
    80006888:	b761                	j	80006810 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000688a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000688e:	04649783          	lh	a5,70(s1)
    80006892:	02f99223          	sh	a5,36(s3)
    80006896:	bf25                	j	800067ce <sys_open+0xa2>
    itrunc(ip);
    80006898:	8526                	mv	a0,s1
    8000689a:	ffffe097          	auipc	ra,0xffffe
    8000689e:	00e080e7          	jalr	14(ra) # 800048a8 <itrunc>
    800068a2:	bfa9                	j	800067fc <sys_open+0xd0>
      fileclose(f);
    800068a4:	854e                	mv	a0,s3
    800068a6:	fffff097          	auipc	ra,0xfffff
    800068aa:	d82080e7          	jalr	-638(ra) # 80005628 <fileclose>
    iunlockput(ip);
    800068ae:	8526                	mv	a0,s1
    800068b0:	ffffe097          	auipc	ra,0xffffe
    800068b4:	14c080e7          	jalr	332(ra) # 800049fc <iunlockput>
    end_op();
    800068b8:	fffff097          	auipc	ra,0xfffff
    800068bc:	924080e7          	jalr	-1756(ra) # 800051dc <end_op>
    return -1;
    800068c0:	557d                	li	a0,-1
    800068c2:	b7b9                	j	80006810 <sys_open+0xe4>

00000000800068c4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800068c4:	7175                	addi	sp,sp,-144
    800068c6:	e506                	sd	ra,136(sp)
    800068c8:	e122                	sd	s0,128(sp)
    800068ca:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800068cc:	fffff097          	auipc	ra,0xfffff
    800068d0:	890080e7          	jalr	-1904(ra) # 8000515c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800068d4:	08000613          	li	a2,128
    800068d8:	f7040593          	addi	a1,s0,-144
    800068dc:	4501                	li	a0,0
    800068de:	ffffd097          	auipc	ra,0xffffd
    800068e2:	126080e7          	jalr	294(ra) # 80003a04 <argstr>
    800068e6:	02054963          	bltz	a0,80006918 <sys_mkdir+0x54>
    800068ea:	4681                	li	a3,0
    800068ec:	4601                	li	a2,0
    800068ee:	4585                	li	a1,1
    800068f0:	f7040513          	addi	a0,s0,-144
    800068f4:	fffff097          	auipc	ra,0xfffff
    800068f8:	7fe080e7          	jalr	2046(ra) # 800060f2 <create>
    800068fc:	cd11                	beqz	a0,80006918 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800068fe:	ffffe097          	auipc	ra,0xffffe
    80006902:	0fe080e7          	jalr	254(ra) # 800049fc <iunlockput>
  end_op();
    80006906:	fffff097          	auipc	ra,0xfffff
    8000690a:	8d6080e7          	jalr	-1834(ra) # 800051dc <end_op>
  return 0;
    8000690e:	4501                	li	a0,0
}
    80006910:	60aa                	ld	ra,136(sp)
    80006912:	640a                	ld	s0,128(sp)
    80006914:	6149                	addi	sp,sp,144
    80006916:	8082                	ret
    end_op();
    80006918:	fffff097          	auipc	ra,0xfffff
    8000691c:	8c4080e7          	jalr	-1852(ra) # 800051dc <end_op>
    return -1;
    80006920:	557d                	li	a0,-1
    80006922:	b7fd                	j	80006910 <sys_mkdir+0x4c>

0000000080006924 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006924:	7135                	addi	sp,sp,-160
    80006926:	ed06                	sd	ra,152(sp)
    80006928:	e922                	sd	s0,144(sp)
    8000692a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000692c:	fffff097          	auipc	ra,0xfffff
    80006930:	830080e7          	jalr	-2000(ra) # 8000515c <begin_op>
  argint(1, &major);
    80006934:	f6c40593          	addi	a1,s0,-148
    80006938:	4505                	li	a0,1
    8000693a:	ffffd097          	auipc	ra,0xffffd
    8000693e:	08a080e7          	jalr	138(ra) # 800039c4 <argint>
  argint(2, &minor);
    80006942:	f6840593          	addi	a1,s0,-152
    80006946:	4509                	li	a0,2
    80006948:	ffffd097          	auipc	ra,0xffffd
    8000694c:	07c080e7          	jalr	124(ra) # 800039c4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006950:	08000613          	li	a2,128
    80006954:	f7040593          	addi	a1,s0,-144
    80006958:	4501                	li	a0,0
    8000695a:	ffffd097          	auipc	ra,0xffffd
    8000695e:	0aa080e7          	jalr	170(ra) # 80003a04 <argstr>
    80006962:	02054b63          	bltz	a0,80006998 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006966:	f6841683          	lh	a3,-152(s0)
    8000696a:	f6c41603          	lh	a2,-148(s0)
    8000696e:	458d                	li	a1,3
    80006970:	f7040513          	addi	a0,s0,-144
    80006974:	fffff097          	auipc	ra,0xfffff
    80006978:	77e080e7          	jalr	1918(ra) # 800060f2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000697c:	cd11                	beqz	a0,80006998 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000697e:	ffffe097          	auipc	ra,0xffffe
    80006982:	07e080e7          	jalr	126(ra) # 800049fc <iunlockput>
  end_op();
    80006986:	fffff097          	auipc	ra,0xfffff
    8000698a:	856080e7          	jalr	-1962(ra) # 800051dc <end_op>
  return 0;
    8000698e:	4501                	li	a0,0
}
    80006990:	60ea                	ld	ra,152(sp)
    80006992:	644a                	ld	s0,144(sp)
    80006994:	610d                	addi	sp,sp,160
    80006996:	8082                	ret
    end_op();
    80006998:	fffff097          	auipc	ra,0xfffff
    8000699c:	844080e7          	jalr	-1980(ra) # 800051dc <end_op>
    return -1;
    800069a0:	557d                	li	a0,-1
    800069a2:	b7fd                	j	80006990 <sys_mknod+0x6c>

00000000800069a4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800069a4:	7135                	addi	sp,sp,-160
    800069a6:	ed06                	sd	ra,152(sp)
    800069a8:	e922                	sd	s0,144(sp)
    800069aa:	e526                	sd	s1,136(sp)
    800069ac:	e14a                	sd	s2,128(sp)
    800069ae:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800069b0:	ffffb097          	auipc	ra,0xffffb
    800069b4:	452080e7          	jalr	1106(ra) # 80001e02 <myproc>
    800069b8:	892a                	mv	s2,a0
  
  begin_op();
    800069ba:	ffffe097          	auipc	ra,0xffffe
    800069be:	7a2080e7          	jalr	1954(ra) # 8000515c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800069c2:	08000613          	li	a2,128
    800069c6:	f6040593          	addi	a1,s0,-160
    800069ca:	4501                	li	a0,0
    800069cc:	ffffd097          	auipc	ra,0xffffd
    800069d0:	038080e7          	jalr	56(ra) # 80003a04 <argstr>
    800069d4:	04054b63          	bltz	a0,80006a2a <sys_chdir+0x86>
    800069d8:	f6040513          	addi	a0,s0,-160
    800069dc:	ffffe097          	auipc	ra,0xffffe
    800069e0:	564080e7          	jalr	1380(ra) # 80004f40 <namei>
    800069e4:	84aa                	mv	s1,a0
    800069e6:	c131                	beqz	a0,80006a2a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800069e8:	ffffe097          	auipc	ra,0xffffe
    800069ec:	db2080e7          	jalr	-590(ra) # 8000479a <ilock>
  if(ip->type != T_DIR){
    800069f0:	04449703          	lh	a4,68(s1)
    800069f4:	4785                	li	a5,1
    800069f6:	04f71063          	bne	a4,a5,80006a36 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800069fa:	8526                	mv	a0,s1
    800069fc:	ffffe097          	auipc	ra,0xffffe
    80006a00:	e60080e7          	jalr	-416(ra) # 8000485c <iunlock>
  iput(p->cwd);
    80006a04:	15093503          	ld	a0,336(s2)
    80006a08:	ffffe097          	auipc	ra,0xffffe
    80006a0c:	f4c080e7          	jalr	-180(ra) # 80004954 <iput>
  end_op();
    80006a10:	ffffe097          	auipc	ra,0xffffe
    80006a14:	7cc080e7          	jalr	1996(ra) # 800051dc <end_op>
  p->cwd = ip;
    80006a18:	14993823          	sd	s1,336(s2)
  return 0;
    80006a1c:	4501                	li	a0,0
}
    80006a1e:	60ea                	ld	ra,152(sp)
    80006a20:	644a                	ld	s0,144(sp)
    80006a22:	64aa                	ld	s1,136(sp)
    80006a24:	690a                	ld	s2,128(sp)
    80006a26:	610d                	addi	sp,sp,160
    80006a28:	8082                	ret
    end_op();
    80006a2a:	ffffe097          	auipc	ra,0xffffe
    80006a2e:	7b2080e7          	jalr	1970(ra) # 800051dc <end_op>
    return -1;
    80006a32:	557d                	li	a0,-1
    80006a34:	b7ed                	j	80006a1e <sys_chdir+0x7a>
    iunlockput(ip);
    80006a36:	8526                	mv	a0,s1
    80006a38:	ffffe097          	auipc	ra,0xffffe
    80006a3c:	fc4080e7          	jalr	-60(ra) # 800049fc <iunlockput>
    end_op();
    80006a40:	ffffe097          	auipc	ra,0xffffe
    80006a44:	79c080e7          	jalr	1948(ra) # 800051dc <end_op>
    return -1;
    80006a48:	557d                	li	a0,-1
    80006a4a:	bfd1                	j	80006a1e <sys_chdir+0x7a>

0000000080006a4c <sys_exec>:

uint64
sys_exec(void)
{
    80006a4c:	7145                	addi	sp,sp,-464
    80006a4e:	e786                	sd	ra,456(sp)
    80006a50:	e3a2                	sd	s0,448(sp)
    80006a52:	ff26                	sd	s1,440(sp)
    80006a54:	fb4a                	sd	s2,432(sp)
    80006a56:	f74e                	sd	s3,424(sp)
    80006a58:	f352                	sd	s4,416(sp)
    80006a5a:	ef56                	sd	s5,408(sp)
    80006a5c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006a5e:	e3840593          	addi	a1,s0,-456
    80006a62:	4505                	li	a0,1
    80006a64:	ffffd097          	auipc	ra,0xffffd
    80006a68:	f80080e7          	jalr	-128(ra) # 800039e4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006a6c:	08000613          	li	a2,128
    80006a70:	f4040593          	addi	a1,s0,-192
    80006a74:	4501                	li	a0,0
    80006a76:	ffffd097          	auipc	ra,0xffffd
    80006a7a:	f8e080e7          	jalr	-114(ra) # 80003a04 <argstr>
    80006a7e:	87aa                	mv	a5,a0
    return -1;
    80006a80:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006a82:	0c07c263          	bltz	a5,80006b46 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006a86:	10000613          	li	a2,256
    80006a8a:	4581                	li	a1,0
    80006a8c:	e4040513          	addi	a0,s0,-448
    80006a90:	ffffa097          	auipc	ra,0xffffa
    80006a94:	482080e7          	jalr	1154(ra) # 80000f12 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006a98:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006a9c:	89a6                	mv	s3,s1
    80006a9e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006aa0:	02000a13          	li	s4,32
    80006aa4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006aa8:	00391513          	slli	a0,s2,0x3
    80006aac:	e3040593          	addi	a1,s0,-464
    80006ab0:	e3843783          	ld	a5,-456(s0)
    80006ab4:	953e                	add	a0,a0,a5
    80006ab6:	ffffd097          	auipc	ra,0xffffd
    80006aba:	e70080e7          	jalr	-400(ra) # 80003926 <fetchaddr>
    80006abe:	02054a63          	bltz	a0,80006af2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006ac2:	e3043783          	ld	a5,-464(s0)
    80006ac6:	c3b9                	beqz	a5,80006b0c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006ac8:	ffffa097          	auipc	ra,0xffffa
    80006acc:	252080e7          	jalr	594(ra) # 80000d1a <kalloc>
    80006ad0:	85aa                	mv	a1,a0
    80006ad2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006ad6:	cd11                	beqz	a0,80006af2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006ad8:	6605                	lui	a2,0x1
    80006ada:	e3043503          	ld	a0,-464(s0)
    80006ade:	ffffd097          	auipc	ra,0xffffd
    80006ae2:	e9a080e7          	jalr	-358(ra) # 80003978 <fetchstr>
    80006ae6:	00054663          	bltz	a0,80006af2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006aea:	0905                	addi	s2,s2,1
    80006aec:	09a1                	addi	s3,s3,8
    80006aee:	fb491be3          	bne	s2,s4,80006aa4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006af2:	10048913          	addi	s2,s1,256
    80006af6:	6088                	ld	a0,0(s1)
    80006af8:	c531                	beqz	a0,80006b44 <sys_exec+0xf8>
    kfree(argv[i]);
    80006afa:	ffffa097          	auipc	ra,0xffffa
    80006afe:	098080e7          	jalr	152(ra) # 80000b92 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b02:	04a1                	addi	s1,s1,8
    80006b04:	ff2499e3          	bne	s1,s2,80006af6 <sys_exec+0xaa>
  return -1;
    80006b08:	557d                	li	a0,-1
    80006b0a:	a835                	j	80006b46 <sys_exec+0xfa>
      argv[i] = 0;
    80006b0c:	0a8e                	slli	s5,s5,0x3
    80006b0e:	fc040793          	addi	a5,s0,-64
    80006b12:	9abe                	add	s5,s5,a5
    80006b14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006b18:	e4040593          	addi	a1,s0,-448
    80006b1c:	f4040513          	addi	a0,s0,-192
    80006b20:	fffff097          	auipc	ra,0xfffff
    80006b24:	190080e7          	jalr	400(ra) # 80005cb0 <exec>
    80006b28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b2a:	10048993          	addi	s3,s1,256
    80006b2e:	6088                	ld	a0,0(s1)
    80006b30:	c901                	beqz	a0,80006b40 <sys_exec+0xf4>
    kfree(argv[i]);
    80006b32:	ffffa097          	auipc	ra,0xffffa
    80006b36:	060080e7          	jalr	96(ra) # 80000b92 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b3a:	04a1                	addi	s1,s1,8
    80006b3c:	ff3499e3          	bne	s1,s3,80006b2e <sys_exec+0xe2>
  return ret;
    80006b40:	854a                	mv	a0,s2
    80006b42:	a011                	j	80006b46 <sys_exec+0xfa>
  return -1;
    80006b44:	557d                	li	a0,-1
}
    80006b46:	60be                	ld	ra,456(sp)
    80006b48:	641e                	ld	s0,448(sp)
    80006b4a:	74fa                	ld	s1,440(sp)
    80006b4c:	795a                	ld	s2,432(sp)
    80006b4e:	79ba                	ld	s3,424(sp)
    80006b50:	7a1a                	ld	s4,416(sp)
    80006b52:	6afa                	ld	s5,408(sp)
    80006b54:	6179                	addi	sp,sp,464
    80006b56:	8082                	ret

0000000080006b58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006b58:	7139                	addi	sp,sp,-64
    80006b5a:	fc06                	sd	ra,56(sp)
    80006b5c:	f822                	sd	s0,48(sp)
    80006b5e:	f426                	sd	s1,40(sp)
    80006b60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006b62:	ffffb097          	auipc	ra,0xffffb
    80006b66:	2a0080e7          	jalr	672(ra) # 80001e02 <myproc>
    80006b6a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006b6c:	fd840593          	addi	a1,s0,-40
    80006b70:	4501                	li	a0,0
    80006b72:	ffffd097          	auipc	ra,0xffffd
    80006b76:	e72080e7          	jalr	-398(ra) # 800039e4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006b7a:	fc840593          	addi	a1,s0,-56
    80006b7e:	fd040513          	addi	a0,s0,-48
    80006b82:	fffff097          	auipc	ra,0xfffff
    80006b86:	dd6080e7          	jalr	-554(ra) # 80005958 <pipealloc>
    return -1;
    80006b8a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006b8c:	0c054463          	bltz	a0,80006c54 <sys_pipe+0xfc>
  fd0 = -1;
    80006b90:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006b94:	fd043503          	ld	a0,-48(s0)
    80006b98:	fffff097          	auipc	ra,0xfffff
    80006b9c:	518080e7          	jalr	1304(ra) # 800060b0 <fdalloc>
    80006ba0:	fca42223          	sw	a0,-60(s0)
    80006ba4:	08054b63          	bltz	a0,80006c3a <sys_pipe+0xe2>
    80006ba8:	fc843503          	ld	a0,-56(s0)
    80006bac:	fffff097          	auipc	ra,0xfffff
    80006bb0:	504080e7          	jalr	1284(ra) # 800060b0 <fdalloc>
    80006bb4:	fca42023          	sw	a0,-64(s0)
    80006bb8:	06054863          	bltz	a0,80006c28 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006bbc:	4691                	li	a3,4
    80006bbe:	fc440613          	addi	a2,s0,-60
    80006bc2:	fd843583          	ld	a1,-40(s0)
    80006bc6:	68a8                	ld	a0,80(s1)
    80006bc8:	ffffb097          	auipc	ra,0xffffb
    80006bcc:	cf4080e7          	jalr	-780(ra) # 800018bc <copyout>
    80006bd0:	02054063          	bltz	a0,80006bf0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006bd4:	4691                	li	a3,4
    80006bd6:	fc040613          	addi	a2,s0,-64
    80006bda:	fd843583          	ld	a1,-40(s0)
    80006bde:	0591                	addi	a1,a1,4
    80006be0:	68a8                	ld	a0,80(s1)
    80006be2:	ffffb097          	auipc	ra,0xffffb
    80006be6:	cda080e7          	jalr	-806(ra) # 800018bc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006bea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006bec:	06055463          	bgez	a0,80006c54 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006bf0:	fc442783          	lw	a5,-60(s0)
    80006bf4:	07e9                	addi	a5,a5,26
    80006bf6:	078e                	slli	a5,a5,0x3
    80006bf8:	97a6                	add	a5,a5,s1
    80006bfa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006bfe:	fc042503          	lw	a0,-64(s0)
    80006c02:	0569                	addi	a0,a0,26
    80006c04:	050e                	slli	a0,a0,0x3
    80006c06:	94aa                	add	s1,s1,a0
    80006c08:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006c0c:	fd043503          	ld	a0,-48(s0)
    80006c10:	fffff097          	auipc	ra,0xfffff
    80006c14:	a18080e7          	jalr	-1512(ra) # 80005628 <fileclose>
    fileclose(wf);
    80006c18:	fc843503          	ld	a0,-56(s0)
    80006c1c:	fffff097          	auipc	ra,0xfffff
    80006c20:	a0c080e7          	jalr	-1524(ra) # 80005628 <fileclose>
    return -1;
    80006c24:	57fd                	li	a5,-1
    80006c26:	a03d                	j	80006c54 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006c28:	fc442783          	lw	a5,-60(s0)
    80006c2c:	0007c763          	bltz	a5,80006c3a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006c30:	07e9                	addi	a5,a5,26
    80006c32:	078e                	slli	a5,a5,0x3
    80006c34:	94be                	add	s1,s1,a5
    80006c36:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006c3a:	fd043503          	ld	a0,-48(s0)
    80006c3e:	fffff097          	auipc	ra,0xfffff
    80006c42:	9ea080e7          	jalr	-1558(ra) # 80005628 <fileclose>
    fileclose(wf);
    80006c46:	fc843503          	ld	a0,-56(s0)
    80006c4a:	fffff097          	auipc	ra,0xfffff
    80006c4e:	9de080e7          	jalr	-1570(ra) # 80005628 <fileclose>
    return -1;
    80006c52:	57fd                	li	a5,-1
}
    80006c54:	853e                	mv	a0,a5
    80006c56:	70e2                	ld	ra,56(sp)
    80006c58:	7442                	ld	s0,48(sp)
    80006c5a:	74a2                	ld	s1,40(sp)
    80006c5c:	6121                	addi	sp,sp,64
    80006c5e:	8082                	ret

0000000080006c60 <kernelvec>:
    80006c60:	7111                	addi	sp,sp,-256
    80006c62:	e006                	sd	ra,0(sp)
    80006c64:	e40a                	sd	sp,8(sp)
    80006c66:	e80e                	sd	gp,16(sp)
    80006c68:	ec12                	sd	tp,24(sp)
    80006c6a:	f016                	sd	t0,32(sp)
    80006c6c:	f41a                	sd	t1,40(sp)
    80006c6e:	f81e                	sd	t2,48(sp)
    80006c70:	fc22                	sd	s0,56(sp)
    80006c72:	e0a6                	sd	s1,64(sp)
    80006c74:	e4aa                	sd	a0,72(sp)
    80006c76:	e8ae                	sd	a1,80(sp)
    80006c78:	ecb2                	sd	a2,88(sp)
    80006c7a:	f0b6                	sd	a3,96(sp)
    80006c7c:	f4ba                	sd	a4,104(sp)
    80006c7e:	f8be                	sd	a5,112(sp)
    80006c80:	fcc2                	sd	a6,120(sp)
    80006c82:	e146                	sd	a7,128(sp)
    80006c84:	e54a                	sd	s2,136(sp)
    80006c86:	e94e                	sd	s3,144(sp)
    80006c88:	ed52                	sd	s4,152(sp)
    80006c8a:	f156                	sd	s5,160(sp)
    80006c8c:	f55a                	sd	s6,168(sp)
    80006c8e:	f95e                	sd	s7,176(sp)
    80006c90:	fd62                	sd	s8,184(sp)
    80006c92:	e1e6                	sd	s9,192(sp)
    80006c94:	e5ea                	sd	s10,200(sp)
    80006c96:	e9ee                	sd	s11,208(sp)
    80006c98:	edf2                	sd	t3,216(sp)
    80006c9a:	f1f6                	sd	t4,224(sp)
    80006c9c:	f5fa                	sd	t5,232(sp)
    80006c9e:	f9fe                	sd	t6,240(sp)
    80006ca0:	b0bfc0ef          	jal	ra,800037aa <kerneltrap>
    80006ca4:	6082                	ld	ra,0(sp)
    80006ca6:	6122                	ld	sp,8(sp)
    80006ca8:	61c2                	ld	gp,16(sp)
    80006caa:	7282                	ld	t0,32(sp)
    80006cac:	7322                	ld	t1,40(sp)
    80006cae:	73c2                	ld	t2,48(sp)
    80006cb0:	7462                	ld	s0,56(sp)
    80006cb2:	6486                	ld	s1,64(sp)
    80006cb4:	6526                	ld	a0,72(sp)
    80006cb6:	65c6                	ld	a1,80(sp)
    80006cb8:	6666                	ld	a2,88(sp)
    80006cba:	7686                	ld	a3,96(sp)
    80006cbc:	7726                	ld	a4,104(sp)
    80006cbe:	77c6                	ld	a5,112(sp)
    80006cc0:	7866                	ld	a6,120(sp)
    80006cc2:	688a                	ld	a7,128(sp)
    80006cc4:	692a                	ld	s2,136(sp)
    80006cc6:	69ca                	ld	s3,144(sp)
    80006cc8:	6a6a                	ld	s4,152(sp)
    80006cca:	7a8a                	ld	s5,160(sp)
    80006ccc:	7b2a                	ld	s6,168(sp)
    80006cce:	7bca                	ld	s7,176(sp)
    80006cd0:	7c6a                	ld	s8,184(sp)
    80006cd2:	6c8e                	ld	s9,192(sp)
    80006cd4:	6d2e                	ld	s10,200(sp)
    80006cd6:	6dce                	ld	s11,208(sp)
    80006cd8:	6e6e                	ld	t3,216(sp)
    80006cda:	7e8e                	ld	t4,224(sp)
    80006cdc:	7f2e                	ld	t5,232(sp)
    80006cde:	7fce                	ld	t6,240(sp)
    80006ce0:	6111                	addi	sp,sp,256
    80006ce2:	10200073          	sret
    80006ce6:	00000013          	nop
    80006cea:	00000013          	nop
    80006cee:	0001                	nop

0000000080006cf0 <timervec>:
    80006cf0:	34051573          	csrrw	a0,mscratch,a0
    80006cf4:	e10c                	sd	a1,0(a0)
    80006cf6:	e510                	sd	a2,8(a0)
    80006cf8:	e914                	sd	a3,16(a0)
    80006cfa:	6d0c                	ld	a1,24(a0)
    80006cfc:	7110                	ld	a2,32(a0)
    80006cfe:	6194                	ld	a3,0(a1)
    80006d00:	96b2                	add	a3,a3,a2
    80006d02:	e194                	sd	a3,0(a1)
    80006d04:	4589                	li	a1,2
    80006d06:	14459073          	csrw	sip,a1
    80006d0a:	6914                	ld	a3,16(a0)
    80006d0c:	6510                	ld	a2,8(a0)
    80006d0e:	610c                	ld	a1,0(a0)
    80006d10:	34051573          	csrrw	a0,mscratch,a0
    80006d14:	30200073          	mret
	...

0000000080006d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006d1a:	1141                	addi	sp,sp,-16
    80006d1c:	e422                	sd	s0,8(sp)
    80006d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006d20:	0c0007b7          	lui	a5,0xc000
    80006d24:	4705                	li	a4,1
    80006d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006d28:	c3d8                	sw	a4,4(a5)
}
    80006d2a:	6422                	ld	s0,8(sp)
    80006d2c:	0141                	addi	sp,sp,16
    80006d2e:	8082                	ret

0000000080006d30 <plicinithart>:

void
plicinithart(void)
{
    80006d30:	1141                	addi	sp,sp,-16
    80006d32:	e406                	sd	ra,8(sp)
    80006d34:	e022                	sd	s0,0(sp)
    80006d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d38:	ffffb097          	auipc	ra,0xffffb
    80006d3c:	09e080e7          	jalr	158(ra) # 80001dd6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006d40:	0085171b          	slliw	a4,a0,0x8
    80006d44:	0c0027b7          	lui	a5,0xc002
    80006d48:	97ba                	add	a5,a5,a4
    80006d4a:	40200713          	li	a4,1026
    80006d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006d52:	00d5151b          	slliw	a0,a0,0xd
    80006d56:	0c2017b7          	lui	a5,0xc201
    80006d5a:	953e                	add	a0,a0,a5
    80006d5c:	00052023          	sw	zero,0(a0)
}
    80006d60:	60a2                	ld	ra,8(sp)
    80006d62:	6402                	ld	s0,0(sp)
    80006d64:	0141                	addi	sp,sp,16
    80006d66:	8082                	ret

0000000080006d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006d68:	1141                	addi	sp,sp,-16
    80006d6a:	e406                	sd	ra,8(sp)
    80006d6c:	e022                	sd	s0,0(sp)
    80006d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d70:	ffffb097          	auipc	ra,0xffffb
    80006d74:	066080e7          	jalr	102(ra) # 80001dd6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006d78:	00d5179b          	slliw	a5,a0,0xd
    80006d7c:	0c201537          	lui	a0,0xc201
    80006d80:	953e                	add	a0,a0,a5
  return irq;
}
    80006d82:	4148                	lw	a0,4(a0)
    80006d84:	60a2                	ld	ra,8(sp)
    80006d86:	6402                	ld	s0,0(sp)
    80006d88:	0141                	addi	sp,sp,16
    80006d8a:	8082                	ret

0000000080006d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006d8c:	1101                	addi	sp,sp,-32
    80006d8e:	ec06                	sd	ra,24(sp)
    80006d90:	e822                	sd	s0,16(sp)
    80006d92:	e426                	sd	s1,8(sp)
    80006d94:	1000                	addi	s0,sp,32
    80006d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006d98:	ffffb097          	auipc	ra,0xffffb
    80006d9c:	03e080e7          	jalr	62(ra) # 80001dd6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006da0:	00d5151b          	slliw	a0,a0,0xd
    80006da4:	0c2017b7          	lui	a5,0xc201
    80006da8:	97aa                	add	a5,a5,a0
    80006daa:	c3c4                	sw	s1,4(a5)
}
    80006dac:	60e2                	ld	ra,24(sp)
    80006dae:	6442                	ld	s0,16(sp)
    80006db0:	64a2                	ld	s1,8(sp)
    80006db2:	6105                	addi	sp,sp,32
    80006db4:	8082                	ret

0000000080006db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006db6:	1141                	addi	sp,sp,-16
    80006db8:	e406                	sd	ra,8(sp)
    80006dba:	e022                	sd	s0,0(sp)
    80006dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006dbe:	479d                	li	a5,7
    80006dc0:	04a7cc63          	blt	a5,a0,80006e18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006dc4:	00240797          	auipc	a5,0x240
    80006dc8:	46478793          	addi	a5,a5,1124 # 80247228 <disk>
    80006dcc:	97aa                	add	a5,a5,a0
    80006dce:	0187c783          	lbu	a5,24(a5)
    80006dd2:	ebb9                	bnez	a5,80006e28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006dd4:	00451613          	slli	a2,a0,0x4
    80006dd8:	00240797          	auipc	a5,0x240
    80006ddc:	45078793          	addi	a5,a5,1104 # 80247228 <disk>
    80006de0:	6394                	ld	a3,0(a5)
    80006de2:	96b2                	add	a3,a3,a2
    80006de4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006de8:	6398                	ld	a4,0(a5)
    80006dea:	9732                	add	a4,a4,a2
    80006dec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006df0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006df4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006df8:	953e                	add	a0,a0,a5
    80006dfa:	4785                	li	a5,1
    80006dfc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006e00:	00240517          	auipc	a0,0x240
    80006e04:	44050513          	addi	a0,a0,1088 # 80247240 <disk+0x18>
    80006e08:	ffffc097          	auipc	ra,0xffffc
    80006e0c:	018080e7          	jalr	24(ra) # 80002e20 <wakeup>
}
    80006e10:	60a2                	ld	ra,8(sp)
    80006e12:	6402                	ld	s0,0(sp)
    80006e14:	0141                	addi	sp,sp,16
    80006e16:	8082                	ret
    panic("free_desc 1");
    80006e18:	00003517          	auipc	a0,0x3
    80006e1c:	b3850513          	addi	a0,a0,-1224 # 80009950 <syscalls+0x318>
    80006e20:	ffff9097          	auipc	ra,0xffff9
    80006e24:	724080e7          	jalr	1828(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006e28:	00003517          	auipc	a0,0x3
    80006e2c:	b3850513          	addi	a0,a0,-1224 # 80009960 <syscalls+0x328>
    80006e30:	ffff9097          	auipc	ra,0xffff9
    80006e34:	714080e7          	jalr	1812(ra) # 80000544 <panic>

0000000080006e38 <virtio_disk_init>:
{
    80006e38:	1101                	addi	sp,sp,-32
    80006e3a:	ec06                	sd	ra,24(sp)
    80006e3c:	e822                	sd	s0,16(sp)
    80006e3e:	e426                	sd	s1,8(sp)
    80006e40:	e04a                	sd	s2,0(sp)
    80006e42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006e44:	00003597          	auipc	a1,0x3
    80006e48:	b2c58593          	addi	a1,a1,-1236 # 80009970 <syscalls+0x338>
    80006e4c:	00240517          	auipc	a0,0x240
    80006e50:	50450513          	addi	a0,a0,1284 # 80247350 <disk+0x128>
    80006e54:	ffffa097          	auipc	ra,0xffffa
    80006e58:	f32080e7          	jalr	-206(ra) # 80000d86 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e5c:	100017b7          	lui	a5,0x10001
    80006e60:	4398                	lw	a4,0(a5)
    80006e62:	2701                	sext.w	a4,a4
    80006e64:	747277b7          	lui	a5,0x74727
    80006e68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006e6c:	14f71e63          	bne	a4,a5,80006fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006e70:	100017b7          	lui	a5,0x10001
    80006e74:	43dc                	lw	a5,4(a5)
    80006e76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e78:	4709                	li	a4,2
    80006e7a:	14e79763          	bne	a5,a4,80006fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e7e:	100017b7          	lui	a5,0x10001
    80006e82:	479c                	lw	a5,8(a5)
    80006e84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006e86:	14e79163          	bne	a5,a4,80006fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006e8a:	100017b7          	lui	a5,0x10001
    80006e8e:	47d8                	lw	a4,12(a5)
    80006e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e92:	554d47b7          	lui	a5,0x554d4
    80006e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006e9a:	12f71763          	bne	a4,a5,80006fc8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e9e:	100017b7          	lui	a5,0x10001
    80006ea2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ea6:	4705                	li	a4,1
    80006ea8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006eaa:	470d                	li	a4,3
    80006eac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006eae:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006eb0:	c7ffe737          	lui	a4,0xc7ffe
    80006eb4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47db73f7>
    80006eb8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006eba:	2701                	sext.w	a4,a4
    80006ebc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ebe:	472d                	li	a4,11
    80006ec0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006ec2:	0707a903          	lw	s2,112(a5)
    80006ec6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006ec8:	00897793          	andi	a5,s2,8
    80006ecc:	10078663          	beqz	a5,80006fd8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006ed0:	100017b7          	lui	a5,0x10001
    80006ed4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006ed8:	43fc                	lw	a5,68(a5)
    80006eda:	2781                	sext.w	a5,a5
    80006edc:	10079663          	bnez	a5,80006fe8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ee0:	100017b7          	lui	a5,0x10001
    80006ee4:	5bdc                	lw	a5,52(a5)
    80006ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ee8:	10078863          	beqz	a5,80006ff8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006eec:	471d                	li	a4,7
    80006eee:	10f77d63          	bgeu	a4,a5,80007008 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006ef2:	ffffa097          	auipc	ra,0xffffa
    80006ef6:	e28080e7          	jalr	-472(ra) # 80000d1a <kalloc>
    80006efa:	00240497          	auipc	s1,0x240
    80006efe:	32e48493          	addi	s1,s1,814 # 80247228 <disk>
    80006f02:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006f04:	ffffa097          	auipc	ra,0xffffa
    80006f08:	e16080e7          	jalr	-490(ra) # 80000d1a <kalloc>
    80006f0c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006f0e:	ffffa097          	auipc	ra,0xffffa
    80006f12:	e0c080e7          	jalr	-500(ra) # 80000d1a <kalloc>
    80006f16:	87aa                	mv	a5,a0
    80006f18:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006f1a:	6088                	ld	a0,0(s1)
    80006f1c:	cd75                	beqz	a0,80007018 <virtio_disk_init+0x1e0>
    80006f1e:	00240717          	auipc	a4,0x240
    80006f22:	31273703          	ld	a4,786(a4) # 80247230 <disk+0x8>
    80006f26:	cb6d                	beqz	a4,80007018 <virtio_disk_init+0x1e0>
    80006f28:	cbe5                	beqz	a5,80007018 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006f2a:	6605                	lui	a2,0x1
    80006f2c:	4581                	li	a1,0
    80006f2e:	ffffa097          	auipc	ra,0xffffa
    80006f32:	fe4080e7          	jalr	-28(ra) # 80000f12 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006f36:	00240497          	auipc	s1,0x240
    80006f3a:	2f248493          	addi	s1,s1,754 # 80247228 <disk>
    80006f3e:	6605                	lui	a2,0x1
    80006f40:	4581                	li	a1,0
    80006f42:	6488                	ld	a0,8(s1)
    80006f44:	ffffa097          	auipc	ra,0xffffa
    80006f48:	fce080e7          	jalr	-50(ra) # 80000f12 <memset>
  memset(disk.used, 0, PGSIZE);
    80006f4c:	6605                	lui	a2,0x1
    80006f4e:	4581                	li	a1,0
    80006f50:	6888                	ld	a0,16(s1)
    80006f52:	ffffa097          	auipc	ra,0xffffa
    80006f56:	fc0080e7          	jalr	-64(ra) # 80000f12 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006f5a:	100017b7          	lui	a5,0x10001
    80006f5e:	4721                	li	a4,8
    80006f60:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006f62:	4098                	lw	a4,0(s1)
    80006f64:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006f68:	40d8                	lw	a4,4(s1)
    80006f6a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006f6e:	6498                	ld	a4,8(s1)
    80006f70:	0007069b          	sext.w	a3,a4
    80006f74:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006f78:	9701                	srai	a4,a4,0x20
    80006f7a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006f7e:	6898                	ld	a4,16(s1)
    80006f80:	0007069b          	sext.w	a3,a4
    80006f84:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006f88:	9701                	srai	a4,a4,0x20
    80006f8a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006f8e:	4685                	li	a3,1
    80006f90:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006f92:	4705                	li	a4,1
    80006f94:	00d48c23          	sb	a3,24(s1)
    80006f98:	00e48ca3          	sb	a4,25(s1)
    80006f9c:	00e48d23          	sb	a4,26(s1)
    80006fa0:	00e48da3          	sb	a4,27(s1)
    80006fa4:	00e48e23          	sb	a4,28(s1)
    80006fa8:	00e48ea3          	sb	a4,29(s1)
    80006fac:	00e48f23          	sb	a4,30(s1)
    80006fb0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006fb4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006fb8:	0727a823          	sw	s2,112(a5)
}
    80006fbc:	60e2                	ld	ra,24(sp)
    80006fbe:	6442                	ld	s0,16(sp)
    80006fc0:	64a2                	ld	s1,8(sp)
    80006fc2:	6902                	ld	s2,0(sp)
    80006fc4:	6105                	addi	sp,sp,32
    80006fc6:	8082                	ret
    panic("could not find virtio disk");
    80006fc8:	00003517          	auipc	a0,0x3
    80006fcc:	9b850513          	addi	a0,a0,-1608 # 80009980 <syscalls+0x348>
    80006fd0:	ffff9097          	auipc	ra,0xffff9
    80006fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006fd8:	00003517          	auipc	a0,0x3
    80006fdc:	9c850513          	addi	a0,a0,-1592 # 800099a0 <syscalls+0x368>
    80006fe0:	ffff9097          	auipc	ra,0xffff9
    80006fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006fe8:	00003517          	auipc	a0,0x3
    80006fec:	9d850513          	addi	a0,a0,-1576 # 800099c0 <syscalls+0x388>
    80006ff0:	ffff9097          	auipc	ra,0xffff9
    80006ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006ff8:	00003517          	auipc	a0,0x3
    80006ffc:	9e850513          	addi	a0,a0,-1560 # 800099e0 <syscalls+0x3a8>
    80007000:	ffff9097          	auipc	ra,0xffff9
    80007004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80007008:	00003517          	auipc	a0,0x3
    8000700c:	9f850513          	addi	a0,a0,-1544 # 80009a00 <syscalls+0x3c8>
    80007010:	ffff9097          	auipc	ra,0xffff9
    80007014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80007018:	00003517          	auipc	a0,0x3
    8000701c:	a0850513          	addi	a0,a0,-1528 # 80009a20 <syscalls+0x3e8>
    80007020:	ffff9097          	auipc	ra,0xffff9
    80007024:	524080e7          	jalr	1316(ra) # 80000544 <panic>

0000000080007028 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80007028:	7159                	addi	sp,sp,-112
    8000702a:	f486                	sd	ra,104(sp)
    8000702c:	f0a2                	sd	s0,96(sp)
    8000702e:	eca6                	sd	s1,88(sp)
    80007030:	e8ca                	sd	s2,80(sp)
    80007032:	e4ce                	sd	s3,72(sp)
    80007034:	e0d2                	sd	s4,64(sp)
    80007036:	fc56                	sd	s5,56(sp)
    80007038:	f85a                	sd	s6,48(sp)
    8000703a:	f45e                	sd	s7,40(sp)
    8000703c:	f062                	sd	s8,32(sp)
    8000703e:	ec66                	sd	s9,24(sp)
    80007040:	e86a                	sd	s10,16(sp)
    80007042:	1880                	addi	s0,sp,112
    80007044:	892a                	mv	s2,a0
    80007046:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007048:	00c52c83          	lw	s9,12(a0)
    8000704c:	001c9c9b          	slliw	s9,s9,0x1
    80007050:	1c82                	slli	s9,s9,0x20
    80007052:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007056:	00240517          	auipc	a0,0x240
    8000705a:	2fa50513          	addi	a0,a0,762 # 80247350 <disk+0x128>
    8000705e:	ffffa097          	auipc	ra,0xffffa
    80007062:	db8080e7          	jalr	-584(ra) # 80000e16 <acquire>
  for(int i = 0; i < 3; i++){
    80007066:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007068:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000706a:	00240b17          	auipc	s6,0x240
    8000706e:	1beb0b13          	addi	s6,s6,446 # 80247228 <disk>
  for(int i = 0; i < 3; i++){
    80007072:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80007074:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007076:	00240c17          	auipc	s8,0x240
    8000707a:	2dac0c13          	addi	s8,s8,730 # 80247350 <disk+0x128>
    8000707e:	a8b5                	j	800070fa <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80007080:	00fb06b3          	add	a3,s6,a5
    80007084:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80007088:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000708a:	0207c563          	bltz	a5,800070b4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000708e:	2485                	addiw	s1,s1,1
    80007090:	0711                	addi	a4,a4,4
    80007092:	1f548a63          	beq	s1,s5,80007286 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80007096:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80007098:	00240697          	auipc	a3,0x240
    8000709c:	19068693          	addi	a3,a3,400 # 80247228 <disk>
    800070a0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800070a2:	0186c583          	lbu	a1,24(a3)
    800070a6:	fde9                	bnez	a1,80007080 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800070a8:	2785                	addiw	a5,a5,1
    800070aa:	0685                	addi	a3,a3,1
    800070ac:	ff779be3          	bne	a5,s7,800070a2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800070b0:	57fd                	li	a5,-1
    800070b2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800070b4:	02905a63          	blez	s1,800070e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800070b8:	f9042503          	lw	a0,-112(s0)
    800070bc:	00000097          	auipc	ra,0x0
    800070c0:	cfa080e7          	jalr	-774(ra) # 80006db6 <free_desc>
      for(int j = 0; j < i; j++)
    800070c4:	4785                	li	a5,1
    800070c6:	0297d163          	bge	a5,s1,800070e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800070ca:	f9442503          	lw	a0,-108(s0)
    800070ce:	00000097          	auipc	ra,0x0
    800070d2:	ce8080e7          	jalr	-792(ra) # 80006db6 <free_desc>
      for(int j = 0; j < i; j++)
    800070d6:	4789                	li	a5,2
    800070d8:	0097d863          	bge	a5,s1,800070e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800070dc:	f9842503          	lw	a0,-104(s0)
    800070e0:	00000097          	auipc	ra,0x0
    800070e4:	cd6080e7          	jalr	-810(ra) # 80006db6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800070e8:	85e2                	mv	a1,s8
    800070ea:	00240517          	auipc	a0,0x240
    800070ee:	15650513          	addi	a0,a0,342 # 80247240 <disk+0x18>
    800070f2:	ffffc097          	auipc	ra,0xffffc
    800070f6:	a52080e7          	jalr	-1454(ra) # 80002b44 <sleep>
  for(int i = 0; i < 3; i++){
    800070fa:	f9040713          	addi	a4,s0,-112
    800070fe:	84ce                	mv	s1,s3
    80007100:	bf59                	j	80007096 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80007102:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80007106:	00479693          	slli	a3,a5,0x4
    8000710a:	00240797          	auipc	a5,0x240
    8000710e:	11e78793          	addi	a5,a5,286 # 80247228 <disk>
    80007112:	97b6                	add	a5,a5,a3
    80007114:	4685                	li	a3,1
    80007116:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80007118:	00240597          	auipc	a1,0x240
    8000711c:	11058593          	addi	a1,a1,272 # 80247228 <disk>
    80007120:	00a60793          	addi	a5,a2,10
    80007124:	0792                	slli	a5,a5,0x4
    80007126:	97ae                	add	a5,a5,a1
    80007128:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000712c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80007130:	f6070693          	addi	a3,a4,-160
    80007134:	619c                	ld	a5,0(a1)
    80007136:	97b6                	add	a5,a5,a3
    80007138:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000713a:	6188                	ld	a0,0(a1)
    8000713c:	96aa                	add	a3,a3,a0
    8000713e:	47c1                	li	a5,16
    80007140:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80007142:	4785                	li	a5,1
    80007144:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80007148:	f9442783          	lw	a5,-108(s0)
    8000714c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007150:	0792                	slli	a5,a5,0x4
    80007152:	953e                	add	a0,a0,a5
    80007154:	05890693          	addi	a3,s2,88
    80007158:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000715a:	6188                	ld	a0,0(a1)
    8000715c:	97aa                	add	a5,a5,a0
    8000715e:	40000693          	li	a3,1024
    80007162:	c794                	sw	a3,8(a5)
  if(write)
    80007164:	100d0d63          	beqz	s10,8000727e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80007168:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000716c:	00c7d683          	lhu	a3,12(a5)
    80007170:	0016e693          	ori	a3,a3,1
    80007174:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80007178:	f9842583          	lw	a1,-104(s0)
    8000717c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007180:	00240697          	auipc	a3,0x240
    80007184:	0a868693          	addi	a3,a3,168 # 80247228 <disk>
    80007188:	00260793          	addi	a5,a2,2
    8000718c:	0792                	slli	a5,a5,0x4
    8000718e:	97b6                	add	a5,a5,a3
    80007190:	587d                	li	a6,-1
    80007192:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007196:	0592                	slli	a1,a1,0x4
    80007198:	952e                	add	a0,a0,a1
    8000719a:	f9070713          	addi	a4,a4,-112
    8000719e:	9736                	add	a4,a4,a3
    800071a0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800071a2:	6298                	ld	a4,0(a3)
    800071a4:	972e                	add	a4,a4,a1
    800071a6:	4585                	li	a1,1
    800071a8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800071aa:	4509                	li	a0,2
    800071ac:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800071b0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800071b4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800071b8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800071bc:	6698                	ld	a4,8(a3)
    800071be:	00275783          	lhu	a5,2(a4)
    800071c2:	8b9d                	andi	a5,a5,7
    800071c4:	0786                	slli	a5,a5,0x1
    800071c6:	97ba                	add	a5,a5,a4
    800071c8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800071cc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800071d0:	6698                	ld	a4,8(a3)
    800071d2:	00275783          	lhu	a5,2(a4)
    800071d6:	2785                	addiw	a5,a5,1
    800071d8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800071dc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800071e0:	100017b7          	lui	a5,0x10001
    800071e4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800071e8:	00492703          	lw	a4,4(s2)
    800071ec:	4785                	li	a5,1
    800071ee:	02f71163          	bne	a4,a5,80007210 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800071f2:	00240997          	auipc	s3,0x240
    800071f6:	15e98993          	addi	s3,s3,350 # 80247350 <disk+0x128>
  while(b->disk == 1) {
    800071fa:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800071fc:	85ce                	mv	a1,s3
    800071fe:	854a                	mv	a0,s2
    80007200:	ffffc097          	auipc	ra,0xffffc
    80007204:	944080e7          	jalr	-1724(ra) # 80002b44 <sleep>
  while(b->disk == 1) {
    80007208:	00492783          	lw	a5,4(s2)
    8000720c:	fe9788e3          	beq	a5,s1,800071fc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80007210:	f9042903          	lw	s2,-112(s0)
    80007214:	00290793          	addi	a5,s2,2
    80007218:	00479713          	slli	a4,a5,0x4
    8000721c:	00240797          	auipc	a5,0x240
    80007220:	00c78793          	addi	a5,a5,12 # 80247228 <disk>
    80007224:	97ba                	add	a5,a5,a4
    80007226:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000722a:	00240997          	auipc	s3,0x240
    8000722e:	ffe98993          	addi	s3,s3,-2 # 80247228 <disk>
    80007232:	00491713          	slli	a4,s2,0x4
    80007236:	0009b783          	ld	a5,0(s3)
    8000723a:	97ba                	add	a5,a5,a4
    8000723c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007240:	854a                	mv	a0,s2
    80007242:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80007246:	00000097          	auipc	ra,0x0
    8000724a:	b70080e7          	jalr	-1168(ra) # 80006db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000724e:	8885                	andi	s1,s1,1
    80007250:	f0ed                	bnez	s1,80007232 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80007252:	00240517          	auipc	a0,0x240
    80007256:	0fe50513          	addi	a0,a0,254 # 80247350 <disk+0x128>
    8000725a:	ffffa097          	auipc	ra,0xffffa
    8000725e:	c70080e7          	jalr	-912(ra) # 80000eca <release>
}
    80007262:	70a6                	ld	ra,104(sp)
    80007264:	7406                	ld	s0,96(sp)
    80007266:	64e6                	ld	s1,88(sp)
    80007268:	6946                	ld	s2,80(sp)
    8000726a:	69a6                	ld	s3,72(sp)
    8000726c:	6a06                	ld	s4,64(sp)
    8000726e:	7ae2                	ld	s5,56(sp)
    80007270:	7b42                	ld	s6,48(sp)
    80007272:	7ba2                	ld	s7,40(sp)
    80007274:	7c02                	ld	s8,32(sp)
    80007276:	6ce2                	ld	s9,24(sp)
    80007278:	6d42                	ld	s10,16(sp)
    8000727a:	6165                	addi	sp,sp,112
    8000727c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000727e:	4689                	li	a3,2
    80007280:	00d79623          	sh	a3,12(a5)
    80007284:	b5e5                	j	8000716c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80007286:	f9042603          	lw	a2,-112(s0)
    8000728a:	00a60713          	addi	a4,a2,10
    8000728e:	0712                	slli	a4,a4,0x4
    80007290:	00240517          	auipc	a0,0x240
    80007294:	fa050513          	addi	a0,a0,-96 # 80247230 <disk+0x8>
    80007298:	953a                	add	a0,a0,a4
  if(write)
    8000729a:	e60d14e3          	bnez	s10,80007102 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000729e:	00a60793          	addi	a5,a2,10
    800072a2:	00479693          	slli	a3,a5,0x4
    800072a6:	00240797          	auipc	a5,0x240
    800072aa:	f8278793          	addi	a5,a5,-126 # 80247228 <disk>
    800072ae:	97b6                	add	a5,a5,a3
    800072b0:	0007a423          	sw	zero,8(a5)
    800072b4:	b595                	j	80007118 <virtio_disk_rw+0xf0>

00000000800072b6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800072b6:	1101                	addi	sp,sp,-32
    800072b8:	ec06                	sd	ra,24(sp)
    800072ba:	e822                	sd	s0,16(sp)
    800072bc:	e426                	sd	s1,8(sp)
    800072be:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800072c0:	00240497          	auipc	s1,0x240
    800072c4:	f6848493          	addi	s1,s1,-152 # 80247228 <disk>
    800072c8:	00240517          	auipc	a0,0x240
    800072cc:	08850513          	addi	a0,a0,136 # 80247350 <disk+0x128>
    800072d0:	ffffa097          	auipc	ra,0xffffa
    800072d4:	b46080e7          	jalr	-1210(ra) # 80000e16 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800072d8:	10001737          	lui	a4,0x10001
    800072dc:	533c                	lw	a5,96(a4)
    800072de:	8b8d                	andi	a5,a5,3
    800072e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800072e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800072e6:	689c                	ld	a5,16(s1)
    800072e8:	0204d703          	lhu	a4,32(s1)
    800072ec:	0027d783          	lhu	a5,2(a5)
    800072f0:	04f70863          	beq	a4,a5,80007340 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800072f4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800072f8:	6898                	ld	a4,16(s1)
    800072fa:	0204d783          	lhu	a5,32(s1)
    800072fe:	8b9d                	andi	a5,a5,7
    80007300:	078e                	slli	a5,a5,0x3
    80007302:	97ba                	add	a5,a5,a4
    80007304:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007306:	00278713          	addi	a4,a5,2
    8000730a:	0712                	slli	a4,a4,0x4
    8000730c:	9726                	add	a4,a4,s1
    8000730e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80007312:	e721                	bnez	a4,8000735a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80007314:	0789                	addi	a5,a5,2
    80007316:	0792                	slli	a5,a5,0x4
    80007318:	97a6                	add	a5,a5,s1
    8000731a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000731c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80007320:	ffffc097          	auipc	ra,0xffffc
    80007324:	b00080e7          	jalr	-1280(ra) # 80002e20 <wakeup>

    disk.used_idx += 1;
    80007328:	0204d783          	lhu	a5,32(s1)
    8000732c:	2785                	addiw	a5,a5,1
    8000732e:	17c2                	slli	a5,a5,0x30
    80007330:	93c1                	srli	a5,a5,0x30
    80007332:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007336:	6898                	ld	a4,16(s1)
    80007338:	00275703          	lhu	a4,2(a4)
    8000733c:	faf71ce3          	bne	a4,a5,800072f4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80007340:	00240517          	auipc	a0,0x240
    80007344:	01050513          	addi	a0,a0,16 # 80247350 <disk+0x128>
    80007348:	ffffa097          	auipc	ra,0xffffa
    8000734c:	b82080e7          	jalr	-1150(ra) # 80000eca <release>
}
    80007350:	60e2                	ld	ra,24(sp)
    80007352:	6442                	ld	s0,16(sp)
    80007354:	64a2                	ld	s1,8(sp)
    80007356:	6105                	addi	sp,sp,32
    80007358:	8082                	ret
      panic("virtio_disk_intr status");
    8000735a:	00002517          	auipc	a0,0x2
    8000735e:	6de50513          	addi	a0,a0,1758 # 80009a38 <syscalls+0x400>
    80007362:	ffff9097          	auipc	ra,0xffff9
    80007366:	1e2080e7          	jalr	482(ra) # 80000544 <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
