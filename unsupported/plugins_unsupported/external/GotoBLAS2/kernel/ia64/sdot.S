/*********************************************************************/
/*                                                                   */
/*             Optimized BLAS libraries                              */
/*                     By Kazushige Goto <kgoto@tacc.utexas.edu>     */
/*                                                                   */
/* Copyright (c) The University of Texas, 2009. All rights reserved. */
/* UNIVERSITY EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES CONCERNING  */
/* THIS SOFTWARE AND DOCUMENTATION, INCLUDING ANY WARRANTIES OF      */
/* MERCHANTABILITY, FITNESS FOR ANY PARTICULAR PURPOSE,              */
/* NON-INFRINGEMENT AND WARRANTIES OF PERFORMANCE, AND ANY WARRANTY  */
/* THAT MIGHT OTHERWISE ARISE FROM COURSE OF DEALING OR USAGE OF     */
/* TRADE. NO WARRANTY IS EITHER EXPRESS OR IMPLIED WITH RESPECT TO   */
/* THE USE OF THE SOFTWARE OR DOCUMENTATION.                         */
/* Under no circumstances shall University be liable for incidental, */
/* special, indirect, direct or consequential damages or loss of     */
/* profits, interruption of business, or related expenses which may  */
/* arise from use of Software or Documentation, including but not    */
/* limited to those resulting from defects in Software and/or        */
/* Documentation, or loss or inaccuracy of data of any kind.         */
/*********************************************************************/

#define ASSEMBLER
#include "common.h"

#define PREFETCH_SIZE (8 * 16 + 4)

#define N	r32
#define X1	r33
#define INCX	r34
#define Y1	r35
#define INCY	r36

#define PREX	r2
#define PREY	r3

#define I	r14
#define J	r15
#define Y2	r16
#define X2	r17
#define INCX16	r18
#define INCY16	r19
#define INCX5	r20
#define INCY5	r21
#define YY	r22
#define XA	r23
#define YA	r24
#define XX	r25

#define PR	r30
#define ARLC	r31

	PROLOGUE
	.prologue
	PROFCODE
	{ .mfi
	nop.m 0
	mov	f8  = f0
	.save ar.lc, ARLC
	mov	ARLC = ar.lc
	}
	{ .mfi
	mov	r26 = 1
	mov	f9  = f0
	shr  XA = X1, 3
	}
	;;
	.body
#ifdef F_INTERFACE
	LDINT	N    = [N]
	LDINT	INCX = [INCX]
	LDINT	INCY = [INCY]
	;;
#ifndef USE64BITINT
	sxt4	N    = N
	sxt4	INCX = INCX
	sxt4	INCY = INCY
	;;
#endif

	cmp.le	p0, p6 = r0, INCX
	cmp.le	p0, p7 = r0, INCY
	sub	r26 = r26, N
	;;
	setf.sig f32 = r26
	setf.sig f33 = INCX
	setf.sig f34 = INCY
	;;
	xmpy.l f33 = f32, f33
	xmpy.l f34 = f32, f34
	;;
	getf.sig r26 = f33
	getf.sig r27 = f34
	;;
	(p6) shladd X1 = r26, BASE_SHIFT, X1
	(p7) shladd Y1 = r27, BASE_SHIFT, Y1
	;;
#endif
	{ .mfi
	shladd	INCX = INCX, BASE_SHIFT, r0
	mov	f32 = f0
	mov	PR = pr
	}
	{ .mfb
	cmp.lt	p0, p6 = r0, N
	mov	f80 = f0
	(p6) br.ret.sptk.many b0
	}
	;;
	{ .mfi
	shladd	INCY = INCY, BASE_SHIFT, r0
	mov	f10 = f0
	tbit.nz	p15, p0 = X1, BASE_SHIFT
	}
	{ .mfb
	cmp.ne	p6, p0 = SIZE, INCX
	mov	f11 = f0
	(p6) br.cond.dptk .L100
	}
	;;
	{ .mfi
	(p15) LDFD f32 = [X1], INCX
	mov	f12 = f0
	mov	pr.rot= 0
	}
	{ .mfi
	(p15) adds N = -1, N
	mov	f13 = f0
	shr  YA = Y1, 3
	}
	;;
	{ .mfi
	(p15) LDFD f80 = [Y1], INCY
	mov	f14 = f0
	shr	I =  N, 4
	}
	{ .mmi
	and	J =  15, N
	and  XA = 0x1f, XA
	and  YA = 0x1f, YA
	}
	;;
	{ .mmi
	shladd	INCX5 = INCX, 2, INCX
	shladd	INCY5 = INCY, 2, INCY
	sub	XA = YA, XA
	}
	{ .mmi
	shladd	INCX16 = INCX, 4, r0
	shladd	INCY16 = INCY, 4, r0
	tbit.z	p0, p12 = N, 3
	}
	;;
	{ .mmi
	shladd	Y2 = INCY, 2, Y1
	cmp.eq	p7, p0  =   r0, J
	mov	ar.ec= 3
	}
	{ .mmi
	adds	I = -1, I
	cmp.ge	p8, p0 = 4, XA
	cmp.eq	p16, p0 = r0, r0
	}
	;;
	{ .mbb
	cmp.le	p9, p0 = 24, XA
	(p8)  br.cond.dpnt  .L20
	(p9)  br.cond.dpnt  .L20
	}
	;;
	{ .mmi
	adds	PREX = PREFETCH_SIZE * SIZE, X1
	adds	PREY = (PREFETCH_SIZE + 6) * SIZE, Y1
	mov	ar.lc = I
	}
	{ .mfb
	cmp.eq	p6 ,p0  =   -1, I
	FMA  f15 = f32, f80, f0
	(p6) br.cond.dpnt  .L15
	}
	;;
	.align 32

