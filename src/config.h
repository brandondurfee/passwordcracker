#include <string>

struct Config {
    std::string mode;
    int threads = 1;
    int length = 4;
    bool use_gpu = false;
    std::string wordlist;
    std::string target;
}