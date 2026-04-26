#pragma once

#include <sstream>
#include <iomanip>
#include <openssl/md5.h>

std::string pprint_digest(unsigned char* digest);

void hex_to_bytes(const std::string& hex, unsigned char* out);

std::vector<std::string> load_wordlist(const std::string& filename);