/* INCX == 1 && X is aligned */
.L12:
	{ .mmf
	(p16) LDFPD	f32, f35  = [X1], 2 * SIZE
	(p16) lfetch.nt1 [PREX], INCX16
	(p18) FMA	f8  = f34, f82,  f8
	}
	{ .mmf
	(p16) LDFD	f80 = [Y1], INCY
	(p16) LDFD	f92 = [Y2], INCY
	(p18) FMA	f9  = f37, f85,  f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f38,  f41  = [X1], 2 * SIZE
	(p16) lfetch.nt1 [PREY], INCY16
	(p18) FMA	f10 = f40, f88,  f10
	}
	{ .mmf
	(p16) LDFD	f83  = [Y1], INCY
	(p16) LDFD	f95  = [Y2], INCY
	(p18) FMA	f11 = f43, f91,  f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f44,  f47  = [X1], 2 * SIZE
	(p18) FMA	f12 = f46, f94,  f12
	}
	{ .mmf
	(p16) LDFD	f86  = [Y1], INCY
	(p16) LDFD	f98  = [Y2], INCY
	(p18) FMA	f13 = f49, f97,  f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f50,  f53  = [X1], 2 * SIZE
	(p18) FMA	f14 = f52, f100,  f14
	}
	{ .mmf
	(p16) LDFD	f89  = [Y1], INCY5
	(p16) LDFD	f101 = [Y2], INCY5
	(p18) FMA	f15 = f55, f103, f15
	}
	;;
	{ .mmf
	(p16) LDFPD	f56,  f59  = [X1], 2 * SIZE
	(p18) FMA	f8  = f58, f106, f8
	}
	{ .mmf
	(p16) LDFD	f104 = [Y1], INCY
	(p16) LDFD	f116 = [Y2], INCY
	(p18) FMA	f9   = f61, f109, f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f62,  f65  = [X1], 2 * SIZE
	(p18) FMA	f10 = f64, f112, f10
	}
	{ .mmf
	(p16) LDFD	f107 = [Y1], INCY
	(p16) LDFD	f119 = [Y2], INCY
	(p18) FMA	f11 = f67, f115, f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f68,  f71  = [X1], 2 * SIZE
	(p18) FMA	f12 = f70, f118, f12
	}
	{ .mmf
	(p16) LDFD	f110 = [Y1], INCY
	(p16) LDFD	f122 = [Y2], INCY
	(p18) FMA	f13 = f73, f121, f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f74,  f77  = [X1], 2 * SIZE
	(p16) LDFD	f113 = [Y1], INCY5
	(p18) FMA	f14 = f76, f124, f14
	}
	{ .mfb
	(p16) LDFD	f125 = [Y2], INCY5
	(p18) FMA	f15 = f79, f127, f15
	br.ctop.sptk.few .L12
	}
	;;
	.align 32

.L15:
	{ .mmi
	(p12) LDFPD	f32, f33  = [X1], 2 * SIZE
	mov	YY = Y1
	tbit.z	p0, p13 = N, 2
	}
	{ .mmb
	(p12) LDFD	f34 = [Y1], INCY
	(p12) LDFD	f42 = [Y2], INCY
	(p7) br.cond.dptk .L999
	}
	;;
	{ .mmi
	(p12) LDFPD	f36, f37  = [X1], 2 * SIZE
	(p12) shladd YY = INCY, 3, YY
	tbit.z	p0, p14 = N, 1
	}
	{ .mmi
	(p12) LDFD	f35 = [Y1], INCY
	(p12) LDFD	f43 = [Y2], INCY
	tbit.z	p0, p15 = N, 0
	}
	;;
	{ .mmi
	(p12) LDFPD	f40, f41  = [X1], 2 * SIZE
	(p13) shladd YY = INCY, 2, YY
	}
	{ .mmi
	(p12) LDFD	f38 = [Y1], INCY
	(p12) LDFD	f46 = [Y2], INCY
	}
	;;
	(p12) LDFPD	f44, f45  = [X1], 2 * SIZE
	(p12) LDFD	f39 = [Y1], INCY5
	(p12) LDFD	f47 = [Y2], INCY5
	;;
	(p13) LDFPD	f48, f49  = [X1], 2 * SIZE
	(p13) LDFD	f50 = [Y1], INCY
	(p14) LDFD	f58 = [YY], INCY
	;;
	(p13) LDFPD	f52, f53  = [X1], 2 * SIZE
	(p13) LDFD	f51 = [Y1], INCY
	(p14) LDFD	f59 = [YY], INCY
	;;
	(p14) LDFPD	f56, f57  = [X1], 2 * SIZE
	(p13) LDFD	f54 = [Y1], INCY
	(p15) LDFD	f61  = [YY]
	;;
	(p13) LDFD	f55 = [Y1], INCY
	(p15) LDFD	f60  = [X1]
	;;
	(p12) FMA	f8  = f32, f34, f8
	(p12) FMA	f9  = f33, f35, f9
	(p12) FMA	f10 = f36, f38, f10
	(p12) FMA	f11 = f37, f39, f11
	(p12) FMA	f12 = f40, f42, f12
	(p12) FMA	f13 = f41, f43, f13
	(p12) FMA	f14 = f44, f46, f14
	(p12) FMA	f15 = f45, f47, f15
	;;		      
	(p13) FMA	f8  = f48, f50, f8
	(p13) FMA	f9  = f49, f51, f9
	(p13) FMA	f10 = f52, f54, f10
	(p13) FMA	f11 = f53, f55, f11
	(p14) FMA	f12 = f56, f58, f12
	(p14) FMA	f13 = f57, f59, f13
	(p15) FMA	f14 = f60, f61, f14
	br	.L999
	;;
	.align 32

