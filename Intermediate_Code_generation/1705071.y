%{

#include"symbol_table.h"

#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);

extern FILE *yyin;

symbol_table *symtbl = new symbol_table();

ofstream outlog, outerror, outcode, outoptcode;

int lines = 1;
int errors = 0;

int tempcount = 0; //for assembly code
int labelcount = 0;

vector<string>vardeclist; // to declare variables in asm

string newLabel()
{
	string label = "L"+to_string(labelcount);
	labelcount++;
	return label;
}

vector<string> temp_varlist;

string newTemp()
{
	string temp;
	if(temp_varlist.size()!=0)
	{
		temp = temp_varlist[0];
		temp_varlist.erase(temp_varlist.begin());
	}
	else
	{
		temp = "t"+to_string(tempcount);
		tempcount++;
		vardeclist.push_back(temp+"	DW	?");
	}
	return temp;
}


string code = "";//generate code

string varlist=""; //for variable declarartion list
vector<string>paramlist; //for parameter list fot func dec and func def
vector<string>paramname; //for func def	
vector<string>arglist; //to store types of function argument

vector<string> pop_arg_list; //pop in variables in func def
vector<string> push_arg_list; //push to stack during function call

int is_func = 0; //is compound statement in function definition

string ret_type, func_name, func_ret_type, ret_label;

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

void my_optimizer(string code)
{
	string opt_code;
	
	stringstream ss(code);
	
	while(getline(ss,opt_code))
	{
		check_again:
		if(opt_code.find("ADD")<=3)
		{
			vector<string>inst1;
			
			inst1.push_back(opt_code.substr(5,opt_code.find(",")-5));
			inst1.push_back(opt_code.substr(opt_code.find(",")+2,opt_code.length()-1));
			
			if(inst1[1]=="0")	
			{
				cout<<"Adding with 0 found "<<opt_code<<endl;
				goto end;
			}
		}
		
		if(opt_code.find("MOV")<=3)
		{
			//cout<<"found first mov "<<opt_code<<endl;
			
			vector<string>inst1;
			vector<string>inst2;
			
			inst1.push_back(opt_code.substr(5,opt_code.find(",")-5));
			inst1.push_back(opt_code.substr(opt_code.find(",")+2,opt_code.length()-1));
			
			if(inst1[0]=="BX"&&inst1[1]=="1")
			{
				string opt_code1;
				getline(ss,opt_code1);
				
				if(opt_code1.find("MUL")<=3) 
				{
					cout<<"multiply with 1 found"<<endl;
				}
				else if(opt_code1.find("CWD")<=3)
				{
					getline(ss,opt_code1);
					cout<<"divide by 1 found"<<endl;
				}
				else
				{
					outoptcode<<opt_code<<endl;
					outoptcode<<opt_code1<<endl;
				}
				goto end;
			}
			
			outoptcode<<opt_code<<endl;
			
			getline(ss,opt_code);
			if((opt_code[0]=='\t'&&opt_code[1]==';')||opt_code=="")
			{
				outoptcode<<opt_code<<endl; //write the blank line or comment and read another line
				getline(ss,opt_code);
				if(opt_code=="")
				{
					outoptcode<<opt_code<<endl;
					getline(ss,opt_code);
				}
				//cout<<opt_code<<endl;
			}
			
			if(opt_code.find("MOV")<=3)
			{
				//cout<<"found second move "<<opt_code<<endl<<endl;
				
				inst2.push_back(opt_code.substr(5,opt_code.find(",")-5));
				inst2.push_back(opt_code.substr(opt_code.find(",")+2,opt_code.length()-1));
				
				//cout<<inst1[0]<<" "<<inst2[1]<<" "<<inst1[1]<<""<<inst2[0]<<endl;
				
				if(inst1[0]==inst2[1]&&inst1[1]==inst2[0])
				{
					cout<<"match found"<<endl;
					goto end;
				}				
				else
				{
					//cout<<"no match writing code as it is"<<endl;
					//outoptcode<<"h3 "<<opt_code<<endl;
					goto check_again;
				}
			}
			else
			{
				if(opt_code.find("ADD")<=3)
				{
					vector<string>inst1;
					
					inst1.push_back(opt_code.substr(5,opt_code.find(",")-5));
					inst1.push_back(opt_code.substr(opt_code.find(",")+2,opt_code.length()-1));
					
					if(inst1[1]=="0")	
					{
						cout<<"Adding with 0 found "<<opt_code<<endl;
						goto end;
					}
				}
				outoptcode<<opt_code<<endl; //next instruction is not mov, write as it is
				goto end;
			}
		}
		else outoptcode<<opt_code<<endl;
		end:
		;
	}
}


%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program  //done
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		symtbl->Print_all_scope(outlog);
		
		if(errors == 0)
		{
			code = ".MODEL MEDIUM\n.STACK 100H\n.DATA\n\n";
			code+=("t_adrs DW 0\n"); //for function call
			for(int i = 0; i < vardeclist.size(); i++)
			{
				code+=(vardeclist[i]+"\n");
			}
			code+="\n.CODE\n"+$1->getcode();
			
			//code for print
			code+="\nOUTPUT PROC\n\tOR AX,AX\n\tJGE PRINTRSLT\n\n\tPUSH AX\n\tMOV DL, '-'\n\tMOV AH, 2H\n\tINT 21H\n\tPOP AX\n\tNEG AX\n\nPRINTRSLT:\n\n\tCMP AX,0\n\tJE ZERO\n\n\tMOV CX, 0\n\tMOV DX, 0\nPRINT:\n\tCMP AX, 0\n\tJE PRINT1\n\n\tMOV BX, 10\n\n\tDIV BX\n\n\tPUSH DX\n\n\tINC CX\n\n\tXOR DX,DX\n\tJMP PRINT\n\n\tPRINT1:\n\n\tCMP CX, 0\n\tJE EXIT\n\n\tPOP DX\n\tADD DX, 48\n\tMOV AH, 2H\n\tINT 21H\n\tDEC CX\n\n\tJMP PRINT1\n\nZERO:\n\tMOV DX, AX\n\tADD DX, 48\n\tMOV AH, 2H\n\tINT 21H\n\nEXIT:\n\tMOV DL, 0DH\n\tINT 21H\n\tMOV DL, 0AH\n\tINT 21H\n\tRET\n\nOUTPUT ENDP\n";
			code+="\tEND MAIN\n";
			
			outcode<<code<<endl;
		}
		
		delete $1;
		
	}
	;

