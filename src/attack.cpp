#include "attack.h"
#include "utils.h"
#include "dict.h"

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

    if (cfg.rules == "basic")
        ruleset = {append1, append2, append3, capitalize, uppercase, leete, leeta, leeto, appendexcl};

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

        result = compareDigest(buf, target_digest);
        if (result.match) return result;
    }

    result.plaintext = "not found";
    return result;
}

/**
* crack the password with the CPU using a dictionary attack
*/
struct CrackResult Cracker::crack_cpu_dict() {
    unsigned char digest[MD5_DIGEST_LENGTH];
    unsigned char target_digest[MD5_DIGEST_LENGTH];

    hex_to_bytes(cfg.target_digest, target_digest); 

    struct CrackResult result;

    std::vector<std::string> wordlist = load_wordlist(cfg.wordlist);
    for (const auto& word : wordlist) {
        result = compareDigest(word, target_digest);
        if (result.match) return result;

        // apply ruleset
        for (const auto& rule : ruleset) {
            std::string rulew = rule(word);
            result = compareDigest(rulew, target_digest);
            if (result.match) return result;
        }
    }
    result.plaintext = "not found";
    return result;
}

struct CrackResult Cracker::compareDigest(unsigned char* buf, unsigned char* target_digest) {
    std::string word = reinterpret_cast<const char*>(buf);
    return compareDigest(word, target_digest);
}

struct CrackResult Cracker::compareDigest(const std::string& word, unsigned char* target_digest) {
    struct CrackResult result;
    unsigned char digest[MD5_DIGEST_LENGTH];

    MD5((unsigned char*) word.c_str(), word.size(), digest);
    
    if (memcmp(digest, target_digest, MD5_DIGEST_LENGTH) == 0) {
        memcpy(result.digest, digest, MD5_DIGEST_LENGTH);
        result.plaintext = word;
        result.match = true;
    } else {
        result.match = false;
    }

    return result;
}
