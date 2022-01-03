#include<bits/stdc++.h>
using namespace std;

fstream output;

class symbol_info
{
private:
    string sym_name;
    string sym_type;
    symbol_info *next_sym;
public:
    //symbol_info(){}
    symbol_info(string name, string type)
    {
        sym_name = name;
        sym_type = type;
        next_sym = NULL;
    }

    void set_next(symbol_info *symbol)
    {
        next_sym = symbol;
    }

    symbol_info* get_next()
    {
        return next_sym;
    }

    string getname()
    {
        return sym_name;
    }
    string gettype()
    {
        return sym_type;
    }

    ~symbol_info()
    {
        delete next_sym;
    }
};

class scope_table
{
private:
    symbol_info** chains;
    int tbl_size;
    int num_chld = 0;
    string ID;
    scope_table *parent_scope = NULL;
    int hash_func(string symbol)
    {
        int sum = 0;
        for (int i = 0; i < symbol.size(); i++)
        {
            sum += (int)symbol[i];
        }
        return sum%tbl_size;
    }
public:
    scope_table(){}
    scope_table(int n)
    {
        tbl_size = n;

        chains = new symbol_info*[n];

        for(int i = 0; i < n; i++)
        {
            chains[i] = NULL;
        }
    }

    void set_prnt(scope_table *table)
    {
        parent_scope = table;
        if(parent_scope!=NULL) parent_scope->incrs_chld();
        set_scope_table_ID();
    }

    scope_table* get_prnt()
    {
        return parent_scope;
    }

    void set_scope_table_ID()
    {
        if(parent_scope) ID = parent_scope->getID()+"."+to_string(parent_scope->get_num_chld());
        else ID = "1";
        cout<<"New ScopeTable with id "<<ID<<" created"<<endl<<endl;
        output<<"New ScopeTable with id "<<ID<<" created"<<endl<<endl;
    }

    int get_num_chld()
    {
        return num_chld;
    }

    void incrs_chld()
    {
        num_chld++;
    }

    string getID()
    {
        return ID;
    }

    symbol_info* Lookup_in_scope(string name)
    {
        int pos=0;
        int hash_val = hash_func(name);
        symbol_info *curr_sym = chains[hash_val];

        while(curr_sym != NULL)
        {
            if (curr_sym->getname() == name)
            {
                cout<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                output<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                return curr_sym;
            }
            else
            {
                pos++;
                curr_sym = curr_sym->get_next();
            }
        }

        return curr_sym;
    }

    bool Insert_in_scope(string name, string type)
    {
        int pos = 0;
        symbol_info *new_sym = new symbol_info(name,type);

        int hash_val = hash_func(name);

        if(chains[hash_val]==NULL)
        {
            chains[hash_val] = new_sym;
            cout<<"Inserted in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
            output<<"Inserted in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
            return true;
        }
        else
        {
            if (chains[hash_val]->getname() == name)
            {
                cout<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl<<endl;
                output<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl<<endl;
                return false;
            }

            pos++;
            symbol_info *buffer = chains[hash_val];
            symbol_info *curr_sym = chains[hash_val]->get_next();

            while(true)
            {
                if(curr_sym == NULL)
                {
                    cout<<"Inserted in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                    output<<"Inserted in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                    buffer->set_next(new_sym);
                    return true;
                }
                else
                {
                    if (curr_sym->getname() == name)
                    {
                        cout<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl<<endl;
                        output<<"< "<<name<<","<<type<<" > already exists in current ScopeTable"<<endl<<endl;
                        return false;
                    }
                    pos++;
                    buffer = curr_sym;
                    curr_sym = curr_sym->get_next();
                }
            }
        }
    }

    bool Delete_from_scope(string name)
    {
        int pos = 0;
        int hash_val = hash_func(name);
        symbol_info *curr_sym = chains[hash_val];


        if(curr_sym == NULL)
        {
            cout<<"Not found"<<endl<<endl;
            cout<<name<<" not found"<<endl<<endl;
            output<<"Not found"<<endl<<endl;
            output<<name<<" not found"<<endl<<endl;
            return false;
        }

        else if (curr_sym->getname() == name)
        {
            cout<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
            cout<<"Deleted Entry "<<hash_val<<", "<<pos<<" from current ScopeTable"<<endl<<endl;
            output<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
            output<<"Deleted Entry "<<hash_val<<", "<<pos<<" from current ScopeTable"<<endl<<endl;
            chains[hash_val] = curr_sym->get_next();
            curr_sym->set_next(NULL);
            delete curr_sym;
            curr_sym = NULL;
            return true;
        }

        else
        {
            pos++;
            symbol_info *buffer = curr_sym;
            curr_sym = curr_sym->get_next();
            while(curr_sym!=NULL)
            {
                if (curr_sym->getname() == name)
                {
                    cout<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                    cout<<"Deleted Entry "<<hash_val<<", "<<pos<<" from current ScopeTable"<<endl<<endl;
                    output<<"Found in ScopeTable # "<<getID()<<" at position "<<hash_val<<","<<pos<<endl<<endl;
                    output<<"Deleted Entry "<<hash_val<<", "<<pos<<" from current ScopeTable"<<endl<<endl;
                    buffer->set_next(curr_sym->get_next());
                    curr_sym->set_next(NULL);
                    delete curr_sym;
                    curr_sym = NULL;
                    return true;
                }
                else
                {
                    pos++;
                    buffer = curr_sym;
                    curr_sym = curr_sym->get_next();
                }
            }
            cout<<"Not found"<<endl<<endl;
            cout<<name<<" not found"<<endl<<endl;
            output<<"Not found"<<endl<<endl;
            output<<name<<" not found"<<endl<<endl;
            return false;
        }
    }

