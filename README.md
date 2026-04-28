TODO:
1. [DONE] parallelize the CPU brute threading cracker using OpenMP
2. [DONE] add dictionary attack using wordlist (passed in as a file) and dictionary rules
3. [DONE] add GPU brute force attack
4. [DONE] add timing measurements (total amount of time & hashes/sec)
5. [DONE] add Makefile
6. get Benchmarks

Extensions:
1. add dictionary attack on GPUs
2. add ability for user to input a multitude of hashes in a file that they want to try to crack
3. add ability for multiple different types of hashes (sha1, sha256, sha512)
4. Multi level / advanced dictionary attacks


Examples:

Compile on *Linux/Pace*

```bash
module load cuda
nvcc -Xcompiler -fopenmp main.cpp cuda_cracker.cu attack.cpp dict.cpp utils.cpp  -o cracker      -lssl -lcrypto
```

1. Use brute force on the CPU with length of 5 on hello's md5sum

```bash
(base) brandon@Brandons-MacBook-Air-2 src % echo -n "hello" | md5sum
5d41402abc4b2a76b9719d911017c592

(base) brandon@Brandons-MacBook-Air-2 src % ./cracker --mode brute --target_digest 5d41402abc4b2a76b9719d911017c592 --length 5
Mode: brute
Threads: 1
Length: 5
GPU: no
Target Digest: 5d41402abc4b2a76b9719d911017c592
hash: 5d41402abc4b2a76b9719d911017c592, plaintext: hello
```

2. Use dictionary attack on the CPU with rockyou.txt wordlist and basic rules
```bash
(base) brandon@Brandons-MacBook-Air-2 src % ./cracker --mode dict  --target_digest 9f748013af895cce7c56044e75ea3a96 --wordlist /Users/brandon/Desktop/Spring-2026/ECE6122/Final/rockyou.txt --rules basic
Mode: dict
Threads: 1
Length: 4
GPU: no
Wordlist: /Users/brandon/Desktop/Spring-2026/ECE6122/Final/rockyou.txt
Rules basic
Target Digest: 9f748013af895cce7c56044e75ea3a96
hash: 9f748013af895cce7c56044e75ea3a96, plaintext: gr8c4tch
```


lscpu output (snipped)
```bash
[bdurfee3@atl1-1-01-002-8-0 passwordcracker]$ lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             46 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      40
  On-line CPU(s) list:       0-39
Vendor ID:                   GenuineIntel
  Model name:                Intel(R) Xeon(R) Gold 6248 CPU @ 2.50GHz
    CPU family:              6
    Model:                   85
    Thread(s) per core:      1
    Core(s) per socket:      20
    Socket(s):               2
    Stepping:                7
    CPU(s) scaling MHz:      77%
    CPU max MHz:             2500.0000
    CPU min MHz:             1000.0000
    BogoMIPS:                5000.00
<snip>
```

NVIDIA-SMI output:
```bash
[bdurfee3@atl1-1-01-002-8-0 passwordcracker]$ nvidia-smi
Mon Apr 27 19:14:40 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 575.57.08              Driver Version: 575.57.08      CUDA Version: 12.9     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla V100-PCIE-32GB           On  |   00000000:AF:00.0 Off |                    0 |
| N/A   48C    P0             27W /  250W |       0MiB /  32768MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```


Charsets:

Default Charset: abcdefghijklmnopqrstuvwxyz

Advanced Charset: abcdefghijklmnopqrstuvwxyz!@*$

Ultra Charset: abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@*$