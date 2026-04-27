#include "cuda_cracker.h"
#include <stdio.h>

namespace gpu {
/**************************************************************
 * MD5 declarations
 * ************************************************************/
#define MD5_DIGEST_LENGTH 16

 /* Any 32-bit or wider unsigned integer data type will do */
typedef unsigned int MD5_u32plus;

typedef struct {
	MD5_u32plus lo, hi;
	MD5_u32plus a, b, c, d;
	unsigned char buffer[64];
	MD5_u32plus block[16];
} MD5_CTX;

__device__ void MD5_Init(MD5_CTX *ctx);
__device__ void MD5_Update(MD5_CTX *ctx, const void *data, unsigned long size);
__device__ void MD5_Final(unsigned char *result, MD5_CTX *ctx);
/**************************************************************/


/********************************************** Crack CODE **********************************************/
__device__
void MD5(const char* word, int length, unsigned char* out) {
    MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, word, length);
    MD5_Final(out, &ctx);
}

__device__
void indexToPassword(uint64_t idx, char* out, int length,
                        const char* charset, int base) {
    for (int i = length - 1; i >= 0; --i) {
        out[i] = charset[idx % base];
        idx /= base;
    }
}

__device__
int my_memcmp(const void* a, const void* b, int n) {
    const unsigned char* a1 = (const unsigned char*)a;
    const unsigned char* b1 = (const unsigned char*)b;

    for (int i = 0; i < n; i++)
        if (a1[i] != b1[i]) {
			return 1;
		}
    return 0;
}


__device__
void my_memcpy(void* dst, const void* src, int n) {
    unsigned char* a = (unsigned char*) dst;
    const unsigned char* b = (unsigned char*) src;
    for (int i = 0; i < n; i++) a[i] = b[i];
}

__device__
void my_memset(void* dst, unsigned char val, int n) {
    unsigned char* a = (unsigned char*) dst;
    for (int i = 0; i < n; i++) a[i] = val;
}

// launch crack_kernel which calls md5 on the gpu
__global__ 
void crack_kernel(
	uint64_t total,
    int length,
	const char* charset,
	int base,
    const unsigned char* target_digest,
    int* found,
	char* result_plaintext,
	unsigned char* result_digest)
{
    uint64_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    uint64_t stride = blockDim.x * gridDim.x;

	char buf[16];
	unsigned char digest[MD5_DIGEST_LENGTH];

    for (uint64_t i = tid; i < total; i += stride) {
        if (*found) return;
		indexToPassword(i, buf, length, charset, base);
		
		MD5(buf, length, digest);

		if (my_memcmp(digest, target_digest, MD5_DIGEST_LENGTH) == 0) {
			if (atomicExch(found, 1) == 0) {
				// write result
				memcpy(result_plaintext, buf, length);
				memcpy(result_digest, digest, 16);
			}
			return;
		}
    }
}

struct CrackResult launch_crack_kernel(
		uint64_t total,
		int length,
		const char* charset,
		int base,
		const unsigned char* target_digest)
{
	///// allocate device memory /////
	unsigned char* d_target_digest;
	char* d_charset;
	int* d_found;
	char* d_result_plaintext;
	unsigned char* d_result_digest;

	cudaMalloc(&d_target_digest, MD5_DIGEST_LENGTH);
	cudaMalloc(&d_charset, base);
	cudaMalloc(&d_found, sizeof(int));
	cudaMalloc(&d_result_plaintext, length);
	cudaMalloc(&d_result_digest, MD5_DIGEST_LENGTH);

	// copy data to GPU
	cudaMemcpy(d_target_digest, target_digest, MD5_DIGEST_LENGTH, cudaMemcpyHostToDevice);
	cudaMemcpy(d_charset, charset, base, cudaMemcpyHostToDevice);
	int zero = 0;
	cudaMemcpy(d_found, &zero, sizeof(int), cudaMemcpyHostToDevice);

	// launch kernel
	int blockSize = 256;
	int numBlocks = 512;
	crack_kernel<<<blockSize, numBlocks>>>(total, length, d_charset, base, d_target_digest, 
							d_found, d_result_plaintext, d_result_digest);
	cudaDeviceSynchronize();

	// copy result back
	int h_found;
	cudaMemcpy(&h_found, d_found, sizeof(int), cudaMemcpyDeviceToHost);

	// create CrackResult
	struct CrackResult result;
	if (h_found) {
		// get plaintext from device onto host
		char h_result_plaintext[length + 1];
		h_result_plaintext[length] = '\0';
		cudaMemcpy(h_result_plaintext, d_result_plaintext, length, cudaMemcpyDeviceToHost);
		
		// get digest from device onto host
		char h_result_digest[MD5_DIGEST_LENGTH];
		cudaMemcpy(h_result_digest, d_result_digest, MD5_DIGEST_LENGTH, cudaMemcpyDeviceToHost);

		// write to result
		result.plaintext = h_result_plaintext;
		memcpy(result.digest, h_result_digest, MD5_DIGEST_LENGTH);
		result.match = true;
		return result;
	}
	
	result.match = false;
	result.plaintext = "no match found";

	return result;
}
/********************************************************************************************/



