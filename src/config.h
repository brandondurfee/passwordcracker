#pragma once

#include <string>
#include <openssl/md5.h>


enum class CrackerType {brute, dict};
enum class DeviceType {cpu, gpu};
// TODO: other hashes?

struct Config {
    std::string mode;
    int threads = 1;
    int length = 4;
    bool use_gpu = false;
    std::string wordlist;
    std::string target_digest;
    std::string rules = "none";
    std::string charset = "abcdefghijklmnopqrstuvwxyz";
};

struct CrackResult {
    std::string plaintext;
    unsigned char digest[MD5_DIGEST_LENGTH];
    bool match;
};