program : program unit  //done
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
		
		$$->setcode($1->getcode()+$2->getcode());
		
		delete $1;
		delete $2;
	}
	| unit   //done
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
		
		$$->setcode($1->getcode());
		
		delete $1;
	}
	;
	
unit : var_declaration  //done
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
		
		$$->setcode($1->getcode());
		
		delete $1;
		
	 }
     | func_declaration
     {
		outlog<<"At line no: "<<lines<<" unit : func_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
		
		delete $1;
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
		
		$$->setcode($1->getcode());
		
		delete $1;
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
			
			delete $1;
			delete $2;
			delete $4;
			delete $6;
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
			
			delete $1;
			delete $2;
			delete $5;
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
			//code
			code = "\n\n"+$2->getname()+" PROC\n\n\tPOP t_adrs";
			
			for(int i = (pop_arg_list.size()-1); i >-1; i--) //pop arguments in function for use
			{
				code+="\n\tPOP "+pop_arg_list[i];
			}
			
			code+=($7->getcode()+"\n\t"+ret_label+":\n\tPUSH t_adrs\n\tRET\n\n"+$2->getname()+" ENDP");
			
			/*
			PROC FUNC
			POP t_adrs
			
			POP ARGUMENTS ONE BY ONE IF ANY
			
			CODE OF COMPOUND STATEMENT
			
			PUSH t_adrs
			RET
			FUNC ENDP
			*/
			
			$$->setcode(code);
			
			paramlist.clear();
			paramname.clear();
			pop_arg_list.clear();
			
			delete $1;
			delete $2;
			delete $4;
			delete $7;
			
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
			
			if($2->getname()=="main") //main function
			{
				code = "\n\nMAIN PROC\n\n\tMOV AX, @DATA\n\tMOV DS, AX\n";
				code+=$6->getcode();
				code+="\n\tEND_main:\n\tMOV AH, 4CH\n\tINT 21H\nMAIN ENDP\n\n";
				
				/*
				MAIN PROC
				MOV AX, @DATA
				MOV DS, AX
				
				**CODE**
				
				END_main:
				MOV AH, 4CH
				INT 21H
				MAIN ENDP
				*/
			}
			else
			{
				code = "\n\n"+$2->getname()+" PROC\n\n\tPOP t_adrs"+$6->getcode()+"\n\t"+ret_label+":\n\tPUSH t_adrs\n\tRET\n\n"+$2->getname()+" ENDP";
			}
			
			$$->setcode(code);
			
			delete $1;
			delete $2;
			delete $6;
			
		}
 		;		
				