/****************************************************************************************************************
 * MD5 implementation
 ****************************************************************************************************************/

 /*
 * This is an OpenSSL-compatible implementation of the RSA Data Security, Inc.
 * MD5 Message-Digest Algorithm (RFC 1321).
 *
 * Homepage:
 * http://openwall.info/wiki/people/solar/software/public-domain-source-code/md5
 *
 * Author:
 * Alexander Peslyak, better known as Solar Designer <solar at openwall.com>
 *
 * This software was written by Alexander Peslyak in 2001.  No copyright is
 * claimed, and the software is hereby placed in the public domain.
 * In case this attempt to disclaim copyright and place the software in the
 * public domain is deemed null and void, then the software is
 * Copyright (c) 2001 Alexander Peslyak and it is hereby released to the
 * general public under the following terms:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted.
 *
 * There's ABSOLUTELY NO WARRANTY, express or implied.
 *
 * (This is a heavily cut-down "BSD license".)
 *
 * This differs from Colin Plumb's older public domain implementation in that
 * no exactly 32-bit integer data type is required (any 32-bit or wider
 * unsigned integer data type will do), there's no compile-time endianness
 * configuration, and the function prototypes match OpenSSL's.  No code from
 * Colin Plumb's implementation has been reused; this comment merely compares
 * the properties of the two independent implementations.
 *
 * The primary goals of this implementation are portability and ease of use.
 * It is meant to be fast, but not as fast as possible.  Some known
 * optimizations are not included to reduce source code size and avoid
 * compile-time configuration.
 */

/*
 * The basic MD5 functions.
 *
 * F and G are optimized compared to their RFC 1321 definitions for
 * architectures that lack an AND-NOT instruction, just like in Colin Plumb's
 * implementation.
 */
#define F(x, y, z)			((z) ^ ((x) & ((y) ^ (z))))
#define G(x, y, z)			((y) ^ ((z) & ((x) ^ (y))))
#define H(x, y, z)			(((x) ^ (y)) ^ (z))
#define H2(x, y, z)			((x) ^ ((y) ^ (z)))
#define I(x, y, z)			((y) ^ ((x) | ~(z)))

/*
 * The MD5 transformation for all four rounds.
 */
#define STEP(f, a, b, c, d, x, t, s) \
	(a) += f((b), (c), (d)) + (x) + (t); \
	(a) = (((a) << (s)) | (((a) & 0xffffffff) >> (32 - (s)))); \
	(a) += (b);


#define SET(n) \
	(ctx->block[(n)] = \
	(MD5_u32plus)ptr[(n) * 4] | \
	((MD5_u32plus)ptr[(n) * 4 + 1] << 8) | \
	((MD5_u32plus)ptr[(n) * 4 + 2] << 16) | \
	((MD5_u32plus)ptr[(n) * 4 + 3] << 24))
#define GET(n) \
	(ctx->block[(n)])

/*
 * This processes one or more 64-byte data blocks, but does NOT update the bit
 * counters.  There are no alignment requirements.
 */
