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
        unsigned int hash = 0;
        for (char c : name)
        {
            hash = hash * 31 + c;
        }
        return hash % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info *symbol);
    bool insert_in_scope(symbol_info *symbol);
    bool delete_from_scope(symbol_info *symbol);
    void print_scope_table(ofstream &outlog);
    ~scope_table();
};

scope_table::scope_table()
{
    bucket_count = 10;
    unique_id = 0;
    parent_scope = NULL;
    table.resize(bucket_count);
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

symbol_info *scope_table::lookup_in_scope(symbol_info *symbol)
{
    int index = hash_function(symbol->get_name());

    for (symbol_info *sym : table[index])
    {
        if (sym->get_name() == symbol->get_name())
        {
            return sym;
        }
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info *symbol)
{
    // Check if symbol already exists in this scope
    if (lookup_in_scope(symbol) != NULL)
    {
        return false; // Symbol already exists
    }

    int index = hash_function(symbol->get_name());
    table[index].push_back(symbol);
    return true;
}

bool scope_table::delete_from_scope(symbol_info *symbol)
{
    int index = hash_function(symbol->get_name());

    for (auto it = table[index].begin(); it != table[index].end(); it++)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            delete *it;
            table[index].erase(it);
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream &outlog)
{
    outlog << "ScopeTable # " + to_string(unique_id) << endl;

    for (int i = 0; i < bucket_count; i++)
    {
        if (!table[i].empty())
        {
            outlog << i << " --> " << endl;
            for (symbol_info *sym : table[i])
            {
                outlog << "< " << sym->get_name() << " : " << sym->get_type() << " >" << endl;

                if (sym->is_function())
                {
                    outlog << "Function Definition" << endl;
                    outlog << "Return Type: " << sym->get_return_type() << endl;
                    outlog << "Number of Parameters: " << sym->get_param_count() << endl;
                    outlog << "Parameter Details: " << sym->get_param_details() << endl;
                }
                else if (sym->is_array())
                {
                    outlog << "Array" << endl;
                    outlog << "Type: " << sym->get_data_type() << endl;
                    outlog << "Size: " << sym->get_array_size() << endl;
                }
                else
                {
                    outlog << "Variable" << endl;
                    outlog << "Type: " << sym->get_data_type() << endl;
                }
                outlog << endl;
            }
        }
    }
}

scope_table::~scope_table()
{
    for (int i = 0; i < bucket_count; i++)
    {
        for (symbol_info *sym : table[i])
        {
            delete sym;
        }
        table[i].clear();
    }
}