enter_func : {
				
				is_func=1;//compound statement is coming in function definition. enter parameter variables.
				
				ret_label = "END_"+func_name;
				
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
			
			delete $1;
			delete $3;
			delete $4;
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()+","+$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			paramlist.push_back($3->getname());
			paramname.push_back("_null_");
			
			delete $1;
			delete $3;
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
			paramlist.push_back($1->getname());
			paramname.push_back($2->getname());
			
			delete $1;
			delete $2;
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			
			paramlist.push_back($1->getname());
			paramname.push_back("_null_");
			
			delete $1;
		}
 		;

 		
compound_statement : LCURL enter_scope_variables statements RCURL  //done
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
				symtbl->Print_all_scope(outlog);
			    symtbl->exit_scope(outlog);
			    
			    $$->setcode($3->getcode());
			    //cout<<$3->getcode()<<endl;
			    
				delete $3;
 		    }
 		    | LCURL enter_scope_variables RCURL   //done
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				symtbl->Print_all_scope(outlog);
			    symtbl->exit_scope(outlog);
			    
			    $$->setcode("");
			
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
							
							//enter variables in dec list to declare in data segment
							vardeclist.push_back(paramname[i]+symtbl->getID()+"	DW	?");
							
							(symtbl->Lookup_in_table(paramname[i]))->setvalvar(paramname[i]+symtbl->getID()); //code
							
							pop_arg_list.push_back((symtbl->Lookup_in_table(paramname[i]))->getvalvar()); //when in function definition use this list to pop in data
							
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
			// variables are always entered (even if declared void to avoid subsequent errors
			
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
							
							//enter variables in dec list to declare in data segment
							vardeclist.push_back(varname+symtbl->getID()+"	DW	?");
							
							(symtbl->Lookup_in_table(varname))->setvalvar(varname+symtbl->getID()); //code
							
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
							
							//enter variables in dec list to declare in data segment
							vardeclist.push_back(name+symtbl->getID()+"\tDW\t"+size+" DUP (?)");
							
							(symtbl->Lookup_in_table(name))->setvalvar(name+symtbl->getID()); //code
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
			
			delete $1;
			delete $2;
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
		  	$$ = new symbol_info("dec_list","dec_list");
 		  	string name = $3->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	
 		  	varlist=varlist+","+name;
 		  	
			outlog<<varlist<<endl<<endl;
			
			delete $1;
			delete $3;
			
 		  }
 		  | declaration_list COMMA id_name LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	$$ = new symbol_info("dec_list","dec_list");
 		  	string name = $3->getname();
 		  	string size = $5->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	
 		  	varlist=varlist+","+name+"["+size+"]";
 		  	
			outlog<<varlist<<endl<<endl;
			
			delete $1;
			delete $3;
			delete $5;
			
 		  }
 		  |id_name
 		  {
 		  	$$ = new symbol_info("dec_list","dec_list");
 		  	string name = $1->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<name<<endl<<endl;
			
			varlist+=name;
			
			delete $1;
 		  }
 		  | id_name LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	$$ = new symbol_info("dec_list","dec_list");
 		  	string name = $1->getname();
 		  	string size = $3->getname();
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<name+"["+size+"]"<<endl<<endl;
			
			varlist=varlist+name+"["+size+"]";
			
			delete $1;
			delete $3;
 		  }
 		  ;
id_name : ID
		  {
		   	$$ = new symbol_info($1->getname(),"ID");
		   	func_name = $1->getname();
		   	func_ret_type = ret_type;
		   	
		   	delete $1;
		  }
 		  ;
statements : statement  //done
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
			
			$$->setcode($1->getcode());
			//cout<<$1->getcode()<<endl
			
			delete $1;
	   }
	   | statements statement  //done
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
			
			$$->setcode($1->getcode()+$2->getcode());
			//cout<<$2->getcode()<<endl;

			delete $1;
			delete $2;
	   }
	   | error
	   {
	  		$$ = new symbol_info("","stmnts");
	   }  
	   | statements error
	   {
	   		$$ = new symbol_info($1->getname(),"stmnts");
	   		
	   		delete $1;
	   }
	   ;
	   
