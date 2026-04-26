#include <iostream>
#include <string>

#include "config.h"

struct Config parse_args(int argc, char* argv[]) {
    Config cfg;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];

        if (arg == "--mode") {
            cfg.mode = argv[++i];
        } else if (arg == "--threads") {
            cfg.mode == std::stoi(argv[++i]);
        } else if (arg == "--gpu") {
            cfg.use_gpu = true;
        } else if (arg == "--wordlist") {
            cfg.wordlist = argv[++i];
        } else if (arg == "--target") {
            cfg.target = argv[++i];
        } else {
            std::cerr << "Unknown argument: " << arg << std::endl;
            exit(1);
        }
    }

    return cfg;
}

void validate_config(const Config& config) {
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

    if (target == "") {
        std::cerr << "Error: target must be a non-null string\n";
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

    std::cout << "Target: " << cfg.target << std::endl;

    // dispatch
    if (cfg.mode == "brute") {
        if (cfg.use_gpu) {
            // run CUDA brute force
        } else {
            // run CPU brute force
        }
    } else if (cfg.mode == "dict") {
        // run dictionary attack
    }
    
    return 0;

}