__device__
static const void *body(MD5_CTX *ctx, const void *data, unsigned long size)
{
	const unsigned char *ptr;
	MD5_u32plus a, b, c, d;
	MD5_u32plus saved_a, saved_b, saved_c, saved_d;

	ptr = (const unsigned char *)data;

	a = ctx->a;
	b = ctx->b;
	c = ctx->c;
	d = ctx->d;

	do {
		saved_a = a;
		saved_b = b;
		saved_c = c;
		saved_d = d;

/* Round 1 */
		STEP(F, a, b, c, d, SET(0), 0xd76aa478, 7)
		STEP(F, d, a, b, c, SET(1), 0xe8c7b756, 12)
		STEP(F, c, d, a, b, SET(2), 0x242070db, 17)
		STEP(F, b, c, d, a, SET(3), 0xc1bdceee, 22)
		STEP(F, a, b, c, d, SET(4), 0xf57c0faf, 7)
		STEP(F, d, a, b, c, SET(5), 0x4787c62a, 12)
		STEP(F, c, d, a, b, SET(6), 0xa8304613, 17)
		STEP(F, b, c, d, a, SET(7), 0xfd469501, 22)
		STEP(F, a, b, c, d, SET(8), 0x698098d8, 7)
		STEP(F, d, a, b, c, SET(9), 0x8b44f7af, 12)
		STEP(F, c, d, a, b, SET(10), 0xffff5bb1, 17)
		STEP(F, b, c, d, a, SET(11), 0x895cd7be, 22)
		STEP(F, a, b, c, d, SET(12), 0x6b901122, 7)
		STEP(F, d, a, b, c, SET(13), 0xfd987193, 12)
		STEP(F, c, d, a, b, SET(14), 0xa679438e, 17)
		STEP(F, b, c, d, a, SET(15), 0x49b40821, 22)

/* Round 2 */
		STEP(G, a, b, c, d, GET(1), 0xf61e2562, 5)
		STEP(G, d, a, b, c, GET(6), 0xc040b340, 9)
		STEP(G, c, d, a, b, GET(11), 0x265e5a51, 14)
		STEP(G, b, c, d, a, GET(0), 0xe9b6c7aa, 20)
		STEP(G, a, b, c, d, GET(5), 0xd62f105d, 5)
		STEP(G, d, a, b, c, GET(10), 0x02441453, 9)
		STEP(G, c, d, a, b, GET(15), 0xd8a1e681, 14)
		STEP(G, b, c, d, a, GET(4), 0xe7d3fbc8, 20)
		STEP(G, a, b, c, d, GET(9), 0x21e1cde6, 5)
		STEP(G, d, a, b, c, GET(14), 0xc33707d6, 9)
		STEP(G, c, d, a, b, GET(3), 0xf4d50d87, 14)
		STEP(G, b, c, d, a, GET(8), 0x455a14ed, 20)
		STEP(G, a, b, c, d, GET(13), 0xa9e3e905, 5)
		STEP(G, d, a, b, c, GET(2), 0xfcefa3f8, 9)
		STEP(G, c, d, a, b, GET(7), 0x676f02d9, 14)
		STEP(G, b, c, d, a, GET(12), 0x8d2a4c8a, 20)

/* Round 3 */
		STEP(H, a, b, c, d, GET(5), 0xfffa3942, 4)
		STEP(H2, d, a, b, c, GET(8), 0x8771f681, 11)
		STEP(H, c, d, a, b, GET(11), 0x6d9d6122, 16)
		STEP(H2, b, c, d, a, GET(14), 0xfde5380c, 23)
		STEP(H, a, b, c, d, GET(1), 0xa4beea44, 4)
		STEP(H2, d, a, b, c, GET(4), 0x4bdecfa9, 11)
		STEP(H, c, d, a, b, GET(7), 0xf6bb4b60, 16)
		STEP(H2, b, c, d, a, GET(10), 0xbebfbc70, 23)
		STEP(H, a, b, c, d, GET(13), 0x289b7ec6, 4)
		STEP(H2, d, a, b, c, GET(0), 0xeaa127fa, 11)
		STEP(H, c, d, a, b, GET(3), 0xd4ef3085, 16)
		STEP(H2, b, c, d, a, GET(6), 0x04881d05, 23)
		STEP(H, a, b, c, d, GET(9), 0xd9d4d039, 4)
		STEP(H2, d, a, b, c, GET(12), 0xe6db99e5, 11)
		STEP(H, c, d, a, b, GET(15), 0x1fa27cf8, 16)
		STEP(H2, b, c, d, a, GET(2), 0xc4ac5665, 23)

/* Round 4 */
		STEP(I, a, b, c, d, GET(0), 0xf4292244, 6)
		STEP(I, d, a, b, c, GET(7), 0x432aff97, 10)
		STEP(I, c, d, a, b, GET(14), 0xab9423a7, 15)
		STEP(I, b, c, d, a, GET(5), 0xfc93a039, 21)
		STEP(I, a, b, c, d, GET(12), 0x655b59c3, 6)
		STEP(I, d, a, b, c, GET(3), 0x8f0ccc92, 10)
		STEP(I, c, d, a, b, GET(10), 0xffeff47d, 15)
		STEP(I, b, c, d, a, GET(1), 0x85845dd1, 21)
		STEP(I, a, b, c, d, GET(8), 0x6fa87e4f, 6)
		STEP(I, d, a, b, c, GET(15), 0xfe2ce6e0, 10)
		STEP(I, c, d, a, b, GET(6), 0xa3014314, 15)
		STEP(I, b, c, d, a, GET(13), 0x4e0811a1, 21)
		STEP(I, a, b, c, d, GET(4), 0xf7537e82, 6)
		STEP(I, d, a, b, c, GET(11), 0xbd3af235, 10)
		STEP(I, c, d, a, b, GET(2), 0x2ad7d2bb, 15)
		STEP(I, b, c, d, a, GET(9), 0xeb86d391, 21)

		a += saved_a;
		b += saved_b;
		c += saved_c;
		d += saved_d;

		ptr += 64;
	} while (size -= 64);

	ctx->a = a;
	ctx->b = b;
	ctx->c = c;
	ctx->d = d;

	return ptr;
}