statement : var_declaration  //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
			$$->setvalvar($1->getvalvar());
			
			delete $1;
	  }
	  | func_definition  //done
	  {
	  		outlog<<"At line no: "<<lines<<" Function definition must be in the global scope "<<endl<<endl;
	  		outerror<<"At line no: "<<lines<<" Function definition must be in the global scope "<<endl<<endl;
	  		errors++;
	  		
	  		$$ = new symbol_info("","stmnt");
	  		
	  		delete $1;
	  		
	  }
	  | func_declaration  //done
	  {
	  		outlog<<"At line no: "<<lines<<" Function declaration must be in the global scope "<<endl<<endl;
	  		outerror<<"At line no: "<<lines<<" Function declaration must be in the global scope "<<endl<<endl;
	  		errors++;
	  		$$ = new symbol_info("","stmnt");
	  		
	  		delete $1;
	  }
	  | expression_statement  //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
			
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
			
						
			string temp = $1->getvalvar();  //optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($1->getvalvar());
			
			delete $1;
	  }
	  | compound_statement  //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
			
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
								
			string temp = $1->getvalvar();  //optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($1->getvalvar());
			
			
			delete $1;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement  //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
			
			//code
			
			string lbl1 = newLabel();
			string lbl2 = newLabel();
			
			code = $3->getcode()+"\n\t"+lbl1+":	;for loop start"+$4->getcode()+"\n\tCMP "+$4->getvalvar()+", 0\n\tJE "+lbl2+$7->getcode()+$5->getcode()+"\n\tJMP "+lbl1+"\n\t"+lbl2+":	;for loop end";
			
			/*
			**EXPRESSION STATEMENT1 CODE**
			L1:
			**EXPRESSION STATEMENT2 CODE**
			CMP EXP_STMNT1_VAR, 0
			JE L2
			**STATEMENT CODE**
			**EXPRESSION CODE**
			JMP L1
			L2:
			*/
			
			$$->setcode(code);
			
			string temp = $3->getvalvar();    //optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($3->getvalvar());
			temp = $4->getvalvar();
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($4->getvalvar());
			temp = $5->getvalvar();
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($5->getvalvar());
			
			delete $3;
			delete $4;
			delete $5;
			delete $7;
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE  //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
			
			//code
			
			string lbl = newLabel();
			
			code = $3->getcode()+"\n\tCMP "+$3->getvalvar()+", 0	;if start\n\tJE "+lbl+$5->getcode()+"\n\t"+lbl+":	;if end";
			
			/*
			**EXPRESSION CODE**
			CMP EXP_VAR, 0
			JE L1
			**STATEMENT CODE**
			L1:
			*/
			
			$$->setcode(code);
			
			string temp = $3->getvalvar();		//optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($3->getvalvar());
			
			
			delete $3;
			delete $5;
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement    //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
			
			//code
			
			string lbl1 = newLabel();
			string lbl2 = newLabel();
			
			code = $3->getcode()+"\n\tCMP "+$3->getvalvar()+", 0	;if else start\n\tJE "+lbl1+$5->getcode()+"\n\tJMP "+lbl2+"\n\t"+lbl1+":"+$7->getcode()+"\n\t"+lbl2+":	;if else end";
			
			/*
			**EXPRESSION CODE**
			CMP EXP_VAR, 0
			JE L1
			**STATEMENT1 CODE**
			JMP L2
			L1:
			**STATEMENT2 CODE**
			L2:
			*/
			
			$$->setcode(code);
			
			string temp = $3->getvalvar();		//optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($3->getvalvar());
			
			
			delete $3;
			delete $5;
			delete $7;
	  }
	  | WHILE LPAREN expression RPAREN statement   //done
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
			
			//code
			
			string lbl1 = newLabel();
			string lbl2 = newLabel();
			
			code = "\n\n\t"+lbl1+":	;while start"+$3->getcode()+"\n\tCMP "+$3->getvalvar()+", 0\n\tJE "+lbl2+$5->getcode()+"\n\tJMP "+lbl1+"\n\t"+lbl2+":	;while end";
			
			/*
			L1:
			**CODE OF EXPRESSION**
			CMP EXP_VAR, 0
			JE L2
			**STATEMENT CODE**
			JMP L1
			L2:
			*/
			
			string temp = $3->getvalvar();		//optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($3->getvalvar());
			
			$$->setcode(code);
			
			delete $3;
			delete $5;
	  }
	  | PRINTLN LPAREN id_name RPAREN SEMICOLON  // might need to add push pop
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
			
			//code
			code = "\n\tMOV AX, "+symtbl->Lookup_in_table($3->getname())->getvalvar()+"\n\tCALL OUTPUT\n";
			$$->setcode(code);
			
			//MOV AX, ID_VAR
			//CALL OUTPUT
			
			delete $3;
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			//check return type of expression with function return type by passing upward
			//no need according to sir
			
			if($2->getvartype() == "void") // void expression
			{
				outerror<<"At line no: "<<lines<<" canonot return void value "<<$2->getname()<<endl<<endl;
				outlog<<"At line no: "<<lines<<" cannot return void value "<<$2->getname()<<endl<<endl;
				errors++;
			}		
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
			
			//code
			code = $2->getcode()+"\n\tPUSH "+$2->getvalvar()+"	;return "+$2->getname()+"\n\tJMP "+ret_label;
			//cout<<$2->getcode()<<endl;
			
			/*
			PUSH expression_variable 
			JMP ret_label;
			*/
			
			$$->setcode(code);	
			
			string temp = $2->getvalvar();		//optimize temps
			if(temp!=""&&temp[0]=='t') temp_varlist.push_back($2->getvalvar());
			
			delete $2;
	  }
	  ;
	  
