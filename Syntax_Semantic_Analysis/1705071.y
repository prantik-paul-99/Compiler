%{

#include"symbol_table.h"

#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);

extern FILE *yyin;

symbol_table *symtbl = new symbol_table();

ofstream outlog, outerror;

int lines = 1;
int errors = 0;

string varlist=""; //for variable declarartion list
vector<string>paramlist; //for parameter list fot func dec and func def
vector<string>paramname; //for func def	
vector<string>arglist; //to store types of function argument

int is_func = 0; //is compound statement in function definition

string ret_type, func_name, func_ret_type;

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
	outerror<<"At line "<<lines<<" "<<s<<endl<<endl;
	errors++;
	
	varlist = "";
	paramlist.clear();
	paramname.clear();
	arglist.clear();
	is_func = 0;
	ret_type = "";
	func_name = "";
	func_ret_type = "";
}


%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		symtbl->Print_all_scope(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;
	
unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_declaration
     {
		outlog<<"At line no: "<<lines<<" unit : func_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
	 | error
	 {
	 	$$ = new symbol_info("","unit");
	 }
     ;
     
func_declaration : type_specifier id_name LPAREN parameter_list RPAREN SEMICOLON
		{
			outlog<<"At line no: "<<lines<<" func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()<<");"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+");","func_dec");
			
			//insert into symbol table
			if(symtbl->getID()!="1") goto end; //not in global scope
			
			if(symtbl->Insert_in_table($2->getname(),"ID"))
			{
				(symtbl->Lookup_in_table($2->getname()))->setvartype($1->getname());
				(symtbl->Lookup_in_table($2->getname()))->setidtype("func_dec");
				(symtbl->Lookup_in_table($2->getname()))->setparamlist(paramlist);
			}
			else
			{
				outerror<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				errors++;
			}
			end:
			paramlist.clear();
			paramname.clear();
		}
		| type_specifier id_name LPAREN RPAREN SEMICOLON
		{
			outlog<<"At line no: "<<lines<<" func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"();"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"();","func_dec");
			
			//insert into symbol table
			if(symtbl->getID()!="1") goto end1; //not in global scope
			
			if(symtbl->Insert_in_table($2->getname(),"ID"))
			{
				(symtbl->Lookup_in_table($2->getname()))->setvartype($1->getname());
				(symtbl->Lookup_in_table($2->getname()))->setidtype("func_dec");
			}
			else
			{
				outerror<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Multiple declaration of function "<<$2->getname()<<endl<<endl;
				errors++;
			}
			end1:
			;
		}
		;
		 
func_definition : type_specifier id_name LPAREN parameter_list RPAREN enter_func compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");	
			
			if(symtbl->getID()!="1")
			{
				symtbl->Remove_from_table($2->getname());
			}
			
			paramlist.clear();
			paramname.clear();	
		}
		| type_specifier id_name LPAREN RPAREN enter_func compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
			
			if(symtbl->getID()!="1")
			{
				symtbl->Remove_from_table($2->getname());
			}
			
			paramlist.clear();
			paramname.clear();	
		}
 		;		
				