__device__
void MD5_Init(MD5_CTX *ctx)
{
	ctx->a = 0x67452301;
	ctx->b = 0xefcdab89;
	ctx->c = 0x98badcfe;
	ctx->d = 0x10325476;

	ctx->lo = 0;
	ctx->hi = 0;
}

__device__
void MD5_Update(MD5_CTX *ctx, const void *data, unsigned long size)
{
	MD5_u32plus saved_lo;
	unsigned long used, available;

	saved_lo = ctx->lo;
	if ((ctx->lo = (saved_lo + size) & 0x1fffffff) < saved_lo)
		ctx->hi++;
	ctx->hi += size >> 29;

	used = saved_lo & 0x3f;

	if (used) {
		available = 64 - used;

		if (size < available) {
			my_memcpy(&ctx->buffer[used], data, size);
			return;
		}

		my_memcpy(&ctx->buffer[used], data, available);
		data = (const unsigned char *)data + available;
		size -= available;
		body(ctx, ctx->buffer, 64);
	}

	if (size >= 64) {
		data = body(ctx, data, size & ~(unsigned long)0x3f);
		size &= 0x3f;
	}

	my_memcpy(ctx->buffer, data, size);
}

#define OUT(dst, src) \
	(dst)[0] = (unsigned char)(src); \
	(dst)[1] = (unsigned char)((src) >> 8); \
	(dst)[2] = (unsigned char)((src) >> 16); \
	(dst)[3] = (unsigned char)((src) >> 24);

__device__
void MD5_Final(unsigned char *result, MD5_CTX *ctx)
{
	unsigned long used, available;

	used = ctx->lo & 0x3f;

	ctx->buffer[used++] = 0x80;

	available = 64 - used;

	if (available < 8) {
		my_memset(&ctx->buffer[used], 0, available);
		body(ctx, ctx->buffer, 64);
		used = 0;
		available = 64;
	}

	my_memset(&ctx->buffer[used], 0, available - 8);

	ctx->lo <<= 3;
	OUT(&ctx->buffer[56], ctx->lo)
	OUT(&ctx->buffer[60], ctx->hi)

	body(ctx, ctx->buffer, 64);

	OUT(&result[0], ctx->a)
	OUT(&result[4], ctx->b)
	OUT(&result[8], ctx->c)
	OUT(&result[12], ctx->d)

	my_memset(ctx, 0, sizeof(*ctx));
}
}