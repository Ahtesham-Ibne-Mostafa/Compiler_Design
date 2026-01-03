#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count);
    ~symbol_table();
    void enter_scope(ofstream &outlog);
    void exit_scope(ofstream &outlog);
    bool insert(symbol_info *symbol);
    symbol_info *lookup(symbol_info *symbol);
    void print_current_scope(ofstream &outlog);
    void print_all_scopes(ofstream &outlog);
    scope_table *get_current_scope();
};

symbol_table::symbol_table(int bucket_count)
{
    this->bucket_count = bucket_count;
    this->current_scope_id = 1;
    this->current_scope = new scope_table(bucket_count, current_scope_id, NULL);
}

void symbol_table::enter_scope(ofstream &outlog)
{
    current_scope_id++;
    scope_table *new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
    current_scope = new_scope;
    outlog << "New ScopeTable with ID " << current_scope_id << " created" << endl
           << endl;
}

void symbol_table::exit_scope(ofstream &outlog)
{
    if (current_scope != NULL)
    {
        print_all_scopes(outlog);

        outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed" << endl
               << endl;

        scope_table *temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;
    }
}

bool symbol_table::insert(symbol_info *symbol)
{
    if (current_scope != NULL)
    {
        return current_scope->insert_in_scope(symbol);
    }
    return false;
}

symbol_info *symbol_table::lookup(symbol_info *symbol)
{
    scope_table *temp = current_scope;
    while (temp != NULL)
    {
        symbol_info *result = temp->lookup_in_scope(symbol);
        if (result != NULL)
        {
            return result;
        }
        temp = temp->get_parent_scope();
    }
    return NULL;
}

void symbol_table::print_current_scope(ofstream &outlog)
{
    if (current_scope != NULL)
    {
        current_scope->print_scope_table(outlog);
    }
}

void symbol_table::print_all_scopes(ofstream &outlog)
{
    outlog << "################################" << endl
           << endl;
    scope_table *temp = current_scope;
    while (temp != NULL)
    {
        temp->print_scope_table(outlog);
        temp = temp->get_parent_scope();
    }
    outlog << "################################" << endl
           << endl;
}

scope_table *symbol_table::get_current_scope()
{
    return current_scope;
}

symbol_table::~symbol_table()
{
    while (current_scope != NULL)
    {
        scope_table *temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;
    }
}