.L20:
	{ .mmi
	adds	PREX = PREFETCH_SIZE * SIZE, X1
	adds	PREY = (PREFETCH_SIZE + 38) * SIZE, Y1
	mov	ar.lc = I
	}
	{ .mfb
	cmp.eq	p6 ,p0  =   -1, I
	FMA  f15 = f32, f80, f0
	(p6) br.cond.dpnt  .L25
	}
	;;
	.align 32

.L22:
	{ .mmf
	(p16) LDFPD	f32, f35  = [X1], 2 * SIZE
	(p16) lfetch.nt1 [PREX], INCX16
	(p18) FMA	f8  = f34, f82,  f8
	}
	{ .mmf
	(p17) LDFD	f81 = [Y1], INCY
	(p17) LDFD	f93 = [Y2], INCY
	(p18) FMA	f9  = f37, f85,  f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f38,  f41  = [X1], 2 * SIZE
	(p16) lfetch.nt1 [PREY], INCY16
	(p18) FMA	f10 = f40, f88,  f10
	}
	{ .mmf
	(p17) LDFD	f84  = [Y1], INCY
	(p17) LDFD	f96  = [Y2], INCY
	(p18) FMA	f11 = f43, f91,  f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f44,  f47  = [X1], 2 * SIZE
	(p18) FMA	f12 = f46, f94,  f12
	}
	{ .mmf
	(p17) LDFD	f87  = [Y1], INCY
	(p17) LDFD	f99  = [Y2], INCY
	(p18) FMA	f13 = f49, f97,  f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f50,  f53  = [X1], 2 * SIZE
	(p18) FMA	f14 = f52, f100,  f14
	}
	{ .mmf
	(p17) LDFD	f90  = [Y1], INCY5
	(p17) LDFD	f102 = [Y2], INCY5
	(p18) FMA	f15 = f55, f103, f15
	}
	;;
	{ .mmf
	(p16) LDFPD	f56,  f59  = [X1], 2 * SIZE
	(p18) FMA	f8  = f58, f106, f8
	}
	{ .mmf
	(p17) LDFD	f105 = [Y1], INCY
	(p17) LDFD	f117 = [Y2], INCY
	(p18) FMA	f9   = f61, f109, f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f62,  f65  = [X1], 2 * SIZE
	(p18) FMA	f10 = f64, f112, f10
	}
	{ .mmf
	(p17) LDFD	f108 = [Y1], INCY
	(p17) LDFD	f120 = [Y2], INCY
	(p18) FMA	f11 = f67, f115, f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f68,  f71  = [X1], 2 * SIZE
	(p18) FMA	f12 = f70, f118, f12
	}
	{ .mmf
	(p17) LDFD	f111 = [Y1], INCY
	(p17) LDFD	f123 = [Y2], INCY
	(p18) FMA	f13 = f73, f121, f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f74,  f77  = [X1], 2 * SIZE
	(p17) LDFD	f114 = [Y1], INCY5
	(p18) FMA	f14 = f76, f124, f14
	}
	{ .mfb
	(p17) LDFD	f126 = [Y2], INCY5
	(p18) FMA	f15 = f79, f127, f15
	br.ctop.sptk.few .L22
	}
	;;
	.align 32

