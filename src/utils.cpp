#include "utils.h"

#include <fstream>
#include <vector>
#include <iostream>

std::string pprint_digest(unsigned char* digest) {
    std::ostringstream oss;
    for (int i = 0; i < MD5_DIGEST_LENGTH; i++) {
        oss << std::hex << std::setw(2) << std::setfill('0')
            << (int)digest[i];
    }

    return oss.str();
}

void hex_to_bytes(const std::string& hex, unsigned char* out) {
    for (int i = 0; i < 16; i++) {
        std::string byte = hex.substr(2 * i, 2);
        out[i] = (unsigned char) strtol(byte.c_str(), nullptr, 16);
    }
}

std::vector<std::string> load_wordlist(const std::string& filename) {
    // std::cout << "hello world\n";
    std::ifstream file(filename);
    std::vector<std::string> words;
    
    // reserve to prevent realloc for perf
    words.reserve(1'000'000);

    if (!file.is_open()) {
        std::cerr << "Failed to open wordlist: " << filename << std::endl;
        exit(1);
    }

    std::string line;
    while (std::getline(file, line)) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        else if (!line.empty())
            words.push_back(std::move(line));
    }


    return std::move(words);
}