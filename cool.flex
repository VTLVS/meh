/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Dont remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char buf[MAX_STR_CONST]; /* to assemble string constants */
char *ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Assignment: Add Your own definitions here
 */
int comment_recurses = 0;

%}

/*
 * Define names for regular expressions here.
 */

%START INLINE_COMMENTS MULTILINE_COMMENTS STRING

DARROW          =>
DASSIGN         <-
DLE             <=

DIGITS [0-9]+
LETTERS [A-Za-z]+
TYPE_IDEN [A-Z][A-Za-z0-9_]*
OBJ_IDEN [a-z][A-Za-z0-9_]*
TRUE_LETTER [t][Rr][Uu][Ee]
FALSE_LETTER [f][Aa][Ll][Ss][Ee]

/* COMMENT */
NEST_COMMENT_BEGIN "(*"
NEST_COMMENT_END "*)"
ONELINE_COMMENT_SYMBOL "--"

STRING_CHAR  ["]
WHITE_SPACE_CHAR [ \n\f\r\t\v]
%%


 /* INLINE COMMENTS */
"--" {
    BEGIN INLINE_COMMENTS;
}

<INLINE_COMMENTS>[^\n]* { }

<INLINE_COMMENTS>\n {
    curr_lineno++;
    BEGIN 0;
}

<INLINE_COMMENTS><<EOF>> { 
    yylval.error_msg = "EOF in comment";
    BEGIN 0;
    return ERROR;
}



 /* MULTILINE COMMENTS */
"(*" {
    comment_recurses++;
    BEGIN MULTILINE_COMMENTS;
}

<MULTILINE_COMMENTS>"(*" {
    comment_recurses++;
}

<MULTILINE_COMMENTS>"*)" {
    comment_recurses--;
    if (comment_recurses == 0) {
      BEGIN 0;
    }
}

<MULTILINE_COMMENTS>\n {
    curr_lineno++;
}

 /* [^\n()*]* */
<MULTILINE_COMMENTS>[^\n()*]* { }

<MULTILINE_COMMENTS>[()*] { }


<MULTILINE_COMMENTS><<EOF>> { 
    yylval.error_msg = "EOF in comment";
    BEGIN 0;
    return ERROR;
}

"*)" {
    yylval.error_msg = "Unmatched *)";
    return ERROR;
}




 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

<INITIAL>["]  {
  BEGIN STRING;
  ptr = buf;
}

<STRING>["] {
  BEGIN INITIAL;
  if(ptr < buf + MAX_STR_CONST){
    *ptr = '\0';
    cool_yylval.symbol = stringtable.add_string(buf);
    return STR_CONST;
  }
}
<STRING>"\\\n"  {
  if(ptr < buf + MAX_STR_CONST){
    *ptr++ = '\n';

    if(ptr == buf + MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      return ERROR;
    }
  }
}

<STRING>"\\".  {
  if(ptr < buf + MAX_STR_CONST){
    if(yytext[1] == 'b') *ptr++ = '\b';
    else if(yytext[1] == 't') *ptr++ = '\t';
    else if(yytext[1] == 'n') *ptr++ = '\n';
    else if(yytext[1] == 'f') *ptr++ = '\f';
    else *ptr++ = yytext[1];

    if(ptr == buf + MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      return ERROR;
    }
  }
}
<STRING>"\n"  {
  BEGIN INITIAL;
  if(ptr < buf + MAX_STR_CONST){
    cool_yylval.error_msg = "Unterminated string constant";
    return ERROR;
  }
}

<STRING>"\0"  {
  if(ptr < buf + MAX_STR_CONST){
    ptr = buf + MAX_STR_CONST;
    cool_yylval.error_msg = "String contains null character";
    return ERROR;
  }
}

<STRING><<EOF>>  {
  BEGIN INITIAL;
  if(ptr < buf + MAX_STR_CONST){
    cool_yylval.error_msg = "Unterminated string constant";
    return ERROR;
  }
}

<STRING>. {
  if(ptr < buf + MAX_STR_CONST){
    *ptr++ = yytext[0];
    if(ptr == buf + MAX_STR_CONST){
      cool_yylval.error_msg = "String constant too long";
      return ERROR;
    }
  }
}



 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
 /* Keywords */
<INITIAL>[A-Za-z]+  {
  if(strcasecmp(yytext, "class")==0) 
    return CLASS;
  else if(strcasecmp(yytext, "else")==0) 
    return ELSE;
  else if(strcasecmp(yytext, "fi")==0) 
    return FI;
  else if(strcasecmp(yytext, "if")==0) 
    return IF;
  else if(strcasecmp(yytext, "in")==0) 
    return IN;
  else if(strcasecmp(yytext, "inherits")==0) 
    return INHERITS;
  else if(strcasecmp(yytext, "let")==0) 
    return LET;
  else if(strcasecmp(yytext, "loop")==0) 
    return LOOP;
  else if(strcasecmp(yytext, "pool")==0) 
    return POOL;
  else if(strcasecmp(yytext, "then")==0) 
    return THEN;
  else if(strcasecmp(yytext, "while")==0) 
    return WHILE;
  else if(strcasecmp(yytext, "case")==0) 
    return CASE;
  else if(strcasecmp(yytext, "esac")==0) 
    return ESAC;
  else if(strcasecmp(yytext, "of")==0) 
    return OF;
  else if(strcasecmp(yytext, "new")==0) 
    return NEW;
  else if(strcasecmp(yytext, "isvoid")==0) 
    return ISVOID;
  else if(strcasecmp(yytext, "not")==0) 
    return NOT;
  else REJECT;
}

 /* BOOL CONSTANTS */
<INITIAL>t(?i:rue)  {
    cool_yylval.boolean = 1;
  	return BOOL_CONST;
}

<INITIAL>f(?i:alse) {
  	cool_yylval.boolean = 0;
  	return BOOL_CONST;
}

 /* INTEGER CONSTANTS */
<INITIAL>[0-9]+ {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}

 /* TYPEID */
<INITIAL>[A-Z][A-Za-z0-9_]* {
    cool_yylval.symbol = idtable.add_string(yytext);
    return TYPEID;
}

 /* OBJECTID */
<INITIAL>[a-z][A-Za-z0-9_]* {
    cool_yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}


 /*
  *  The multiple-character operators.
  */
"=>"    { return DARROW; }
"<-"    { return ASSIGN; }
"<="    { return LE; }

 /* NEWLINES */
<INITIAL>"\n" { curr_lineno++; }

 /* WHITESPACE */
<INITIAL>[ \f\r\t\v]+ { }

<INITIAL>"@" { return '@'; }

<INITIAL>"~" { return '~'; }

<INITIAL>"+" { return '+'; }

<INITIAL>"-" { return '-'; }

<INITIAL>"*" { return '*'; }

<INITIAL>"/" { return '/'; }

<INITIAL>"=" { return '='; }
 
<INITIAL>":" { return ':'; }

<INITIAL>"<" { return '<'; }

<INITIAL>"," { return ','; }

<INITIAL>"." { return '.'; }

<INITIAL>";" { return ';'; }

<INITIAL>"}" { return '}'; }

<INITIAL>")" { return ')'; }

<INITIAL>"(" { return '('; }

<INITIAL>"{" { return '{'; }


 /*
    When all else fails
 */
. {
  buf[0] = yytext[0];
  buf[1] = '\0';

  cool_yylval.error_msg = buf;
  return (ERROR);
}

%%