.L25:
	{ .mmi
	(p12) LDFPD	f32, f33  = [X1], 2 * SIZE
	mov	YY = Y1
	tbit.z	p0, p13 = N, 2
	}
	{ .mmb
	(p12) LDFD	f34 = [Y1], INCY
	(p12) LDFD	f42 = [Y2], INCY
	(p7) br.cond.dptk .L999
	}
	;;
	{ .mmi
	(p12) LDFPD	f36, f37  = [X1], 2 * SIZE
	(p12) shladd YY = INCY, 3, YY
	tbit.z	p0, p14 = N, 1
	}
	{ .mmi
	(p12) LDFD	f35 = [Y1], INCY
	(p12) LDFD	f43 = [Y2], INCY
	tbit.z	p0, p15 = N, 0
	}
	;;
	{ .mmi
	(p12) LDFPD	f40, f41  = [X1], 2 * SIZE
	(p13) shladd YY = INCY, 2, YY
	}
	{ .mmi
	(p12) LDFD	f38 = [Y1], INCY
	(p12) LDFD	f46 = [Y2], INCY
	}
	;;
	(p12) LDFPD	f44, f45  = [X1], 2 * SIZE
	(p12) LDFD	f39 = [Y1], INCY5
	(p12) LDFD	f47 = [Y2], INCY5
	;;
	(p13) LDFPD	f48, f49  = [X1], 2 * SIZE
	(p13) LDFD	f50 = [Y1], INCY
	(p14) LDFD	f58 = [YY], INCY
	;;
	(p13) LDFPD	f52, f53  = [X1], 2 * SIZE
	(p13) LDFD	f51 = [Y1], INCY
	(p14) LDFD	f59 = [YY], INCY
	;;
	(p14) LDFPD	f56, f57  = [X1], 2 * SIZE
	(p13) LDFD	f54 = [Y1], INCY
	(p15) LDFD	f61  = [YY]
	;;
	(p13) LDFD	f55 = [Y1], INCY
	(p15) LDFD	f60  = [X1]
	;;
	(p12) FMA	f8  = f32, f34, f8
	(p12) FMA	f9  = f33, f35, f9
	(p12) FMA	f10 = f36, f38, f10
	(p12) FMA	f11 = f37, f39, f11
	(p12) FMA	f12 = f40, f42, f12
	(p12) FMA	f13 = f41, f43, f13
	(p12) FMA	f14 = f44, f46, f14
	(p12) FMA	f15 = f45, f47, f15
	;;		      
	(p13) FMA	f8  = f48, f50, f8
	(p13) FMA	f9  = f49, f51, f9
	(p13) FMA	f10 = f52, f54, f10
	(p13) FMA	f11 = f53, f55, f11
	(p14) FMA	f12 = f56, f58, f12
	(p14) FMA	f13 = f57, f59, f13
	(p15) FMA	f14 = f60, f61, f14
	br	.L999
	;;
	.align 32

.L100:
	{ .mmi
	shladd	X2 = INCX, 2, X1
	}
	{ .mib
	cmp.ne	p6, p0 = SIZE, INCY
	tbit.nz	p15, p0 = Y1, BASE_SHIFT
	(p6) br.cond.dptk .L200
	}
	;;
	{ .mfi
	(p15) LDFD f32 = [X1], INCX
	mov	f12 = f0
	mov	pr.rot= 0
	}
	{ .mfi
	(p15) adds N = -1, N
	mov	f13 = f0
	shr  YA = Y1, 3
	}
	;;
	{ .mfi
	(p15) LDFD f80 = [Y1], INCY
	mov	f14 = f0
	shr	I =  N, 4
	}
	{ .mmi
	and	J =  15, N
	and  XA = 0x1f, XA
	and  YA = 0x1f, YA
	}
	;;
	{ .mmi
	shladd	INCX5 = INCX, 2, INCX
	shladd	INCY5 = INCY, 2, INCY
	sub	XA = YA, XA
	}
	{ .mmi
	shladd	INCX16 = INCX, 4, r0
	shladd	INCY16 = INCY, 4, r0
	tbit.z	p0, p12 = N, 3
	}
	;;
	{ .mmi
	shladd	X2 = INCX, 2, X1
	cmp.eq	p7, p0  =   r0, J
	mov	ar.ec= 3
	}
	{ .mmi
	adds	I = -1, I
	cmp.ge	p8, p0 = 8, XA
	cmp.eq	p16, p0 = r0, r0
	}
	;;
	{ .mbb
	cmp.le	p9, p0 = 28, XA
	(p8)  br.cond.dpnt  .L120
	(p9)  br.cond.dpnt  .L120
	}
	;;
	{ .mmi
	adds	PREX = (PREFETCH_SIZE + 5) * SIZE, X1
	adds	PREY = (PREFETCH_SIZE + 3) * SIZE, Y1
	mov	ar.lc = I
	}
	{ .mfb
	cmp.eq	p6 ,p0  =   -1, I
	FMA  f15 = f32, f80, f0
	(p6) br.cond.dpnt  .L115
	}
	;;
	.align 32