enter_func : {
				//if(symtbl->getID()!="1") goto end2; //not in global scope , doesnt work because if not inserted lots of errors come in compound statement
				
				is_func=1;//compound statement is coming in function definition. enter parameter variables.
				
				if(paramlist.size()!=0) //check parameters
				{
					for(int i = 0; i < paramlist.size();i++)
					{
						if(paramname[i]=="_null_")
						{
							outerror<<"At line no: "<<lines<<" Parameter "<<i+1<<"'s name not given in function definition of "<<func_name<<endl<<endl;
							outlog<<"At line no: "<<lines<<" Parameter "<<i+1<<"'s name not given in function definition of "<<func_name<<endl<<endl;
							errors++;
						}
					}
				}
				
				//check if function already present and do error checking
				if(symtbl->Insert_in_table(func_name,"ID"))
				{
					(symtbl->Lookup_in_table(func_name))->setvartype(func_ret_type);
					(symtbl->Lookup_in_table(func_name))->setidtype("func_def");
					(symtbl->Lookup_in_table(func_name))->setparamlist(paramlist);//initialize parameters
					(symtbl->Lookup_in_table(func_name))->setparamname(paramname);
				}
				else
				{
					if((symtbl->Lookup_in_table(func_name))->getidtype() != "func_dec")
					{
						outerror<<"At line no: "<<lines<<" Multiple declaration of function "<<func_name<<endl<<endl;
						outlog<<"At line no: "<<lines<<" Multiple declaration of function "<<func_name<<endl<<endl;
						errors++;
					}
					else if((symtbl->Lookup_in_table(func_name))->getidtype() == "func_dec")
					{  //function was declared before. check parameter consistencies
					
						vector<string> temp_list = (symtbl->Lookup_in_table(func_name))->getparamlist();
						
						if(temp_list.size()!=paramlist.size())
						{
							outerror<<"At line no: "<<lines<<" parameter number inconsistencies of function "<<func_name<<endl<<endl;
							outlog<<"At line no: "<<lines<<" parameter number inconsistencies of function "<<func_name<<endl<<endl;
							errors++;
						}
						else if (paramlist.size()!=0)
						{
							for(int i = 0; i < paramlist.size(); i++)
							{
								if(paramlist[i]!=temp_list[i])
								{
									outerror<<"At line no: "<<lines<<" "<<"parameter "<<i+1<<" type mismatch of function "<<func_name<<endl<<endl;
									outlog<<"At line no: "<<lines<<" "<<"parameter "<<i+1<<" type mismatch of function "<<func_name<<endl<<endl;
									errors++;
								}
							}
							(symtbl->Lookup_in_table(func_name))->setparamname(paramname);
						}
					
						(symtbl->Lookup_in_table(func_name))->setidtype("func_def");
					}
					
				}
				if((symtbl->Lookup_in_table(func_name))->getvartype() != func_ret_type)
				{
					outerror<<"At line no: "<<lines<<" Return type mismatch of function "<<func_name<<endl<<endl;
					outlog<<"At line no: "<<lines<<" Return type mismatch of function "<<func_name<<endl<<endl;
					errors++;
				}
				
				//end2:
				//;
            }
            ;
            
parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()+","+$3->getname()+" "+$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
			if(count(paramname.begin(),paramname.end(),$4->getname()))
			{
				outerror<<"At line no: "<<lines<<" Multiple declaration of variable "<<$4->getname()<<" in parameter of "<<func_name<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Multiple declaration of variable "<<$4->getname()<<" in parameter of "<<func_name<<endl<<endl;
				errors++;
			}
			
			paramlist.push_back($3->getname());
			paramname.push_back($4->getname());
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()+","+$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			paramlist.push_back($3->getname());
			paramname.push_back("_null_");
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
			paramlist.push_back($1->getname());
			paramname.push_back($2->getname());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			
			paramlist.push_back($1->getname());
			paramname.push_back("_null_");
		}
 		;

 		
compound_statement : LCURL enter_scope_variables statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
				symtbl->Print_all_scope(outlog);
			    symtbl->exit_scope(outlog);
 		    }
 		    | LCURL enter_scope_variables RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				symtbl->Print_all_scope(outlog);
			    symtbl->exit_scope(outlog);
 		    }
 		    ;
enter_scope_variables :
			{
				symtbl->enter_scope(outlog);
				
				if(is_func == 1)
				{
					if(paramname.size()!=0)
					{
						for(int i = 0; i < paramname.size(); i++)
						{
							if(paramname[i]!="_null_")
							{
								symtbl->Insert_in_table(paramname[i],"ID");
								(symtbl->Lookup_in_table(paramname[i]))->setidtype("var");
								(symtbl->Lookup_in_table(paramname[i]))->setvartype(paramlist[i]);
							}
							
						}
					}
					is_func=0; //variable entered.if more compound statements come in func efinitions, don't enter the function variables.
				}
				
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<varlist<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+varlist+";","var_dec");
			
			if($1->getname()=="void")
			{
				outerror<<"At line no: "<<lines<<" variable type can not be void "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" variable type can not be void "<<endl<<endl;
				errors++;
				$1 = new symbol_info("error","type"); //variable is declared void so pass error instead
			}
			// variables are always entered (even if declared void) to avoid subsequent errors
			
				stringstream _varlist(varlist);
				string varname;
				
				while(getline(_varlist,varname,','))
				{
					if(varname.find("[") == string::npos) //insert normal variable
					{
						if(symtbl->Insert_in_table(varname,"ID"))
						{
							(symtbl->Lookup_in_table(varname))->setvartype($1->getname());
							(symtbl->Lookup_in_table(varname))->setidtype("var");
						}
						else
						{
							outerror<<"At line no: "<<lines<<" Multiple declaration of variable "<<varname<<endl<<endl;
							outlog<<"At line no: "<<lines<<" Multiple declaration of variable "<<varname<<endl<<endl;
							errors++;
						}
					}
					
					else  //insert array information
					{
						stringstream _varname(varname);
						string name,size;
						
						getline(_varname,name,'[');//get array name
						getline(_varname,size,']');//get array size
						
						if(symtbl->Insert_in_table(name,"ID"))
						{
							(symtbl->Lookup_in_table(name))->setvartype($1->getname());
							(symtbl->Lookup_in_table(name))->setidtype("array");
							(symtbl->Lookup_in_table(name))->setarraysize(stoi(size));
						}
						else
						{
							outerror<<"At line no: "<<lines<<" Multiple declaration of variable "<<name<<endl<<endl;
							outlog<<"At line no: "<<lines<<" Multiple declaration of variable "<<name<<endl<<endl;
							errors++;
						}
						
					}
				}
			
			varlist = "";
		 }
 		 ;
 		 
