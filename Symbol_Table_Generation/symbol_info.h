#include <bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    // Additional attributes
    string symbol_type; // variable/array/function
    string data_type;   // int/float/void, etc.
    int array_size;     // arrays

    // Function attributes
    string return_type;
    int param_count;
    vector<string> param_types;
    vector<string> param_names;

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = "";
        this->data_type = "";
        this->array_size = -1;
        this->return_type = "";
        this->param_count = 0;
    }

    // Getter methods
    string get_name()
    {
        return name;
    }
    string get_type()
    {
        return type;
    }

    // Symbol type methods
    string get_symbol_type()
    {
        return symbol_type;
    }

    // Data type methods
    string get_data_type()
    {
        return data_type;
    }
    // Array methods
    int get_array_size()
    {
        return array_size;
    }

    // Function methods
    string get_return_type()
    {
        return return_type;
    }
    int get_param_count()
    {
        return param_count;
    }

    vector<string> get_param_types()
    {
        return param_types;
    }

    vector<string> get_param_names()
    {
        return param_names;
    }

    string get_param_details()
    {
        string details = "";
        for (int i = 0; i < param_count; i++)
        {
            if (i > 0)
                details += ", ";
            details += param_types[i];
            if (!param_names[i].empty())
                details += " " + param_names[i];
        }
        return details;
    }

    // For backward compatibility - some grammar rules use getname()
    string getname()
    {
        return name;
    }

    // Setter methods
    void set_name(string name)
    {
        this->name = name;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    // Symbol type methods
    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    // Data type methods
    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    // Array methods
    void set_array_size(int size)
    {
        this->array_size = size;
        this->symbol_type = "array";
    }
    bool is_array()
    {
        return array_size != -1;
    }
    // Function methods
    void set_return_type(string return_type)
    {
        this->return_type = return_type;
        this->symbol_type = "function";
    }
    void set_param_count(int count)
    {
        this->param_count = count;
    }
    void add_parameter(string type, string name)
    {
        param_types.push_back(type);
        param_names.push_back(name);
        param_count++;
    }

    bool is_function()
    {
        return symbol_type == "function";
    }

    ~symbol_info()
    {
        // Explicitly clear containers and strings to release memory early.
        param_types.clear();
        param_types.shrink_to_fit();
        param_names.clear();
        param_names.shrink_to_fit();

        name.clear();
        type.clear();
        symbol_type.clear();
        data_type.clear();
        return_type.clear();

        array_size = -1;
        param_count = 0;
    }
};