/* INCY == 1 */
.L112:
	{ .mmf
	(p16) LDFPD	f32, f35  = [Y1], 2 * SIZE
	(p16) lfetch.nt1 [PREX], INCX16
	(p18) FMA	f8  = f34, f82,  f8
	}
	{ .mmf
	(p16) LDFD	f80 = [X1], INCX
	(p16) LDFD	f92 = [X2], INCX
	(p18) FMA	f9  = f37, f85,  f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f38,  f41  = [Y1], 2 * SIZE
	(p16) lfetch.nt1 [PREY], INCY16
	(p18) FMA	f10 = f40, f88,  f10
	}
	{ .mmf
	(p16) LDFD	f83  = [X1], INCX
	(p16) LDFD	f95  = [X2], INCX
	(p18) FMA	f11 = f43, f91,  f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f44,  f47  = [Y1], 2 * SIZE
	(p18) FMA	f12 = f46, f94,  f12
	}
	{ .mmf
	(p16) LDFD	f86  = [X1], INCX
	(p16) LDFD	f98  = [X2], INCX
	(p18) FMA	f13 = f49, f97,  f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f50,  f53  = [Y1], 2 * SIZE
	(p18) FMA	f14 = f52, f100,  f14
	}
	{ .mmf
	(p16) LDFD	f89  = [X1], INCX5
	(p16) LDFD	f101 = [X2], INCX5
	(p18) FMA	f15 = f55, f103, f15
	}
	;;
	{ .mmf
	(p16) LDFPD	f56,  f59  = [Y1], 2 * SIZE
	(p18) FMA	f8  = f58, f106, f8
	}
	{ .mmf
	(p16) LDFD	f104 = [X1], INCX
	(p16) LDFD	f116 = [X2], INCX
	(p18) FMA	f9   = f61, f109, f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f62,  f65  = [Y1], 2 * SIZE
	(p18) FMA	f10 = f64, f112, f10
	}
	{ .mmf
	(p16) LDFD	f107 = [X1], INCX
	(p16) LDFD	f119 = [X2], INCX
	(p18) FMA	f11 = f67, f115, f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f68,  f71  = [Y1], 2 * SIZE
	(p18) FMA	f12 = f70, f118, f12
	}
	{ .mmf
	(p16) LDFD	f110 = [X1], INCX
	(p16) LDFD	f122 = [X2], INCX
	(p18) FMA	f13 = f73, f121, f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f74,  f77  = [Y1], 2 * SIZE
	(p16) LDFD	f113 = [X1], INCX5
	(p18) FMA	f14 = f76, f124, f14
	}
	{ .mfb
	(p16) LDFD	f125 = [X2], INCX5
	(p18) FMA	f15 = f79, f127, f15
	br.ctop.sptk.few .L112
	}
	;;
	.align 32

.L115:
	{ .mmi
	(p12) LDFPD	f32, f33  = [Y1], 2 * SIZE
	mov	XX = X1
	tbit.z	p0, p13 = N, 2
	}
	{ .mmb
	(p12) LDFD	f34 = [X1], INCX
	(p12) LDFD	f42 = [X2], INCX
	(p7) br.cond.dptk .L999
	}
	;;
	{ .mmi
	(p12) LDFPD	f36, f37  = [Y1], 2 * SIZE
	(p12) shladd XX = INCX, 3, XX
	tbit.z	p0, p14 = N, 1
	}
	{ .mmi
	(p12) LDFD	f35 = [X1], INCX
	(p12) LDFD	f43 = [X2], INCX
	tbit.z	p0, p15 = N, 0
	}
	;;
	{ .mmi
	(p12) LDFPD	f40, f41  = [Y1], 2 * SIZE
	(p13) shladd XX = INCX, 2, XX
	}
	{ .mmi
	(p12) LDFD	f38 = [X1], INCX
	(p12) LDFD	f46 = [X2], INCX
	}
	;;
	(p12) LDFPD	f44, f45  = [Y1], 2 * SIZE
	(p12) LDFD	f39 = [X1], INCX5
	(p12) LDFD	f47 = [X2], INCX5
	;;
	(p13) LDFPD	f48, f49  = [Y1], 2 * SIZE
	(p13) LDFD	f50 = [X1], INCX
	(p14) LDFD	f58 = [XX], INCX
	;;
	(p13) LDFPD	f52, f53  = [Y1], 2 * SIZE
	(p13) LDFD	f51 = [X1], INCX
	(p14) LDFD	f59 = [XX], INCX
	;;
	(p14) LDFPD	f56, f57  = [Y1], 2 * SIZE
	(p13) LDFD	f54 = [X1], INCX
	(p15) LDFD	f61  = [XX]
	;;
	(p13) LDFD	f55 = [X1], INCX
	(p15) LDFD	f60  = [Y1]
	;;
	(p12) FMA	f8  = f32, f34, f8
	(p12) FMA	f9  = f33, f35, f9
	(p12) FMA	f10 = f36, f38, f10
	(p12) FMA	f11 = f37, f39, f11
	(p12) FMA	f12 = f40, f42, f12
	(p12) FMA	f13 = f41, f43, f13
	(p12) FMA	f14 = f44, f46, f14
	(p12) FMA	f15 = f45, f47, f15
	;;		      
	(p13) FMA	f8  = f48, f50, f8
	(p13) FMA	f9  = f49, f51, f9
	(p13) FMA	f10 = f52, f54, f10
	(p13) FMA	f11 = f53, f55, f11
	(p14) FMA	f12 = f56, f58, f12
	(p14) FMA	f13 = f57, f59, f13
	(p15) FMA	f14 = f60, f61, f14
	br	.L999
	;;
	.align 32

