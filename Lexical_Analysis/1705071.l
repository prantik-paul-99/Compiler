%option noyywrap

%x strng comment commentm

%{

#include"symbol_table.h"

symbol_table *symtbl = new symbol_table();
ofstream yyoutlog, yyouttok;

string tokenlist = "";
string loglist = "";
int lines = 1;
int errors = 0;

string buf = "";
int size = 0;
int cmntstrtln = 0;
int strstrtln = 0;


%}

delim	 [ \t\v\r]
newline  \r?\n
ws		 {delim}+
letter_	 [A-Za-z_]
digit	 [0-9]
id		 {letter_}({letter_}|{digit})*
integers {digit}+
floats	 {digit}*(\.{digit}+)|{digit}*(\.{digit}+)?((E|e)[-]?{digit}+)
char	 \'[^\'\"\\\n]\'|\'\\(n|t|\\|\'|\"|a|f|r|b|v|0)\'
manydec  ({digit}*\.{digit}*((E|e)[-]?{digit}*)?){2,}
illform  ({floats}|{integers})(E|e)[-]?({digit}*\.{digit}*)+|{integers}\.({id})?
invalid  ({floats}|{integers})({letter_}+({floats}|{integers})*)+
/*mulchar  \'.{2,}\'*/
mulchar  \'[^\n,;']{2,}\'
unfchar  \'[^\'\n]+|\'\\(n|t|\\|\'|\"|a|f|r|b|v|0)|\'\\\'|\'\"\'

%%

{ws}      { }
{newline} {lines++;}
\'\'      {
			loglist="Line no "+to_string(lines)+": Error: Empty character constant "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }

{manydec} {
			loglist="Line no "+to_string(lines)+": Error: Too many decimal points "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }	
{char}	  {
			string str = yytext;
			str = str.substr(1,str.size()-2);
			if(str.size()==2)
			{
				if(str == "\\n") str = "\n";
				else if(str == "\\t") str = "\t";
				else if(str == "\\\\") str = "\\";
				else if(str == "\\\'") str = "\'";
				else if(str == "\\\"") str = "\"";
				else if(str == "\\a") str = "\a";
				else if(str == "\\f") str = "\f";
				else if(str == "\\r") str = "\r";
				else if(str == "\\b") str = "\b";
				else if(str == "\\v") str = "\v";
				else if(str == "\\0") str = "\0";
			}
			loglist="Line no "+to_string(lines)+": Token <CONST_CHAR> Lexeme "+yytext+" found ---> "+"<CONST_CHAR, "+str+">"+"\n"+"\n";
			tokenlist="<CONST_CHAR,"+str+">";
		   	yyoutlog<<loglist;
			yyouttok<<tokenlist;
			if(symtbl->Insert_in_table(yytext, (string)"CONST_CHAR"))
			{
				symtbl->Print_all_scope(yyoutlog);
			}
			else
			{
				yyoutlog<<yytext<<" already exists in current ScopeTable"<<endl<<endl;
			}
		  }
{mulchar} {
			loglist="Line no "+to_string(lines)+": Error: Multi character Constant "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }
{unfchar} {
			loglist="Line no "+to_string(lines)+": Error: Unfinished character "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }		  
if		  {
		   	loglist="Line no "+to_string(lines)+": Token <IF> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<IF>";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
else	  {
		   	loglist="Line no "+to_string(lines)+": Token <ELSE> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<ELSE>";
			yyoutlog<<loglist;
			yyouttok<<tokenlist; 
		  }
for	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <FOR> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<FOR>";
			yyoutlog<<loglist;
			yyouttok<<tokenlist; 
		  }
