#include<bits/stdc++.h>
using namespace std;

extern int lines;
extern ofstream outlog;
extern int abc;
class symbol_info
{
private:
    string sym_name;
    string sym_type;
    string ID_type = ""; //var, array, func_dec, func_def
    string var_type = ""; //int, float, void, error
    int array_size;
    vector<string> param_list;//for functions
    vector<string> param_name;
    symbol_info *next_sym;

    string val_var=""; //for assembly value store
    string code="";  //assembly code
    
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
    
    string getvartype()
    {
        return var_type;
    }
    
    void setvartype(string tp)
    {
    	var_type = tp;
    }
    
    string getidtype()
    {
        return ID_type;
    }
    
    void setidtype(string tp)
    {
    	ID_type = tp;
    }
    
    int getarraysize()
    {
        return array_size;
    }
    
    void setarraysize(int sz)
    {
    	array_size = sz;
    }
    
    void setparamlist(vector<string> list)
    {
    	param_list = list;
    }
    
    vector<string> getparamlist()
    {
    	return param_list;
    }
    
    vector<string> getparamname()
    {
    	return param_name;
    }
    
    void setparamname(vector<string> list)
    {
    	param_name = list;
    }
    
    int getparamsize()
    {
    	return param_list.size();
    }
    
    void setvalvar(string valvar)
    {
    	val_var = valvar;
    }
    
    string getvalvar()
    {
    	return val_var;
    }
    
    void setcode(string cd)
    {
    	code = cd;
    }
    
    string getcode()
    {
    	return code;
    }


    ~symbol_info()
    {
        delete next_sym;
        param_list.clear();
        param_name.clear();
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
        if(parent_scope) ID = parent_scope->getID()+"_"+to_string(parent_scope->get_num_chld());
        else ID = "1";
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
            return true;
        }
        else
        {
            if (chains[hash_val]->getname() == name)
            {
                return false;
            }

            pos++;
            symbol_info *buffer = chains[hash_val];
            symbol_info *curr_sym = chains[hash_val]->get_next();

            while(true)
            {
                if(curr_sym == NULL)
                {
                    buffer->set_next(new_sym);
                    return true;
                }
                else
                {
                    if (curr_sym->getname() == name)
                    {
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
            return false;
        }

        else if (curr_sym->getname() == name)
        {
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
            return false;
        }
    }

    void Print_scope(ofstream& outlog)
    {
    	string s = "";
    	s+="ScopeTable # "+(string)ID+"\n";
        //cout<<"ScopeTable # "<<ID<<endl;

        for(int i = 0; i < tbl_size; i++)
        {
            if(chains[i]!=NULL)
            {
            	s+=to_string(i)+" --> ";
            	//cout<<i<<" --> ";

		        symbol_info *curr_sym = chains[i];

		        while(curr_sym!=NULL)
		        {
		        	s+="< "+curr_sym->getname()+" : "+curr_sym->gettype()+" > ";
		            //cout<<"< "<<curr_sym->getname()<<" : "<<curr_sym->gettype()<<" > ";
		            curr_sym = curr_sym->get_next();
		        }
				s+="\n";
		        //cout<<endl;
            }
        }
		s+="\n";
		outlog<<s;
        //cout<<endl;
        //return s;
    }

    ~scope_table()
    {
        //cout<<"delete scope"<<endl;
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
    int scope_size = 30;
public:
	string getID()
	{
		return curr_scope->getID();
	}
    void set_size(int n)
    {
        scope_size = n;
    }
    void enter_scope(ofstream& outlog)
    {
        scope_table *new_scope = new scope_table(scope_size);
        new_scope->set_prnt(curr_scope);
        curr_scope = new_scope;
        outlog<<"New ScopeTable with ID "<<curr_scope->getID()<<" created"<<endl<<endl;
        //if(new_scope->getID() != "1")cout<<curr_scope->getID()<<" "<<(curr_scope->get_prnt())->getID()<<endl;
    }

    void exit_scope(ofstream& outlog)
    {
    	outlog<<"Scopetable with ID "<<curr_scope->getID()<<" removed"<<endl<<endl;
        scope_table *buffer = curr_scope;
        curr_scope = curr_scope->get_prnt();
        delete buffer;
        buffer = NULL;
        //cout<<curr_scope->getID()<<endl;
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
        
        return symbol;
    }

    void Print_current_scope()
    {
        //curr_scope->Print_scope();
    }

    void Print_all_scope(ofstream& outlog)
    {
        scope_table *buffer = curr_scope;

        while(buffer!=NULL)
        {
            buffer->Print_scope(outlog);
            buffer = buffer->get_prnt();
        }
    }

    ~symbol_table()
    {
        delete curr_scope;
    }

};

