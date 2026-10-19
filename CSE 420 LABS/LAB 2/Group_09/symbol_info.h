#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
public:
    struct parameter_info
    {
        string data_type;
        string name;
    };

    struct declaration_info
    {
        string name;
        bool is_array;
        int array_size;
    };

private:
    string name;
    string type;

    // Write necessary attributes to store what type of symbol it is (variable/array/function)
    string symbol_kind;
    // Write necessary attributes to store the type/return type of the symbol (int/float/void/...)
    string data_type;
    // Write necessary attributes to store the parameters of a function
    vector<parameter_info> parameters;
    // Write necessary attributes to store the array size if the symbol is an array
    int array_size;
    vector<declaration_info> declarations;

public:
    symbol_info()
    {
        name = "";
        type = "";
        symbol_kind = "";
        data_type = "";
        array_size = 0;
    }

    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        symbol_kind = "";
        data_type = "";
        array_size = 0;
    }
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Write necessary functions to set and get the attributes
    string getname()
    {
        return get_name();
    }

    string gettype()
    {
        return get_type();
    }

    void setname(string name)
    {
        set_name(name);
    }

    void settype(string type)
    {
        set_type(type);
    }

    void set_symbol_kind(string symbol_kind)
    {
        this->symbol_kind = symbol_kind;
    }

    string get_symbol_kind()
    {
        return symbol_kind;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    string get_data_type()
    {
        return data_type;
    }

    void set_array_size(int array_size)
    {
        this->array_size = array_size;
    }

    int get_array_size()
    {
        return array_size;
    }

    void add_parameter(string data_type, string name)
    {
        parameter_info parameter;
        parameter.data_type = data_type;
        parameter.name = name;
        parameters.push_back(parameter);
    }

    void set_parameters(const vector<parameter_info>& parameters)
    {
        this->parameters = parameters;
    }

    vector<parameter_info> get_parameters()
    {
        return parameters;
    }

    int get_parameter_count()
    {
        return (int)parameters.size();
    }

    string get_parameter_details()
    {
        string details = "";
        for (int i = 0; i < (int)parameters.size(); i++)
        {
            if (i > 0)
            {
                details += ", ";
            }
            details += parameters[i].data_type;
            if (parameters[i].name != "")
            {
                details += " " + parameters[i].name;
            }
        }
        return details;
    }

    void add_declaration(string name, bool is_array, int array_size)
    {
        declaration_info declaration;
        declaration.name = name;
        declaration.is_array = is_array;
        declaration.array_size = array_size;
        declarations.push_back(declaration);
    }

    void set_declarations(const vector<declaration_info>& declarations)
    {
        this->declarations = declarations;
    }

    vector<declaration_info> get_declarations()
    {
        return declarations;
    }

    ~symbol_info()
    {
        // Write necessary code to deallocate memory, if necessary
    }
};

#endif
