%option noyywrap

%{

#include"symbol_table.h"

#define YYSTYPE symbol_info*

#include "y.tab.h"


extern YYSTYPE yylval;
extern symbol_table *symtbl;
void yyerror(char *);

string loglist;

extern int lines;
extern int errors;

extern ofstream outerror,outlog;

%}

delim	 [ \t\v\r\f]
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

{manydec} {
			loglist="At line "+to_string(lines)+": Error: Too many decimal points "+yytext+"\n"+"\n";
			errors++;
			outlog<<loglist;
			outerror<<loglist;
		  }	  
if		  {
			return IF;
		  }
else	  {
			return ELSE;
		  }
for	  	  {
			return FOR;
		  }
while  	  {
			return WHILE;
		  }
do	  	  {
		   	return DO;
		  }
break  	  {
		   	return BREAK;
		  }
int  	  {
		   	return INT;
		  }
char  	  {
		   	return CHAR;
		  }
float  	  {
		   	return FLOAT;
		  }
double    {
		   	return DOUBLE;
		  }		
void  	  {
		   	return VOID;
		  }
return    {
		   	return RETURN;
		  }
switch    {
		   	return SWITCH;
		  }
case  	  {
		   	return CASE;
		  }
default	  {
		   	return DEFAULT;
		  }
continue  {
		   	return CONTINUE;
		  }
printf    {
			return PRINTLN;
		  }
"+"|"-"	  {
			symbol_info *s = new symbol_info((string)yytext,"ADDOP");
			yylval = (YYSTYPE)s;
			return ADDOP;
		  }
"*"|"/"|"%"	  {
			symbol_info *s = new symbol_info((string)yytext,"MULOP");
			yylval = (YYSTYPE)s;
			return MULOP;
		  }	
"++"	  {
		   	return INCOP;
		  }	
"--"      {
		   	return DECOP;
		  }	
	
"<"|"<="|">"|">="|"=="|"!="	  {
			symbol_info *s = new symbol_info((string)yytext,"RElOP");
			yylval = (YYSTYPE)s;
			return RELOP;
		  }			  
	
"="	      {
			return ASSIGNOP;
		  }	
	
"&&"|"||" {
		   	symbol_info *s = new symbol_info((string)yytext,"LOGICOP");
			yylval = (YYSTYPE)s;
			return LOGICOP;
		  }	
	
"!"	  {
		   return NOT;
		  }	
	
"("	  	  {
		   	return LPAREN;
		  }	
")"	  	  {
		   	return RPAREN;
		  }			  
"{"	  	  {
		   	return LCURL;
		  }	
"}"	  	  {
		   	return RCURL;
		  }	
"["	  	  {
		   	return LTHIRD;
		  }	
"]"	  	  {
		   	return RTHIRD;
		  }	
","	  	  {
		   	return COMMA;
		  }			  
";"	  	  {
		   	return SEMICOLON;
		  }	
{integers}  {
			    symbol_info *s = new symbol_info((string)yytext,"CONST_INT");
				yylval = (YYSTYPE)s;
				return CONST_INT;
		    }

{floats}  {
			symbol_info *s = new symbol_info((string)yytext,"CONST_FLOAT");
			yylval = (YYSTYPE)s;
			return CONST_FLOAT;
		  }	 
{illform} {
			loglist="At line "+to_string(lines)+": Error: Ill formed number "+yytext+"\n"+"\n";
			errors++;
			outlog<<loglist;
			outerror<<loglist;
		  }	
{invalid} {
			loglist="At line "+to_string(lines)+": Error: Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence "+yytext+"\n"+"\n";
			errors++;
			outlog<<loglist;
			outerror<<loglist;
		  }	 	
{id}      {
			symbol_info* s = new symbol_info(yytext,"ID");
			yylval = (YYSTYPE) s;
			
			return ID;
		  }	
.           {
			loglist="At line "+to_string(lines)+": Error: Unrecognized character "+yytext+"\n"+"\n";
			errors++;
			outlog<<loglist;
			outerror<<loglist;
		    }
<<EOF>> {return 0;}
		      		  	  			  		  
%%

