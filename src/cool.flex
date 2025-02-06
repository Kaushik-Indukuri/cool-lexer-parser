/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include "cool_parse.h"
#include "utils.h"

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
extern FILE *fin; /* we read from this file */
#undef YY_INPUT
#define YY_INPUT(buf, result, max_size)                                        \
  if ((result = fread((char *)buf, sizeof(char), max_size, fin)) < 0)          \
    YY_FATAL_ERROR("read() in flex scanner failed");

extern int curr_lineno;
/*
 *  Add Your own definitions here
 */

/* Buffer for string literals */
char string_buf[MAX_STR_CONST];
int string_len;
int comment_depth;

/* Helper function declarations */
void clear_string_buf();
void append_to_string_buf(const char *text);
void report_error(const char *msg);
int handle_str_error(const char *msg);
int too_long_error();


%}

%option noyywrap

/* Define start conditions to handle strings */
%x IN_STRING
%x IN_ESCAPE
%x STRING_ERROR

/* Define start conditions to handle comments */
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT

/*
 * Define names for regular expressions here.
 */

digit       [0-9]
/* Type identifier */
t_idf       [A-Z][0-9a-zA-Z_]*
/* Object identifier */
o_idf       [a-z][0-9a-zA-Z_]*
single_symbols     [\+\-\*\/\~\<\=\,\.\;\:\(\)\@\{\}]

%%

\n          { curr_lineno++; }

[ \t\r\f\v]+     { /* Ignore whitespace */ }

{digit}+    { cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }

{single_symbols}   {return yytext[0];}
"=>"        {return DARROW;}
"<="        {return LE;}
"<-"        {return ASSIGN;}

    /* --------------------------------------------------------------------------------------------- */

    /* Entry rule for single-line comments. */
"--"                         { BEGIN(SINGLE_LINE_COMMENT);}
<SINGLE_LINE_COMMENT>\n      { curr_lineno++; BEGIN(INITIAL); }
<SINGLE_LINE_COMMENT><<EOF>> {}

    /* --------------------------------------------------------------------------------------------- */

    /* Entry rule for nested multi-line comments. */
"(*"                        { comment_depth = 1; BEGIN(MULTI_LINE_COMMENT); }
<MULTI_LINE_COMMENT>"(*"    { comment_depth++; }
<MULTI_LINE_COMMENT><<EOF>> { BEGIN(INITIAL); return handle_str_error("EOF in comment"); }
<MULTI_LINE_COMMENT>\n      { curr_lineno++; }
<MULTI_LINE_COMMENT>"*)" {
    comment_depth--;
    if (comment_depth == 0) {
        BEGIN(INITIAL);  // Return to initial state if all comments closed.
    }
}
<SINGLE_LINE_COMMENT,MULTI_LINE_COMMENT>. {/* Consume any characters within comments without action. */}

    /* Handle unmatched closing of a multi-line comment. */
"*)"    { BEGIN(INITIAL); return handle_str_error("Unmatched *)"); }

    /* --------------------------------------------------------------------------------------------- */

[Cc][Ll][Aa][Ss][Ss]     { return CLASS; }
[Ee][Ll][Ss][Ee]         { return ELSE; }
[Ff][Ii]                 { return FI; }
[Ii][Ff]                 { return IF; }
[Ii][Nn]                 { return IN; }
[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss] { return INHERITS; }
[Ii][Ss][Vv][Oo][Ii][Dd] { return ISVOID; }
[Ll][Ee][Tt]             { return LET; }
[Ll][Oo][Oo][Pp]         { return LOOP; }
[Pp][Oo][Oo][Ll]         { return POOL; }
[Tt][Hh][Ee][Nn]         { return THEN; }
[Ww][Hh][Ii][Ll][Ee]     { return WHILE; }
[Cc][Aa][Ss][Ee]         { return CASE; }
[Ee][Ss][Aa][Cc]         { return ESAC; }
[Nn][Ee][Ww]             { return NEW; }
[Oo][Ff]                 { return OF; }
[Nn][Oo][Tt]             { return NOT; }
[t][Rr][Uu][Ee]         { cool_yylval.boolean = true; return BOOL_CONST; }
[f][Aa][Ll][Ss][Ee]     { cool_yylval.boolean = false; return BOOL_CONST; }