type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
			ret_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
			ret_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			$$ = new symbol_info("void","type");
			ret_type = "void";
	    }
 		;
 		
declaration_list : declaration_list COMMA id_name
		  {
 		  	string name = $3->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	
 		  	varlist=varlist+","+name;
 		  	
			outlog<<varlist<<endl<<endl;
			
 		  }
 		  | declaration_list COMMA id_name LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	string name = $3->getname();
 		  	string size = $5->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	
 		  	varlist=varlist+","+name+"["+size+"]";
 		  	
			outlog<<varlist<<endl<<endl;
			
 		  }
 		  |id_name
 		  {
 		  	string name = $1->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<name<<endl<<endl;
			
			varlist+=name;
 		  }
 		  | id_name LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	string name = $1->getname();
 		  	string size = $3->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<name+"["+size+"]"<<endl<<endl;
			
			varlist=varlist+name+"["+size+"]";
 		  }
 		  ;
id_name : ID
		  {
		   	$$ = new symbol_info($1->getname(),"ID");
		   	func_name = $1->getname();
		   	func_ret_type = ret_type;
		  }
 		  ;
statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   | error
	   {
	  		$$ = new symbol_info("","stmnts");
	   }  
	   | statements error
	   {
	   		$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" Function definition must be in the global scope "<<endl<<endl;
	  		outerror<<"At line no: "<<lines<<" Function definition must be in the global scope "<<endl<<endl;
	  		errors++;
	  		$$ = new symbol_info("","stmnt");
	  		
	  }
	  | func_declaration
	  {
	  		outlog<<"At line no: "<<lines<<" Function declaration must be in the global scope "<<endl<<endl;
	  		outerror<<"At line no: "<<lines<<" Function declaration must be in the global scope "<<endl<<endl;
	  		errors++;
	  		$$ = new symbol_info("","stmnt");
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN id_name RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 
			
			if(symtbl->Lookup_in_table($3->getname()) == NULL)
			{
				outerror<<"At line no: "<<lines<<" Undeclared variable "<<$3->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Undeclared variable "<<$3->getname()<<endl<<endl;
				errors++;
			}
			
			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			//check return type of expression with function return type by passing upward
			//no need according to sir
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
	        }
			;
	  