.L120:
	{ .mmi
	adds	PREX = (PREFETCH_SIZE + 17) * SIZE, X1
	adds	PREY = (PREFETCH_SIZE + 19) * SIZE, X1
	mov	ar.lc = I
	}
	{ .mfb
	cmp.eq	p6 ,p0  =   -1, I
	FMA  f15 = f32, f80, f0
	(p6) br.cond.dpnt  .L125
	}
	;;
	.align 32

.L122:
	{ .mmf
	(p16) LDFPD	f32, f35  = [Y1], 2 * SIZE
	(p16) lfetch.nt1 [PREX], INCX16
	(p18) FMA	f8  = f34, f82,  f8
	}
	{ .mmf
	(p17) LDFD	f81 = [X1], INCX
	(p17) LDFD	f93 = [X2], INCX
	(p18) FMA	f9  = f37, f85,  f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f38,  f41  = [Y1], 2 * SIZE
	(p16) lfetch.nt1 [PREY], INCX16
	(p18) FMA	f10 = f40, f88,  f10
	}
	{ .mmf
	(p17) LDFD	f84  = [X1], INCX
	(p17) LDFD	f96  = [X2], INCX
	(p18) FMA	f11 = f43, f91,  f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f44,  f47  = [Y1], 2 * SIZE
	(p18) FMA	f12 = f46, f94,  f12
	}
	{ .mmf
	(p17) LDFD	f87  = [X1], INCX
	(p17) LDFD	f99  = [X2], INCX
	(p18) FMA	f13 = f49, f97,  f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f50,  f53  = [Y1], 2 * SIZE
	(p18) FMA	f14 = f52, f100,  f14
	}
	{ .mmf
	(p17) LDFD	f90  = [X1], INCX5
	(p17) LDFD	f102 = [X2], INCX5
	(p18) FMA	f15 = f55, f103, f15
	}
	;;
	{ .mmf
	(p16) LDFPD	f56,  f59  = [Y1], 2 * SIZE
	(p18) FMA	f8  = f58, f106, f8
	}
	{ .mmf
	(p17) LDFD	f105 = [X1], INCX
	(p17) LDFD	f117 = [X2], INCX
	(p18) FMA	f9   = f61, f109, f9
	}
	;;
	{ .mmf
	(p16) LDFPD	f62,  f65  = [Y1], 2 * SIZE
	(p18) FMA	f10 = f64, f112, f10
	}
	{ .mmf
	(p17) LDFD	f108 = [X1], INCX
	(p17) LDFD	f120 = [X2], INCX
	(p18) FMA	f11 = f67, f115, f11
	}
	;;
	{ .mmf
	(p16) LDFPD	f68,  f71  = [Y1], 2 * SIZE
	(p18) FMA	f12 = f70, f118, f12
	}
	{ .mmf
	(p17) LDFD	f111 = [X1], INCX
	(p17) LDFD	f123 = [X2], INCX
	(p18) FMA	f13 = f73, f121, f13
	}
	;;
	{ .mmf
	(p16) LDFPD	f74,  f77  = [Y1], 2 * SIZE
	(p17) LDFD	f114 = [X1], INCX5
	(p18) FMA	f14 = f76, f124, f14
	}
	{ .mfb
	(p17) LDFD	f126 = [X2], INCX5
	(p18) FMA	f15 = f79, f127, f15
	br.ctop.sptk.few .L122
	}
	;;
	.align 32