expression_statement : SEMICOLON  //done
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$->setcode("");
				$$ = new symbol_info(";","expr_stmt");
				
	        }			
			| expression SEMICOLON  //done
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
				
				//$$->setcode("\n\tCOMMENT @\n\t"+$$->getname()+"\n\t@"+$1->getcode());
				$$->setcode($1->getcode()+"\n\t;"+$$->getname());
				//$$->setcode($1->getcode());
				$$->setvalvar($1->getvalvar());
				
				//string temp = $1->getvalvar();
				//if(temp!=""&&temp[0]=='t') temp_varlist.push_back($1->getvalvar());
				
				delete $1;
	        }
			;
	  
variable : id_name 	 //done
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
		else
		{
			$$->setvartype((symtbl->Lookup_in_table($1->getname()))->getvartype()); //set variable type as id type
			
			$$->setidtype("var");
			$$->setvalvar((symtbl->Lookup_in_table($1->getname())->getvalvar())); //code
			$$->setcode((symtbl->Lookup_in_table($1->getname()))->getcode());
		}
		
		delete $1;
		
		
	 }	
	 | id_name LTHIRD expression RTHIRD    //done
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
			
			
			//code
			
			$$->setidtype("array");
			code = $3->getcode();
			code+=("\n\n\tMOV BX, "+$3->getvalvar()+"\n\tADD BX, BX");
			
			/*
			MOV BX, EXP_VAR (BX HOLDS ARRAY INDEX)
			ADD BX, BX  (BX HOLDS OFFSET)
			*/
			$$->setcode(code);
			$$->setvalvar((symtbl->Lookup_in_table($1->getname()))->getvalvar());
		}
		
		delete $1;
		delete $3;
	 }
	 ;
	 
expression : logic_expression //expr can be void  			done 
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			$$->setvartype($1->getvartype());
			
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());//code
			
			delete $1;
	   }
	   | variable ASSIGNOP logic_expression 	//done
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
			
			///code
			code = $3->getcode()+$1->getcode();
			
			$$->setvalvar($1->getvalvar());
			
			if($1->getidtype()=="var") //setcode for normal variables
			{
				code+=("\n\tMOV AX, "+$3->getvalvar()+"\n\tMOV "+$1->getvalvar()+", AX");
				
				/*
				MOV AX, LOG_EXP_VAR
				MOV VAR, AX
				*/
			}
			else if($1->getidtype()=="array") 
			{
				code+=("\n\tMOV AX, "+$3->getvalvar()+"\n\tMOV "+$1->getvalvar()+"[BX], AX");
				
				/*
				MOV AX, LOG_EXP_VAR
				MOV VAR[BX], AX
				*/
			}
			
			$$->setcode(code);
			
			delete $1;
			delete $3;
	   }
	   ;
			