{t_idf}         {cool_yylval.symbol = idtable.add_string(yytext); return TYPEID; }
{o_idf}         {cool_yylval.symbol = idtable.add_string(yytext); return OBJECTID; }

    /* --------------------------------------------------------------------------------------------- */

\" {
    /* Start string literal */
    clear_string_buf();  /* Reset the string buffer */
    string_len = 0;
    BEGIN(IN_STRING);  /* Enter IN_STRING state */
}

<IN_STRING>\" {
    /* IN_STRING state: handle characters inside string */
    cool_yylval.symbol = stringtable.add_string(string_buf);  /* Save string */
    BEGIN(INITIAL);  /* Return to the initial state */
    return STR_CONST;  /* Return the string constant token */
}

<IN_STRING>\\ {
    /* Handle escape sequences by switching to IN_ESCAPE state */
    BEGIN(IN_ESCAPE);  /* Enter IN_ESCAPE state */
}

<IN_STRING>\n {
    /* Handle unterminated strings (newline in the middle of a string) */
    curr_lineno++;
    BEGIN(INITIAL);
    return handle_str_error("Unterminated string constant");
}

<IN_STRING,IN_ESCAPE><<EOF>> {
    BEGIN(INITIAL);
    return handle_str_error("EOF in string constant");
}

<IN_STRING,IN_ESCAPE>\0      {
    BEGIN(STRING_ERROR);
    return handle_str_error("String contains null character");
}

<IN_ESCAPE>n          { append_to_string_buf("\n"); BEGIN(IN_STRING); }
<IN_ESCAPE>t          { append_to_string_buf("\t"); BEGIN(IN_STRING); }
<IN_ESCAPE>b          { append_to_string_buf("\b"); BEGIN(IN_STRING); }
<IN_ESCAPE>f          { append_to_string_buf("\f"); BEGIN(IN_STRING); }
<IN_ESCAPE>\\         { append_to_string_buf("\\"); BEGIN(IN_STRING); }

<IN_ESCAPE>. {
    /* Handle invalid escape sequences */
    append_to_string_buf(yytext);  /* Add the invalid character */
    BEGIN(IN_STRING);  
}

<IN_ESCAPE>\n         {
    /* escaped newlines */
    if(string_len+1 >= MAX_STR_CONST){
        BEGIN(STRING_ERROR);
        return too_long_error();
    }
    append_to_string_buf(yytext);
    curr_lineno++;
    BEGIN(IN_STRING);
}

<IN_STRING>. {
    /* Handle regular characters in string */
    if (string_len >= MAX_STR_CONST - 1) {
        return too_long_error();  /* Handle long strings */
    }
    append_to_string_buf(yytext);  /* Add regular character to the string */
}

<STRING_ERROR>\"      {BEGIN(INITIAL);}
<STRING_ERROR>\n      { curr_lineno++; BEGIN(INITIAL);}
<STRING_ERROR>\\\n    {curr_lineno++;}
<STRING_ERROR>.       {}


.       {
    /* Catch all other characters and report errors */
    report_error(yytext);
    return ERROR;
}


 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

%%

    /* --------------------------------------------------------------------------------------------- */

/* Helper Functions */

void clear_string_buf() {
    /* Clear the string buffer */
    string_buf[0] = '\0';
    string_len = 0;
}

void append_to_string_buf(const char *text) {
    /* Append text to the string buffer */
    if (string_len + strlen(text) < MAX_STR_CONST) {
        strcat(string_buf, text);
        string_len += strlen(text);
    } else {
        too_long_error();
    }
}

void report_error(const char *msg) {
    /* Report an error */
    cool_yylval.error_msg = msg;
}


int handle_str_error(const char *msg) {
    /* Handle string-related errors */
    report_error(msg);
    clear_string_buf();
    return ERROR;
}

int too_long_error() {
    /* Handle strings that exceed the maximum length */
    report_error("String constant too long");
    clear_string_buf();
    return ERROR;
}