variable : id_name 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"varbl");
		
		if(symtbl->Lookup_in_table($1->getname()) == NULL)
		{
			outerror<<"At line no: "<<lines<<" Undeclared variable "<<$1->getname()<<endl<<endl;
			outlog<<"At line no: "<<lines<<" Undeclared variable "<<$1->getname()<<endl<<endl;
			errors++;
			
			$$->setvartype("error");; //not found set error type
		}
		else if((symtbl->Lookup_in_table($1->getname()))->getidtype() != "var") //variable is not a normal variable
		{
			if((symtbl->Lookup_in_table($1->getname()))->getidtype() == "array")
			{
				outerror<<"At line no: "<<lines<<" variable is of array type : "<<$1->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" variable is of array type : "<<$1->getname()<<endl<<endl;
				errors++;
			}
			else if((symtbl->Lookup_in_table($1->getname()))->getidtype() == "func_def") 
			{
				outerror<<"At line no: "<<lines<<" variable is of function type : "<<$1->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" variable is of function type : "<<$1->getname()<<endl<<endl;
				errors++;
			}
			else if((symtbl->Lookup_in_table($1->getname()))->getidtype() == "func_dec") 
			{
				outerror<<"At line no: "<<lines<<" variable is of function type : "<<$1->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" variable is of function type : "<<$1->getname()<<endl<<endl;
				errors++;
			}
			
			
			$$->setvartype("error");; //doesnt match set error type
		}
		else $$->setvartype((symtbl->Lookup_in_table($1->getname()))->getvartype());  //set variable type as id type
		
	 }	
	 | id_name LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");
		
		if(symtbl->Lookup_in_table($1->getname()) == NULL)
		{
			outerror<<"At line no: "<<lines<<" Undeclared variable "<<$1->getname()<<endl<<endl;
			outlog<<"At line no: "<<lines<<" Undeclared variable "<<$1->getname()<<endl<<endl;
			errors++;
			
			$$->setvartype("error");; //not found set error type
		}
		else if((symtbl->Lookup_in_table($1->getname()))->getidtype() != "array") //variable is not an array
		{
			outerror<<"At line no: "<<lines<<" variable is not of array type : "<<$1->getname()<<endl<<endl;
			outlog<<"At line no: "<<lines<<" variable is not of array type : "<<$1->getname()<<endl<<endl;
			errors++;
			
			$$->setvartype("error");; //doesnt match set error type
		}
		else if($3->getvartype()!="int") // get type of expression of array index
		{
			outerror<<"At line no: "<<lines<<" array index is not of integer type : "<<$1->getname()<<endl<<endl;
			outlog<<"At line no: "<<lines<<" array index is not of integer type : "<<$1->getname()<<endl<<endl;
			errors++;
			
			$$->setvartype("error");
		}
		else
		{
			$$->setvartype((symtbl->Lookup_in_table($1->getname()))->getvartype());
		}
		
	 }
	 ;
	 
expression : logic_expression //expr can be void
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			$$->setvartype($1->getvartype());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
			$$->setvartype($1->getvartype());
			
			if($1->getvartype() == "void" || $3->getvartype() == "void") //if any of them is a void
			{
				outerror<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
			else if($1->getvartype() == "int" && $3->getvartype() == "float") // assignment of float into int
			{
				outerror<<"At line no: "<<lines<<" Warning: Assignment of float value into variable of integer type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Warning: Assignment of float value into variable of integer type "<<endl<<endl;
				errors++;
				
				$$->setvartype("int");
			}
			
			if($1->getvartype() == "error" || $3->getvartype() == "error") //if any of them is a error
			{
				$$->setvartype("error");
			}
	   }
	   ;
			
logic_expression : rel_expression //lgc_expr can be void
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->setvartype($1->getvartype());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
			$$->setvartype("int");
			
			//do type checking of both side of logicop
			
			if($1->getvartype() == "void" || $3->getvartype() == "void") //if any of them is a void
			{
				outerror<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
			
			if($1->getvartype() == "error" || $3->getvartype() == "error") //if any of them is a error
			{
				$$->setvartype("error");
			}
	     }	
		 ;
			
rel_expression	: simple_expression //rel_expr can be void
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->setvartype($1->getvartype());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
			$$->setvartype("int");
			
			//do type checking of both side of relop
			
			if($1->getvartype() == "void" || $3->getvartype() == "void") //if any of them is a void
			{
				outerror<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
			
			if($1->getvartype() == "error" || $3->getvartype() == "error") //if any of them is a error
			{
				$$->setvartype("error");
			}
	    }
		;
				
