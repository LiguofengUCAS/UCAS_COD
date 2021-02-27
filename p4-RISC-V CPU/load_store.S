


.text
main:
   lui	sp,0x4
   j	continued
   nop

continued:
   jal	ra,start
   jal	ra,hit_good_trap

_halt:
  lui	a5,0x0
  sw	a0,12(a5) # c <global_result>

_halt_j:
  j	_halt_j

nemu_assert:
  bnez	a0,reset
  lui	a5,0x0
  li	a4,1
  sw	a4,12(a5) # c <global_result>

nemu_j:
  j	nemu_j

reset:
  ret

hit_good_trap:
  lui	a5,0x0
  sw	zero,12(a5) # c <global_result>

good_j:
  j	good_j

start:
  addi	sp,sp,-32 # 3fe0 <sh_ans+0x3d78>
  sw	s0,24(sp)
  sw	s1,20(sp)
  li	s1,516
  sw	s2,16(sp)
  sw	s3,12(sp)
  sw	s4,8(sp)
  li	s2,516
  sw	ra,28(sp)
  addi	s3,s1,20
  addi	s4,s1,16
  li	s0,516

loop1:
  lh	a0,0(s0)
  lw	a5,0(s3)
  addi	s0,s0,2
  addi	s3,s3,4
  sub	a0,a0,a5
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  bne	s0,s4,loop1
  addi	s0,s2,52

loop2:
  lhu	a0,0(s1)
  lw	a5,0(s0)
  addi	s1,s1,2
  addi	s0,s0,4
  sub	a0,a0,a5
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  bne	s1,s4,loop2
  lbu	a4,2(s2)
  lbu	a3,1(s2)
  lbu	a5,3(s2)
  lbu	a0,4(s2)
  slli	a4,a4,0x8
  or	a4,a4,a3
  slli	a5,a5,0x10
  lw	a3,84(s2)
  or	a5,a5,a4
  slli	a0,a0,0x18
  or	a0,a0,a5
  sub	a0,a3,a0
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  lbu	a4,6(s2)
  lbu	a3,5(s2)
  lbu	a5,7(s2)
  lbu	a0,8(s2)
  slli	a4,a4,0x8
  or	a4,a4,a3
  slli	a5,a5,0x10
  lw	a3,88(s2)
  or	a5,a5,a4
  slli	a0,a0,0x18
  or	a0,a0,a5
  sub	a0,a3,a0
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  lbu	a4,10(s2)
  lbu	a3,9(s2)
  lbu	a5,11(s2)
  lbu	a0,12(s2)
  slli	a4,a4,0x8
  or	a4,a4,a3
  slli	a5,a5,0x10
  lw	a3,92(s2)
  or	a5,a5,a4
  slli	a0,a0,0x18
  or	a0,a0,a5
  sub	a0,a0,a3
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  lbu	a4,14(s2)
  lbu	a3,13(s2)
  lbu	a5,15(s2)
  lbu	a0,16(s2)
  slli	a4,a4,0x8
  or	a4,a4,a3
  slli	a5,a5,0x10
  lw	a3,96(s2)
  or	a5,a5,a4
  slli	a0,a0,0x18
  or	a0,a0,a5
  sub	a0,a3,a0
  sltiu	a0,a0, 0x0
  jal	ra,nemu_assert
  addi	s1,s2,100
  li	s0,1
  li	s4,1
  li	s3,17

loop3:
  sll	a5,s4,s0
  lw	a0,0(s1)
  not	a5,a5
  slli	a5,a5,0x10
  srli	a5,a5,0x10
  add	a4,s2,s0
  sub	a0,a0,a5
  addi	s0,s0,2
  sltiu	a0,a0, 0x0
  sh	a5,-1(a4)
  addi	s1,s1,4
  jal	ra,nemu_assert
  bne	s0,s3,loop3
  lw	ra,28(sp)
  lw	s0,24(sp)
  lw	s1,20(sp)
  lw	s2,16(sp)
  lw	s3,12(sp)
  lw	s4,8(sp)
  li	a0,0
  addi	sp,sp,32
  ret