while  	  {
		   	loglist="Line no "+to_string(lines)+": Token <WHILE> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<WHILE>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
do	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <DO> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<DO>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
break  	  {
		   	loglist="Line no "+to_string(lines)+": Token <BREAK> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<BREAK>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
int  	  {
		   	loglist="Line no "+to_string(lines)+": Token <INT> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<INT>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
char  	  {
		   	loglist="Line no "+to_string(lines)+": Token <CHAR> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<CHAR>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
float  	  {
		   	loglist="Line no "+to_string(lines)+": Token <FLOAT> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<FLOAT>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
double    {
		   	loglist="Line no "+to_string(lines)+": Token <DOUBLE> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<DOUBLE>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }		
void  	  {
		   	loglist="Line no "+to_string(lines)+": Token <VOID> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<VOID>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
return    {
		   	loglist="Line no "+to_string(lines)+": Token <RETURN> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<RETURN>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
switch    {
		   	loglist="Line no "+to_string(lines)+": Token <SWITCH> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<SWITCH>";
			yyoutlog<<loglist;
			yyouttok<<tokenlist; 
		  }
case  	  {
		   	loglist="Line no "+to_string(lines)+": Token <CASE> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<CASE>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
default	  {
		   	loglist="Line no "+to_string(lines)+": Token <DEFAULT> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<DEFAULT>"; 
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
continue  {
		   	loglist="Line no "+to_string(lines)+": Token <CONTINUE> Lexeme "+yytext+" found"+"\n"+"\n";
			tokenlist="<CONTINUE>";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		   }
"+"|"-"	  {
		   	loglist="Line no "+to_string(lines)+": Token <ADDOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<ADDOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }
"*"|"/"|"%"	  {
		   	loglist="Line no "+to_string(lines)+": Token <MULOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<MULOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
"++"|"--"	  {
		   	loglist="Line no "+to_string(lines)+": Token <INCOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<INCOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
	
"<"|"<="|">"|">="|"=="|"!="	  {
		   	loglist="Line no "+to_string(lines)+": Token <RELOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<RElOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }			  
	
"="	  {
		   	loglist="Line no "+to_string(lines)+": Token <ASSIGNOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<ASSIGNOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
	
"&&"|"||"	  {
		   	loglist="Line no "+to_string(lines)+": Token <LOGICOP> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<LOGICOP,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
	
"!"	  {
		   	loglist="Line no "+to_string(lines)+": Token <NOT> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<NOT,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
	
"("	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <LPAREN> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<LPAREN,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
")"	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <RPAREN> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<RPAREN,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }			  
"{"	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <LCURL> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<LCURL,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		   	symtbl->enter_scope();
		  }	
"}"	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <RCURL> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<RCURL,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		   	symtbl->exit_scope();
		  }	
"["	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <LTHIRD> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<LTHIRD,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
"]"	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <RTHIRD> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<RTHIRD,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
","	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <COMMA> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<COMMA,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }			  
";"	  	  {
		   	loglist="Line no "+to_string(lines)+": Token <SEMICOLON> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<SEMICOLON,"+(string)yytext+">";
			yyoutlog<<loglist;
			yyouttok<<tokenlist;
		  }	
{integers}  {
			loglist="Line no "+to_string(lines)+": Token <CONST_INT> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<CONST_INT,"+(string)yytext+">";
		   	yyoutlog<<loglist;
			yyouttok<<tokenlist;
			if(symtbl->Insert_in_table(yytext, (string)"CONST_INT"))
			{
				symtbl->Print_all_scope(yyoutlog);
			}
			else
			{
				yyoutlog<<yytext<<" already exists in current ScopeTable"<<endl<<endl;
			}
		  }

{floats}  {
			loglist="Line no "+to_string(lines)+": Token <CONST_FLOAT> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<CONST_FLOAT,"+(string)yytext+">";
		   	yyoutlog<<loglist;
			yyouttok<<tokenlist;
			if(symtbl->Insert_in_table(yytext, (string)"CONST_FLOAT"))
			{
				symtbl->Print_all_scope(yyoutlog);
			}
			else
			{
				yyoutlog<<yytext<<" already exists in current ScopeTable"<<endl<<endl;
			}
		  }	 
{illform} {
			loglist="Line no "+to_string(lines)+": Error: Ill formed number "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }	
{invalid} {
			loglist="Line no "+to_string(lines)+": Error: Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence "+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		  }	 	
{id}      {
			loglist="Line no "+to_string(lines)+": Token <ID> Lexeme "+yytext+" found"+"\n"+"\n";
		   	tokenlist="<ID,"+(string)yytext+">";
		   	yyoutlog<<loglist;
			yyouttok<<tokenlist;
			if(symtbl->Insert_in_table(yytext, (string)"ID"))
			{
				symtbl->Print_all_scope(yyoutlog);
			}
			else
			{
				yyoutlog<<yytext<<" already exists in current ScopeTable"<<endl<<endl;
			}
		  }	
\"      {
			BEGIN(strng); yymore(); strstrtln = lines;
		  }
<strng>\\\r?\n {if(yytext[yyleng-2]=='\r') size+=3; 
				else size+=2;
				lines++;yymore();}
<strng>\\t	{buf.push_back('\t');size+=2;yymore();}	
<strng>\\\'	{buf.push_back('\'');size+=2;yymore();}	
<strng>\\\\	{buf.push_back('\\');size+=2;yymore();}	
<strng>\\b	{buf.push_back('\b');size+=2;yymore();}	
<strng>\\a	{buf.push_back('\a');size+=2;yymore();}	
<strng>\\n	{buf.push_back('\n');size+=2;yymore();}	
<strng>\\f	{buf.push_back('\f');size+=2;yymore();}	
<strng>\\r	{buf.push_back('\r');size+=2;yymore();}
<strng>\\v	{buf.push_back('\v');size+=2;yymore();}	
<strng>\\\"	{buf.push_back('\"');size+=2;yymore();}	
<strng>\\.	{buf.push_back(yytext[yyleng-2]);buf.push_back(yytext[yyleng-1]);size+=2;yymore();}	
<strng>\r?\n|\\[^\r\n] {
				  	loglist="Line no "+to_string(strstrtln)+": Error: Unfinished String "+yytext+"\n"+"\n";
				  	yyoutlog<<loglist;
				  	lines++;
				  	errors++;
				  	BEGIN(INITIAL);
					buf = "";
					size = 0;
					strstrtln = 0;
				  }	
<strng><<EOF>> 	{
				  	loglist="Line no "+to_string(strstrtln)+": Error: Unfinished String "+yytext+"\n"+"\n";
				  	yyoutlog<<loglist;
				  	lines++;
				  	errors++;
				  	BEGIN(INITIAL);
					buf = "";
					size = 0;
					strstrtln = 0;
					return 0;
				  }	
<strng>\"	{			   	
			   	buf = buf.substr(1,buf.size()-1);
			   	tokenlist="<STRING,"+buf+">";
				loglist="Line no "+to_string(strstrtln)+": Token <STRING> Lexeme "+yytext+" found ---> "+"<STRING, "+buf+">"+"\n"+"\n";
				yyoutlog<<loglist;
				yyouttok<<tokenlist;
				BEGIN(INITIAL);
				buf = "";
				size = 0;
				strstrtln = 0;
			}
<strng>[^\\\r\n\"]+ 	{
							char y = yytext[size];
							while(y) 
							{
								buf.push_back(y);
								size++;
								y = yytext[size];
							}
							yymore();
					    }
\/\/		{
				cmntstrtln = lines; BEGIN(comment); yymore();
			}			 
<comment>[^\\\r\n]* { yymore();}
<comment>\\\r?\n {lines++; yymore();}
<comment>\\[^\\\r\n]* {
							yymore();
						} /*
<comment>\\\r?\n {lines++; yymore();}
<comment>[^\\|\r?\n]* {yymore();}*/
<comment>\r?\n  {
						yytext[yyleng-1]='\0';
						loglist="Line no "+to_string(cmntstrtln)+": Token <COMMENT> Lexeme "+yytext+" found"+"\n"+"\n";
						yyoutlog<<loglist;
						cmntstrtln = 0;
						BEGIN(INITIAL);
						lines++;
					}
<comment><<EOF>>  {
				  	loglist="Line no "+to_string(cmntstrtln)+": Error: Unfinished Comment "+yytext+"\n"+"\n";
				  	yyoutlog<<loglist;
				  	errors++;
				  	return 0;
				  }	
				  
\/\*   {//cout<<yytext<<endl; 
cmntstrtln = lines; BEGIN(commentm);yymore();}
<commentm>[^\*\r\n]*	{yymore();}
<commentm>\*[^\*\/\r\n]* {yymore();}
<commentm>\r?\n {lines++; yymore();}
<commentm><<EOF>> {
				  	loglist="Line no "+to_string(cmntstrtln)+": Error: Unfinished Comment "+yytext+"\n"+"\n";
				  	yyoutlog<<loglist;
				  	errors++;
				  	return 0;
				  }	
<commentm>\*\/ {
					loglist="Line no "+to_string(cmntstrtln)+": Token <COMMENT> Lexeme "+yytext+" found"+"\n"+"\n";
					yyoutlog<<loglist;
					cmntstrtln = 0;	
					BEGIN(INITIAL);
				}
.        {
			loglist="Line no "+to_string(lines)+": Error: Unrecognized character"+yytext+"\n"+"\n";
			yyoutlog<<loglist;
			errors++;
		    }
	  		  		  	  			  		  
%%

int main(int argc, char *argv[])
{
	symtbl->enter_scope();
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	yyoutlog.open("1705071_log.txt", ios::trunc);
	yyouttok.open("1705071_token.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	
	yylex();
	
	yyoutlog<<endl<<"Total lines: "<<lines<<endl;
	yyoutlog<<"Total errors: "<<errors<<endl;
	
	yyoutlog.close();
	yyouttok.close();
	
	fclose(yyin);
}