    void Print_scope()
    {
        cout<<"ScopeTable # "<<ID<<endl;
        output<<"ScopeTable # "<<ID<<endl;

        for(int i = 0; i < tbl_size; i++)
        {
            cout<<i<<" --> ";
            output<<i<<" --> ";

            symbol_info *curr_sym = chains[i];

            while(curr_sym!=NULL)
            {
                cout<<"< "<<curr_sym->getname()<<" : "<<curr_sym->gettype()<<" > ";
                output<<"< "<<curr_sym->getname()<<" : "<<curr_sym->gettype()<<" > ";
                curr_sym = curr_sym->get_next();
            }

            cout<<endl;
            output<<endl;
        }

        cout<<endl;
        output<<endl;
    }

    ~scope_table()
    {
        for(int i = 0; i<tbl_size; i++)
        {
            while(chains[i]!=NULL)
            {
            	symbol_info *buffer = chains[i];
                chains[i] = chains[i]->get_next();
                buffer->set_next(NULL);
                delete buffer;
                buffer = NULL;
            }
        }
        delete[] chains;
    }
};

class symbol_table
{
private:
    scope_table *curr_scope = NULL;
    int scope_size;
public:

    void set_size(int n)
    {
        scope_size = n;
    }
    void enter_scope()
    {
        scope_table *new_scope = new scope_table(scope_size);
        new_scope->set_prnt(curr_scope);
        curr_scope = new_scope;
    }

    void exit_scope()
    {
        cout<<"ScopeTable with id "<<curr_scope->getID()<<" removed"<<endl<<endl;
        output<<"ScopeTable with id "<<curr_scope->getID()<<" removed"<<endl<<endl;
        scope_table *buffer = curr_scope;
        curr_scope = curr_scope->get_prnt();
        delete buffer;
    }

    bool Insert_in_table(string name, string type)
    {
        if(curr_scope->Insert_in_scope(name,type)) return true;
        else return false;
    }

    bool Remove_from_table(string name)
    {
        if(curr_scope->Delete_from_scope(name)) return true;
        else return false;
    }

    symbol_info* Lookup_in_table(string name)
    {
        symbol_info *symbol = curr_scope->Lookup_in_scope(name);
        scope_table *buffer_scope = curr_scope->get_prnt();
        if(symbol==NULL)
        {
            while(buffer_scope!=NULL)
            {
                symbol = buffer_scope->Lookup_in_scope(name);
                if(symbol!=NULL) return symbol;
                buffer_scope = buffer_scope->get_prnt();
            }
        }
        if(symbol==NULL)
        {
            cout<<"Not found"<<endl<<endl;
            output<<"Not found"<<endl<<endl;
        }
        return symbol;
    }

    void Print_current_scope()
    {
        curr_scope->Print_scope();
    }

    void Print_all_scope()
    {
        scope_table *buffer = curr_scope;

        while(buffer!=NULL)
        {
            buffer->Print_scope();
            buffer = buffer->get_prnt();
        }
    }

    ~symbol_table()
    {
        delete curr_scope;
    }

};

int main()
{
    symbol_table sym_tbl;
    fstream input;
    input.open("input.txt",ios::in);

    output.open("out.txt",ios::out);

    string in;
    getline(input,in);
    int sz = stoi(in);
    sym_tbl.set_size(sz);
    sym_tbl.enter_scope();

    while(getline(input,in))
    {
        cout<<in<<endl<<endl;
        output<<in<<"\n\n";
        if(in == "P C") sym_tbl.Print_current_scope();
        else if (in == "P A") sym_tbl.Print_all_scope();
        else if (in == "S") sym_tbl.enter_scope();
        else if (in == "E") sym_tbl.exit_scope();
        else
        {
            int i = 0;
            string cmnd[3];
            stringstream ss(in);
            while(ss>>cmnd[i]) i++;
            if(cmnd[0] == "I") sym_tbl.Insert_in_table(cmnd[1],cmnd[2]);
            else if(cmnd[0] == "L") sym_tbl.Lookup_in_table(cmnd[1]);
            else if(cmnd[0] == "D") sym_tbl.Remove_from_table(cmnd[1]);
        }

    }

}