.L125:
	{ .mmi
	(p12) LDFPD	f32, f33  = [Y1], 2 * SIZE
	mov	XX = X1
	tbit.z	p0, p13 = N, 2
	}
	{ .mmb
	(p12) LDFD	f34 = [X1], INCX
	(p12) LDFD	f42 = [X2], INCX
	(p7) br.cond.dptk .L999
	}
	;;
	{ .mmi
	(p12) LDFPD	f36, f37  = [Y1], 2 * SIZE
	(p12) shladd XX = INCX, 3, XX
	tbit.z	p0, p14 = N, 1
	}
	{ .mmi
	(p12) LDFD	f35 = [X1], INCX
	(p12) LDFD	f43 = [X2], INCX
	tbit.z	p0, p15 = N, 0
	}
	;;
	{ .mmi
	(p12) LDFPD	f40, f41  = [Y1], 2 * SIZE
	(p13) shladd XX = INCX, 2, XX
	}
	{ .mmi
	(p12) LDFD	f38 = [X1], INCX
	(p12) LDFD	f46 = [X2], INCX
	}
	;;
	(p12) LDFPD	f44, f45  = [Y1], 2 * SIZE
	(p12) LDFD	f39 = [X1], INCX5
	(p12) LDFD	f47 = [X2], INCX5
	;;
	(p13) LDFPD	f48, f49  = [Y1], 2 * SIZE
	(p13) LDFD	f50 = [X1], INCX
	(p14) LDFD	f58 = [XX], INCX
	;;
	(p13) LDFPD	f52, f53  = [Y1], 2 * SIZE
	(p13) LDFD	f51 = [X1], INCX
	(p14) LDFD	f59 = [XX], INCX
	;;
	(p14) LDFPD	f56, f57  = [Y1], 2 * SIZE
	(p13) LDFD	f54 = [X1], INCX
	(p15) LDFD	f61  = [XX]
	;;
	(p13) LDFD	f55 = [X1], INCX
	(p15) LDFD	f60  = [Y1]
	;;
	(p12) FMA	f8  = f32, f34, f8
	(p12) FMA	f9  = f33, f35, f9
	(p12) FMA	f10 = f36, f38, f10
	(p12) FMA	f11 = f37, f39, f11
	(p12) FMA	f12 = f40, f42, f12
	(p12) FMA	f13 = f41, f43, f13
	(p12) FMA	f14 = f44, f46, f14
	(p12) FMA	f15 = f45, f47, f15
	;;		      
	(p13) FMA	f8  = f48, f50, f8
	(p13) FMA	f9  = f49, f51, f9
	(p13) FMA	f10 = f52, f54, f10
	(p13) FMA	f11 = f53, f55, f11
	(p14) FMA	f12 = f56, f58, f12
	(p14) FMA	f13 = f57, f59, f13
	(p15) FMA	f14 = f60, f61, f14
	br	.L999
	;;
	.align 32

.L200:
	{ .mfi
	shladd	INCX5 = INCX, 2, INCX
	mov	f12 = f0
	mov	pr.rot= 0
	}
	{ .mfi
	and	J =  15, N
	mov	f13 = f0
	shr	I =  N, 4
	}
	;;
	{ .mmf
	cmp.eq	p16, p0 = r0, r0
	shladd	INCY5 = INCY, 2, INCY
	mov	f14 = f0
	}
	{ .mmi
	shladd	INCX16 = INCX, 4, r0
	shladd	INCY16 = INCY, 4, r0
	tbit.z	p0, p12 = N, 3
	}
	;;
	{ .mmi
	cmp.eq	p7, p0  =   r0, J
	adds	I = -1, I
	mov	ar.ec= 3
	}
	{ .mmi
	shladd	Y2 = INCY, 2, Y1
	mov	XX = X1
	mov	YY = Y1
	}
	;;
	{ .mmi
	adds	PREX = (PREFETCH_SIZE + 5) * SIZE, X1
	adds	PREY = (PREFETCH_SIZE + 3) * SIZE, Y1
	mov	ar.lc = I
	}
	{ .mfb
	cmp.eq	p6 ,p0  =   -1, I
	mov	f15 = f0
	(p6) br.cond.dpnt  .L215
	}
	;;
	.align 32

/* INCY == 1 */
.L212:
	{ .mmf
	(p16) lfetch.nt1 [PREX], INCX16
	(p16) lfetch.nt1 [PREY], INCY16
	(p18) FMA	f8  = f34, f82,  f8
	}
	{ .mmf
	(p16) LDFD	f32 = [Y1], INCY
	(p16) LDFD	f44 = [Y2], INCY
	(p18) FMA	f9  = f37, f85,  f9
	}
	;;
	{ .mmf
	(p16) LDFD	f80 = [X1], INCX
	(p16) LDFD	f92 = [X2], INCX
	(p18) FMA	f10 = f40, f88,  f10
	}
	{ .mmf
	(p16) LDFD	f35 = [Y1], INCY
	(p16) LDFD	f47 = [Y2], INCY
	(p18) FMA	f11 = f43, f91,  f11
	}
	;;
	{ .mmf
	(p16) LDFD	f83  = [X1], INCX
	(p16) LDFD	f95  = [X2], INCX
	(p18) FMA	f12 = f46, f94,  f12
	}
	{ .mmf
	(p16) LDFD	f38 = [Y1], INCY
	(p16) LDFD	f50 = [Y2], INCY
	(p18) FMA	f13 = f49, f97,  f13
	}
	;;
	{ .mmf
	(p16) LDFD	f86  = [X1], INCX
	(p16) LDFD	f98  = [X2], INCX
	(p18) FMA	f14 = f52, f100,  f14
	}
	{ .mmf
	(p16) LDFD	f41 = [Y1], INCY5
	(p16) LDFD	f53 = [Y2], INCY5
	(p18) FMA	f15 = f55, f103, f15
	}
	;;
	{ .mmf
	(p16) LDFD	f89  = [X1], INCX5
	(p16) LDFD	f101 = [X2], INCX5
	(p18) FMA	f8  = f58, f106, f8
	}
	{ .mmf
	(p16) LDFD	f56 = [Y1], INCY
	(p16) LDFD	f68 = [Y2], INCY
	(p18) FMA	f9   = f61, f109, f9
	}
	;;
	{ .mmf
	(p16) LDFD	f104 = [X1], INCX
	(p16) LDFD	f116 = [X2], INCX
	(p18) FMA	f10 = f64, f112, f10
	}
	{ .mmf
	(p16) LDFD	f59 = [Y1], INCY
	(p16) LDFD	f71 = [Y2], INCY
	(p18) FMA	f11 = f67, f115, f11
	}
	;;
	{ .mmf
	(p16) LDFD	f107 = [X1], INCX
	(p16) LDFD	f119 = [X2], INCX
	(p18) FMA	f12 = f70, f118, f12
	}
	{ .mmf
	(p16) LDFD	f62 = [Y1], INCY
	(p16) LDFD	f74 = [Y2], INCY
	(p18) FMA	f13 = f73, f121, f13
	}
	;;
	{ .mmf
	(p16) LDFD	f110 = [X1], INCX
	(p16) LDFD	f122 = [X2], INCX
	(p18) FMA	f14 = f76, f124, f14
	}
	{ .mmf
	(p16) LDFD	f65 = [Y1], INCY5
	(p16) LDFD	f77 = [Y2], INCY5
	(p18) FMA	f15 = f79, f127, f15
	}
	;;
	{ .mmi
	(p16) LDFD	f113 = [X1], INCX5
	(p16) LDFD	f125 = [X2], INCX5
	}
	{ .mmb
	(p16) add XX = INCX16, XX
	(p16) add YY = INCY16, YY
	br.ctop.sptk.few .L212
	}
	;;
	.align 32

