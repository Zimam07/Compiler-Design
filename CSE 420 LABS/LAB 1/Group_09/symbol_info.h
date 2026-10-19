#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string symbol_name;
    string symbol_type;

public:
    symbol_info()
    {
        symbol_name = "";
        symbol_type = "";
    }

    symbol_info(string n, string t)
    {
        symbol_name = n;
        symbol_type = t;
    }

    string getnameofsymbol() const
    {
        return symbol_name;
    }

    string gettypeofsymbol() const
    {
        return symbol_type;
    }

    void setnameofsymbol(string n)
    {
        symbol_name = n;
    }

    void settypeofsymbol(string t)
    {
        symbol_type = t;
    }
};

#endif