logic_expression : rel_expression //lgc_expr can be void          done
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->setvartype($1->getvartype());
			
			$$->setidtype($1->getidtype());
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar()); //code
			
			delete $1;
	     }	
		 | rel_expression LOGICOP rel_expression  //done
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
			
			//code
			
			code = $1->getcode() + $3->getcode();
			
			string tmp = newTemp();
			string lbl1 = newLabel();
			string lbl2 = newLabel();
			
			code+=("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV BX, "+$3->getvalvar());
			
			/*
			MOV AX, REL_EXP1_VAR
			MOV BX, REL_EXP2_VAR
			*/
			
			if($2->getname()=="&&")
			{
				code+=("\n\tCMP AX, 0\n\tJE "+lbl1+"\n\tCMP BX, 0\n\tJE "+lbl1+"\n\tMOV "+tmp+", 1\n\tJMP "+lbl2+"\n\t"+lbl1+":\n\tMOV "+tmp+", 0\n\t"+lbl2+":");
				
				/*
				CMP AX, 0 -------IF ANY OF THEM IS 0, WHOLE IS 0
				JE L1
				CMP BX, 0
				JE L1
				MOV TEMP, 1 ----NOT 0, SET VALUE 1
				JMP L2
				L1:
				MOV TEMP, O  ----SET VALUE 0
				L2:
				*/
			}
			else if($2->getname()=="||")
			{
				code+=("\n\tCMP AX, 0\n\tJNE "+lbl1+"\n\tCMP BX, 0\n\tJNE "+lbl1+"\n\tMOV "+tmp+", 0\n\tJMP "+lbl2+"\n\t"+lbl1+":\n\tMOV "+tmp+", 1\n\t"+lbl2+":");
				
				/*
				CMP AX, 0 -------IF ANY OF THEM IS NOT 0, WHOLE IS 1
				JNE L1
				CMP BX, 0
				JNE L1
				MOV TEMP, 0 ----BOTH 0, SET VALUE 0
				JMP L2
				L1:
				MOV TEMP, 1 ----SET VALUE 1
				L2:
				*/
			}
			
			$$->setcode(code);
			$$->setvalvar(tmp);
			
			delete $1;
			delete $3;
	     }	
		 ;
			
rel_expression	: simple_expression //rel_expr can be void  			done
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->setvartype($1->getvartype());
			
			$$->setidtype($1->getidtype());
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
			
			delete $1;
	    }
		| simple_expression RELOP simple_expression //done
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
			
			//code
			
			string tmp = newTemp();
			string lbl1 = newLabel();	
			string lbl2 = newLabel();
			
			code = $1->getcode() + $3->getcode();
			code+= ("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tCMP AX, "+$3->getvalvar()+"\n\t");
			
			if($2->getname()=="<") code+= "JL ";
			else if($2->getname()=="<=") code+= "JLE ";
			else if($2->getname()==">") code+= "JG ";
			else if($2->getname()==">=") code+= "JGE ";
			else if($2->getname()=="==") code+= "JE ";
			else code+="JNE ";
			
			code+=(lbl1+"\n\tMOV "+tmp+", 0\n\tJMP "+lbl2+"\n\t"+lbl1+":\n\tMOV "+tmp+", 1\n\t"+lbl2+":");
			
			/*
			MOV AX, SIMP_EXP1_VAR
			CMP AX, SIMP_EXP2_VAR
			JL/JLE/JG/JGE/JE/JNE L1
			MOV TEMP, 0 -------SET VALUE 0
			JMP L2
			L1:
			MOV TEMP, 1
			L2:
			*/
			
			$$->setcode(code);
			$$->setvalvar(tmp);
			
			delete $1;
			delete $3;
		
	    }
		;
				
