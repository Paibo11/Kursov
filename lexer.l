%{
#include <stdlib.h>
#include "bis.tab.h"
#include <string.h>

%}

%%


[0-9]+ { yylval.number=atoi(yytext); return NUM; }
"("     { return OB; }
")"     { return CB; }
"{"     { return FOB; } 
"}"     { return FCB; }
","     { return COMMA; }
";"     { return SEMICOLON; }

"if"    { return IF; }
"else"  { return ELSE; }
"while" { return WHILE; }


"is"   { return IS; }
"clear"   { return CLEAR; }
"&&"  { return AND;}
"||" { return OR;}
"!" { return NOT;}

"up" { return UP; }
"down" { return DOWN; }
"left" { return LEFT; }
"right" { return RIGHT; }


 /* actions */
"take_order" { return TAKEORDER; }
"give_the_order" { return GIVETHEORDER; }


 /* anything */
[ \t\n]+  ; 

%%
