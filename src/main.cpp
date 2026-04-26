#include <iostream>
#include <string>
#include <iomanip>
#include <sstream>

#include "config.h"
#include "attack.h"
#include "utils.h"

struct Config parse_args(int argc, char* argv[]) {
    Config cfg;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];

        if (arg == "--mode") {
            cfg.mode = argv[++i];
        } else if (arg == "--threads") {
            cfg.threads = std::stoi(argv[++i]);
        } else if (arg == "--gpu") {
            cfg.use_gpu = true;
        } else if (arg == "--wordlist") {
            cfg.wordlist = argv[++i];
        } else if (arg == "--length") {
            cfg.length = std::stoi(argv[++i]);
        } else if (arg == "--charset") {
            cfg.charset = argv[++i];
        } else if (arg == "--target_digest") {
            cfg.target_digest = argv[++i];
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            exit(1);
        }
    }

    return cfg;
}

void validate_config(const Config& cfg) {
    if (cfg.mode != "brute" && cfg.mode != "dict") {
        std::cerr << "Error: --mode must be 'brute' or 'dict'\n";
        exit(1);
    }

    if (cfg.mode == "brute" && cfg.length <= 0) {
        std::cerr << "Error: --length must be greater than 0\n";
        exit(1);
    }

    if (cfg.mode == "dict" && cfg.wordlist.empty()) {
        std::cerr << "Error: --wordlist required for dict mode\n";
        exit(1);
    }

    if (cfg.target_digest == "") {
        std::cerr << "Error: target_digest must be a non-null string\n";
        exit(1);
    }

    if (cfg.target_digest.size() != MD5_DIGEST_LENGTH * 2) {
        std::cerr << "Error: please ensure target_digest is a valid 16 Byte md5 digest\n";
        exit(1);
    }

    if (cfg.threads <= 0) {
        std::cerr << "Error: threads must be > 0\n";
        exit(1);
    }
}

int main (int argc, char* argv[]) {
    Config cfg = parse_args(argc, argv);
    validate_config(cfg);

    std::cout << "Mode: " << cfg.mode << "\n";
    std::cout << "Threads: " << cfg.threads << "\n";
    std::cout << "Length: " << cfg.length << "\n";
    std::cout << "GPU: " << (cfg.use_gpu ? "yes" : "no") << "\n";

    if (cfg.mode == "dict") {
        std::cout << "Wordlist: " << cfg.wordlist << "\n";
    }

    std::cout << "Target Digest: " << cfg.target_digest << std::endl;

    Cracker cracker(cfg);
    // dispatch
    if (cfg.mode == "brute") {
        if (cfg.use_gpu) {
            // run CUDA brute force

        } else {
            // run CPU brute force
            struct CrackResult res = cracker.crackPassword();
            std::cout << "hash: " << pprint_digest(res.digest) << ", plaintext: " << res.plaintext << std::endl; 
        }
    } else if (cfg.mode == "dict") {
        // run dictionary attack
    }
    
    return 0;

}