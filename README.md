TODO:
1. parallelize the CPU brute threading cracker using OpenMP [DONE]
2. add dictionary attack using wordlist (passed in as a file) and dictionary rules [DONE]
3. add GPU brute force attack [DONE]
4. add timing measurements (total amount of time & hashes/sec)
5. add Makefile

Extensions:
1. add dictionary attack on GPUs
2. add ability for user to input a multitude of hashes in a file that they want to try to crack
3. add ability for multiple different types of hashes (sha1, sha256, sha512)
4. Multi level / advanced dictionary attacks


Examples:

Compile on *Linux/Pace*

```bash
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
(base) brandon@Brandons-MacBook-Air-2 src % ./a.out --mode dict  --target_digest 9f748013af895cce7c56044e75ea3a96 --wordlist /Users/brandon/Desktop/Spring-2026/ECE6122/Final/rockyou.txt --rules basic
Mode: dict
Threads: 1
Length: 4
GPU: no
Wordlist: /Users/brandon/Desktop/Spring-2026/ECE6122/Final/rockyou.txt
Rules basic
Target Digest: 9f748013af895cce7c56044e75ea3a96
hash: 9f748013af895cce7c56044e75ea3a96, plaintext: gr8c4tch
```