simple_expression : term //simp_expr can be void 			done
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->setvartype($1->getvartype());
			
			$$->setidtype($1->getidtype());
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
			
			delete $1;
			
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
			
			//code
			
			string tmp = newTemp();
			
			code = $1->getcode()+$3->getcode();
			
			if($2->getname()=="+")
			{
				code+=("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tADD AX, "+$3->getvalvar()+"\n\tMOV "+tmp+", AX");
			}
			else if($2->getname()=="-")
			{
				code+=("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tSUB AX, "+$3->getvalvar()+"\n\tMOV "+tmp+", AX");
			}
			
			/*
			MOV AX, SIMP_EXP_VAR
			ADD/SUB AX, TERM_VAR
			*/
			
			$$->setcode(code);
			$$->setvalvar(tmp);
			
			delete $1;
			delete $3;
		
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor 			done
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			$$->setvartype($1->getvartype());
			
			$$->setidtype($1->getidtype());
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
			
			delete $1;
			
	 }
     |  term MULOP unary_expression  //done
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
			
			//code
			
			string tmp = newTemp();
			
			code = $1->getcode()+$3->getcode();
			
			if($2->getname() == "*")
			{
				code+="\n\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV BX, "+$3->getvalvar()+"\n\tMUL BX\n\tMOV "+tmp+", AX";
				
				/*
				MOV AX, TERM_VAR
				MOV BX, UN_EXP_VAR
				MUL BX
				MOV TEMP, AX
				*/
			}
			
			else if($2->getname() == "/")
			{
				code+="\n\n\tXOR DX, DX\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV BX, "+$3->getvalvar()+"\n\tCWD\n\tIDIV BX\n\tMOV "+tmp+", AX";
				
				/*
				XOR DX, DX
				MOV AX, TERM_VAR
				MOV BX, UN_EXP_VAR
				CWD
				IDIV BX
				MOV TEMP, AX
				*/
			}
			
			else if($2->getname() == "%")
			{
				code+="\n\n\tXOR DX, DX\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV BX, "+$3->getvalvar()+"\n\tCWD\n\tIDIV BX\n\tMOV "+tmp+", DX";
				
				/*
				XOR DX, DX
				MOV AX, TERM_VAR
				MOV BX, UN_EXP_VAR
				CWD
				IDIV BX
				MOV TEMP, DX
				*/
			}
			
			$$->setcode(code);
			$$->setvalvar(tmp);
			
			delete $1;
			delete $3;
		
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor 		done
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
			
			code = $2->getcode();
			$$->setvalvar($2->getvalvar());
			
			string tmp = newTemp();
			
			if($1->getname()=="-") 
			{
				code+=("\n\n\tMOV AX, "+$2->getvalvar()+"\n\tMOV "+tmp+", AX\n\tNEG "+tmp);
				$$->setvalvar(tmp);
				
				/*
				MOV AX, UN_EXP_VAR
				MOV TMP, AX
				NEG TMP
				*/
			}
			
			$$->setcode(code);
			
			delete $2;
		
	     }
		 | NOT unary_expression //done
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
			
			code = $2->getcode();
			
			string tmp = newTemp();
			string lbl1 = newLabel();
			string lbl2 = newLabel();
			
			code+=("\n\n\tMOV AX, "+$2->getvalvar()+"\n\tCMP AX, 0\n\tJNE "+lbl1+"\n\tMOV "+tmp+", 1\n\tJMP "+lbl2+"\n\t"+lbl1+":\n\tMOV "+tmp+", 0\n\t"+lbl2+":");
			
			/*
			MOV AX, UN_EXP_VAR
			CMP AX, 0
			JNE L1
			MOV TEMP, 1  -----VALUE IS 0, SET VALUE 1
			JMP L2
			L1:
			MOV TEMP, 0 -----NON ZERO VALUE, SET 0
			L2:
			*/
			
			$$->setvalvar(tmp);
			
			$$->setcode(code);
			
			delete $2;
	     }
		 | factor //done
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->setvartype($1->getvartype());
			
			$$->setidtype($1->getidtype());
			$$->setcode($1->getcode());
			$$->setvalvar($1->getvalvar());
			
			//outlog<<$1->getvartype()<<endl;
			
			delete $1;
	     }
		 ;
	