simple_expression : term //simp_expr can be void
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->setvartype($1->getvartype());
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
			$$->setvartype($1->getvartype());
			
			//do type checking of both side of addop
			
			if($1->getvartype() == "void" || $3->getvartype() == "void") //if any of them is a void
			{
				outerror<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
			else if($1->getvartype() == "float" || $3->getvartype() == "float") //if any of them is a float
			{
				$$->setvartype("float");
			}
			else $$->setvartype("int");
			
			if($1->getvartype() == "error" || $3->getvartype() == "error") //if any of them is a error
			{
				$$->setvartype("error");
			}
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			$$->setvartype($1->getvartype());
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");
			$$->setvartype($1->getvartype());
			
			//do type checking of both side of mulop
			if($1->getvartype() == "void" || $3->getvartype() == "void") //if any of them is a void
			{
				outerror<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type "<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
			else if($1->getvartype() == "float" || $3->getvartype() == "float") //if any of them is a float
			{
				$$->setvartype("float");
			}
			else $$->setvartype("int");
			
			//check if both int for modulous
			if($2->getname() == "%")
			{
				if($1->getvartype() == "int" && $3->getvartype() == "int")
				{
					if($3->getname()=="0")
					{
						outerror<<"At line no: "<<lines<<" Modulus by 0 "<<endl<<endl;
						outlog<<"At line no: "<<lines<<" Modulus by 0 "<<endl<<endl;
						errors++;
						
						$$->setvartype("error");
					}
					else $$->setvartype("int");
				}
				else if($1->getvartype() == "float" || $3->getvartype() == "float")
				{
					outerror<<"At line no: "<<lines<<" Modulus operator on non integer type "<<endl<<endl;
					outlog<<"At line no: "<<lines<<" Modulus operator on non integer type "<<endl<<endl;
					errors++;
					
					$$->setvartype("error");
				}
			}
			
			if($2->getname() == "/") //divide by 0
			{
				if($3->getname()=="0")
				{
					outerror<<"At line no: "<<lines<<" Divide by 0 "<<endl<<endl;
					outlog<<"At line no: "<<lines<<" Divide by 0 "<<endl<<endl;
					errors++;
					
					$$->setvartype("error");
				}
			}
			if($1->getvartype() == "error" || $3->getvartype() == "error") //if any of them is a error
			{
				$$->setvartype("error");
			}
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
			$$->setvartype($2->getvartype());
			
			if($2->getvartype()=="void")
			{
				outerror<<"At line no: "<<lines<<" operation on void type : "<<$2->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type : "<<$2->getname()<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");
			$$->setvartype("int");
			
			if($2->getvartype()=="void")
			{
				outerror<<"At line no: "<<lines<<" operation on void type : "<<$2->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" operation on void type : "<<$2->getname()<<endl<<endl;
				errors++;
				
				$$->setvartype("error");
			}
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->setvartype($1->getvartype());
			
			//outlog<<$1->getvartype()<<endl;
	     }
		 ;
	
factor	: variable  // factor can be void
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype($1->getvartype());
	}
	| id_name LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");
		//$$->setvartype($1->getvartype());
		$$->setvartype("error");
		
		int flag = 0;
			
		//do type checking for function parameter types and numbers
		if(symtbl->Lookup_in_table($1->getname())==NULL) //undeclared function
		{
			outerror<<"At line no: "<<lines<<" Undeclared function: "<<$1->getname()<<endl<<endl;
			outlog<<"At line no: "<<lines<<" Undeclared function: "<<$1->getname()<<endl<<endl;
			errors++;
		}
		else
		{
			if((symtbl->Lookup_in_table($1->getname()))->getidtype()=="func_dec") //declared but not defined
			{
				outerror<<"At line no: "<<lines<<" Undefined function: "<<$1->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" Undefined function: "<<$1->getname()<<endl<<endl;
				errors++;
			}
			else if((symtbl->Lookup_in_table($1->getname()))->getidtype()=="func_def")
			{
				vector<string> templist = (symtbl->Lookup_in_table($1->getname()))->getparamlist();
				
				if(arglist.size()!=templist.size()) //number of prameters don't match
				{
					outerror<<"At line no: "<<lines<<" Inconsistencies in number of arguments in function call: "<<$1->getname()<<endl<<endl;
					outlog<<"At line no: "<<lines<<" Inconsistencies in number of arguments in function call: "<<$1->getname()<<endl<<endl;
					errors++;
				}
				else if(templist.size()!=0)
				{
					for(int i = 0; i < templist.size(); i++)
					{
						if(arglist[i]!=templist[i])
						{
							if(arglist[i] == "int" && templist[i] == "float") {}
							else if(arglist[i]!="error")
							{
								flag = 1;
								outerror<<"At line no: "<<lines<<" "<<"argument "<<i+1<<" type mismatch in function call: "<<$1->getname()<<endl<<endl;
								outlog<<"At line no: "<<lines<<" "<<"argument "<<i+1<<" type mismatch in function call: "<<$1->getname()<<endl<<endl;
								errors++;
							}
						}
					}					
				}
				if(!flag) $$->setvartype((symtbl->Lookup_in_table($1->getname()))->getvartype());
			}
		}
		
		arglist.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->setvartype($2->getvartype());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
		$$->setvartype($1->getvartype());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
		$$->setvartype($1->getvartype());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
				arglist.push_back($3->getvartype());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");
				arglist.push_back($1->getvartype());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("log.txt", ios::trunc);
	outerror.open("error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	symtbl->enter_scope(outlog);
	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<errors<<endl;
	outerror<<"Total errors: "<<errors<<endl;
	
	outlog.close();
	outerror.close();
	
	fclose(yyin);
	
	return 0;
}