.L215:
	{ .mmi
	(p12) LDFD	f34 = [X1], INCX
	(p12) LDFD	f42 = [X2], INCX
	tbit.z	p0, p13 = N, 2
	}
	{ .mmb
	(p12) LDFD	f32 = [Y1], INCY
	(p12) LDFD	f40 = [Y2], INCY
	(p7) br.cond.dptk .L999
	}
	;;
	{ .mmi
	(p12) LDFD	f35 = [X1], INCX
	(p12) LDFD	f43 = [X2], INCX
	tbit.z	p0, p14 = N, 1
	}
	{ .mmi
	(p12) LDFD	f33 = [Y1], INCY
	(p12) LDFD	f41 = [Y2], INCY
	tbit.z	p0, p15 = N, 0
	}
	;;
	{ .mmi
	(p12) LDFD	f38 = [X1], INCX
	(p12) LDFD	f46 = [X2], INCX
	(p12) shladd XX = INCX, 3, XX
	}
	{ .mmi
	(p12) LDFD	f36 = [Y1], INCY
	(p12) LDFD	f44 = [Y2], INCY
	(p12) shladd YY = INCY, 3, YY
	}
	;;
	{ .mmi
	(p12) LDFD	f39 = [X1], INCX5
	(p12) LDFD	f47 = [X2], INCX5
	(p13) shladd XX = INCX, 2, XX
	}
	{ .mmi
	(p12) LDFD	f37 = [Y1], INCY5
	(p12) LDFD	f45 = [Y2], INCY5
	(p13) shladd YY = INCY, 2, YY
	}
	;;
	(p13) LDFD	f50 = [X1], INCX
	(p13) LDFD	f48 = [Y1], INCY
	(p14) LDFD	f58 = [XX], INCX
	(p14) LDFD	f56 = [YY], INCY
	;;
	(p13) LDFD	f51 = [X1], INCX
	(p13) LDFD	f49 = [Y1], INCY
	(p14) LDFD	f59 = [XX], INCX
	(p14) LDFD	f57 = [YY], INCY
	;;
	(p13) LDFD	f54 = [X1], INCX
	(p13) LDFD	f52 = [Y1], INCY
	(p15) LDFD	f61 = [XX]
	(p15) LDFD	f60 = [YY]
	;;
	(p13) LDFD	f55 = [X1]
	(p13) LDFD	f53 = [Y1]
	;;
	(p12) FMA	f8  = f32, f34, f8
	(p12) FMA	f9  = f33, f35, f9
	(p12) FMA	f10 = f36, f38, f10
	(p12) FMA	f11 = f37, f39, f11
	(p12) FMA	f12 = f40, f42, f12
	(p12) FMA	f13 = f41, f43, f13
	(p12) FMA	f14 = f44, f46, f14
	(p12) FMA	f15 = f45, f47, f15
	;;		      
	(p13) FMA	f8  = f48, f50, f8
	(p13) FMA	f9  = f49, f51, f9
	(p13) FMA	f10 = f52, f54, f10
	(p13) FMA	f11 = f53, f55, f11
	(p14) FMA	f12 = f56, f58, f12
	(p14) FMA	f13 = f57, f59, f13
	(p15) FMA	f14 = f60, f61, f14
	br	.L999
	;;
	.align 32

.L999:
	FADD	f8  = f8,  f9
	FADD	f10 = f10, f11
	FADD	f12 = f12, f13
	FADD	f14 = f14, f15
	;;
	FADD	f8  = f8,  f10
	FADD	f12 = f12, f14
	mov	ar.lc = ARLC
	;;
	FADD	f8  = f8,  f12
	mov	pr = PR, -65474
	br.ret.sptk.many b0
	EPILOGUE

