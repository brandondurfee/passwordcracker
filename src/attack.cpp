#include "attack.h"
#include "utils.h"

#include <cstring>
#include <openssl/md5.h>

/***
* constructor to create a Cracker class
*/
Cracker::Cracker(struct Config& cfg) {
    this->cfg = cfg;

    // total number of different problem spaces given charset size and length of password (charset_size^length)
    unsigned long long total = 1;
    for (int i = 0; i < cfg.length; i++)
        total *= cfg.charset.length();

    this->total = total;
}

/**
* use a unique index to create a password
*/
void Cracker::indexToPassword(int idx, unsigned char* out, int length) {
    std::string charset = cfg.charset;
    int base = charset.length();

    for (int i = length - 1; i >= 0; --i) {
        out[i] = charset[idx % base];
        idx /= base;
    }
}

/*
* crack the password. Decide what type of cracking to do
*/
struct CrackResult Cracker::crackPassword() {
    struct CrackResult result;
    if (cfg.mode == "brute") {
        if (cfg.use_gpu) {
            // crack the password using brute force GPU
        } else {
            // crack the password using brute force CPU
            result = crack_cpu_brute();
        }
    } else {
        // crack the password using dictionary attack on the CPU
        result = crack_cpu_dict();
    }
    
    return result;
}

/**
* crack the password brute force with the CPU
*/
struct CrackResult Cracker::crack_cpu_brute() {
    unsigned char buf[cfg.length + 1];
    buf[cfg.length] = '\0';

    unsigned char digest[MD5_DIGEST_LENGTH];
    unsigned char target_digest[MD5_DIGEST_LENGTH];

    hex_to_bytes(cfg.target_digest, target_digest);

    struct CrackResult result;

    for (int i = 0; i < total; i++) {
        indexToPassword(i, buf, cfg.length);

        MD5(buf, cfg.length, digest);

        if (memcmp(digest, target_digest, MD5_DIGEST_LENGTH) == 0) {
            memcpy(result.digest, digest, MD5_DIGEST_LENGTH);
            result.plaintext = std::string((char*) buf);
            return result;
        }
    }

    result.plaintext = "not found";
    return result;
}

/**
* crack the password with the CPU using a dictionary attack
*/
struct CrackResult Cracker::crack_cpu_dict() {
    unsigned char buf[cfg.length + 1];
    buf[cfg.length] = '\0';

    unsigned char digest[MD5_DIGEST_LENGTH];
    unsigned char target_digest[MD5_DIGEST_LENGTH];

    hex_to_bytes(cfg.target_digest, target_digest); 

    struct CrackResult result;

    std::vector<std::string> wordlist = load_wordlist(cfg.wordlist);
    for (int i = 0; i < wordlist.size(); i++) {
        MD5((unsigned char*) wordlist.at(i).c_str(), wordlist.at(i).size(), digest);

        if (memcmp(digest, target_digest, MD5_DIGEST_LENGTH) == 0) {
            memcpy(result.digest, digest, MD5_DIGEST_LENGTH);
            result.plaintext = wordlist.at(i);
            return result;
        }
    }

    return result;
}