factor	: variable  // factor can be void  			done
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype($1->getvartype());
			
		$$->setidtype($1->getidtype());
		
		//code
		code = $1->getcode();
		
		if($1->getidtype()=="var") $$->setvalvar($1->getvalvar());
		else //if($1->getidtype()=="array")
		{
			string tmp =  newTemp();
			code += ("\n\tMOV AX, "+$1->getvalvar()+"[BX]\n\tMOV "+tmp+", AX");
			$$->setvalvar(tmp);
		}
		$$->setcode(code);
		
		delete $1;
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
				if(!flag) 
				{
					$$->setvartype((symtbl->Lookup_in_table($1->getname()))->getvartype());
					
					int has_return = ($$->getvartype() != "void");
					//code
					
					code =  $3->getcode()+"\n\tPUSH t_adrs";
					
					for(int i = 0; i < arglist.size(); i++)
					{
						code+="\n\tPUSH "+push_arg_list[i];
					}
					
					code+="\n\tCALL "+$1->getname();
					
					if(has_return)
					{
						string tmp = newTemp();
						code+="\n\tPOP "+tmp;
						$$->setvalvar(tmp);
					}
					
					code+="\n\tPOP t_adrs";
					
					/*
					PUSH t_adrs -----TO  STORE RETURN VALUE, NEEDED IN NESTED CALLS
					PUSH ARGUMENTS IF ANY
					CALL FUNC
					POP RETURN VALUE IF ANY
					POP t_adrs  ------POP ADDRESS FROM STACK, TO GET RETURN ADDRESS FROM BEFORE FUNCTION CALL, NEEDED IN NESTED CALLS
					*/
					
					$$->setcode(code);
															
				}
			}
		}
		
		arglist.clear();
		push_arg_list.clear();
		
		delete $1;
		delete $3;
	}
	| LPAREN expression RPAREN //done
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->setvartype($2->getvartype());
		
		$$->setidtype($2->getidtype());
		$$->setcode($2->getcode());
		$$->setvalvar($2->getvalvar());
		
		delete $2;
	}
	| CONST_INT //done
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype("int");
		
		$$->setvalvar($1->getname());
		
		delete $1;
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->setvartype("float");
		
		delete $1;
	}
	| variable INCOP //done
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
		$$->setvartype($1->getvartype());
		
		code = $1->getcode();
		string tmp = newTemp();
		if($1->getidtype() == "var")
		{
			code+=("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV "+tmp+", AX\n\tINC "+$1->getvalvar());
			
			/*
			MOV AX, VAR
			MOV TEMP, AX
			INC VAR
			*/
			
		}
		else if($1->getidtype() == "array")
		{
			code+=("\n\n\tMOV AX, "+$1->getvalvar()+"[BX]\n\tMOV "+tmp+", AX\n\tINC "+$1->getvalvar())+"[BX]";
			
			/*
			MOV AX, VAR[BX]
			MOV TEMP, AX
			INC VAR[BX]
			*/
		}
		$$->setvalvar(tmp);
		$$->setcode(code);
		
		delete $1;
	}
	| variable DECOP  //done
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
		$$->setvartype($1->getvartype());
		
		code = $1->getcode();
		string tmp = newTemp();
		if($1->getidtype() == "var")
		{
			code+=("\n\n\tMOV AX, "+$1->getvalvar()+"\n\tMOV "+tmp+", AX\n\tDEC "+$1->getvalvar());
			
			/*
			MOV AX, VAR
			MOV TEMP, AX
			DEC VAR
			*/
			
		}
		else if($1->getidtype() == "array")
		{
			code+=("\n\n\tMOV AX, "+$1->getvalvar()+"[BX]\n\tMOV "+tmp+", AX\n\tDEC "+$1->getvalvar())+"[BX]";
			
			/*
			MOV AX, VAR[BX]
			MOV TEMP, AX
			DEC VAR[BX]
			*/
		}
		$$->setvalvar(tmp);
		$$->setcode(code);
		
		delete $1;
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					
					$$->setcode($1->getcode());
					
					delete $1;
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
				
				$$->setcode($1->getcode()+$3->getcode());
				
				push_arg_list.push_back($3->getvalvar());
				
				delete $1;
				delete $3;
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");
				arglist.push_back($1->getvartype());
				
				$$->setcode($1->getcode());
				
				push_arg_list.push_back($1->getvalvar());
				
				delete $1;
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
	outcode.open("code.asm", ios::trunc);
	outoptcode.open("optimized_code.asm", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	symtbl->enter_scope(outlog);
	yyparse();
	
	my_optimizer(code);
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<errors<<endl;
	outerror<<"Total errors: "<<errors<<endl;
	
	outlog.close();
	outerror.close();
	outcode.close();
	outoptcode.close();
	
	fclose(yyin);
	
	return 0;
}
