#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        // write your hash function here
        int hash_value = 0;
        for (int i = 0; i < (int)name.length(); i++)
        {
            hash_value += name[i];
        }
        if (bucket_count == 0)
        {
            return 0;
        }
        return hash_value % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

    // you can add more methods if you need
};

// complete the methods of scope_table class
scope_table::scope_table()
{
    this->bucket_count = 0;
    this->unique_id = 0;
    this->parent_scope = NULL;
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    table.resize(bucket_count);
}

scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
{
    if (symbol == NULL || bucket_count == 0)
    {
        return NULL;
    }

    int bucket_no = hash_function(symbol->get_name());
    for (list<symbol_info *>::iterator it = table[bucket_no].begin(); it != table[bucket_no].end(); it++)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            return *it;
        }
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    if (symbol == NULL || bucket_count == 0 || lookup_in_scope(symbol) != NULL)
    {
        return false;
    }

    int bucket_no = hash_function(symbol->get_name());
    table[bucket_no].push_back(symbol);
    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    if (symbol == NULL || bucket_count == 0)
    {
        return false;
    }

    int bucket_no = hash_function(symbol->get_name());
    for (list<symbol_info *>::iterator it = table[bucket_no].begin(); it != table[bucket_no].end(); it++)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            delete *it;
            table[bucket_no].erase(it);
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " + to_string(unique_id) << endl;

    //iterate through the current scope table and print the symbols and all relevant information
    for (int i = 0; i < bucket_count; i++)
    {
        if (table[i].empty())
        {
            continue;
        }

        outlog << i << " --> " << endl;
        for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
        {
            symbol_info *symbol = *it;
            outlog << "< " << symbol->get_name() << " : " << symbol->get_type() << " >" << endl;

            if (symbol->get_symbol_kind() == "Function Definition")
            {
                outlog << "Function Definition" << endl;
                outlog << "Return Type: " << symbol->get_data_type() << endl;
                outlog << "Number of Parameters: " << symbol->get_parameter_count() << endl;
                outlog << "Parameter Details: " << symbol->get_parameter_details() << endl << endl;
            }
            else if (symbol->get_symbol_kind() == "Array")
            {
                outlog << "Array" << endl;
                outlog << "Type: " << symbol->get_data_type() << endl;
                outlog << "Size: " << symbol->get_array_size() << endl << endl;
            }
            else if (symbol->get_symbol_kind() == "Variable")
            {
                outlog << "Variable" << endl;
                outlog << "Type: " << symbol->get_data_type() << endl << endl;
            }
        }
    }
    outlog << endl;
}

scope_table::~scope_table()
{
    for (int i = 0; i < (int)table.size(); i++)
    {
        for (list<symbol_info *>::iterator it = table[i].begin(); it != table[i].end(); it++)
        {
            delete *it;
        }
        table[i].clear();
    }
}

#endif
