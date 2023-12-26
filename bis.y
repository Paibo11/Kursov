%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "bis.tab.h"

int yylex(void);

extern FILE* yyin;
extern FILE* yyout;

void yyerror(char *str);

int yywrap(){
    return 1;
} 

// создание дерева
struct ast *newAst(int nodetype, struct ast *l, struct ast *r);
struct ast *newNum(int integer);
struct ast *newFlow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el);

// освобождение памяти, занятой деревом
void treeFree(struct ast *);
int eval(struct ast *a);
struct ast{
    int nodetype;
    struct ast *l;
    struct ast *r;
};

struct numval{
    int nodetype;			// тип K
    int number;
};

struct flow{
    int nodetype;			// тип I или W
    struct ast *cond;		// условие
    struct ast *tl;		    // действие
    struct ast *el;		    // else
};

void robotFunc(int operations, int step);
int inRoom(int step);


int Flag;
int count = 0;

int ArrRobot[2];// координаты робота
int tray = 0; // наличие заказа
int ArrRoom[100][100];

// вычисление передвижение робота
void move(int step);

// действия робота
int take_order();
int give_the_order();

%}

%union{
    struct ast *a;
    int number;
}

%token OB CB FCB FOB COMMA SEMICOLON
%token IF ELSE WHILE
%token IS CLEAR
%token UP DOWN LEFT RIGHT
%token TAKEORDER GIVETHEORDER 
%token <number> NUM
%type <a> command  condition else action base move operation lenth

%%
commands:
| commands command { eval($2); treeFree($2); }
;

command: IF OB condition CB FOB action FCB else { $$ = newFlow('I', $3, $6, $8); }
| IF OB condition CB FOB action FCB { $$ = newFlow('I', $3, $6, NULL);  }
| WHILE OB condition CB FOB action FCB { $$ = newFlow('W', $3, $6, NULL);  }
| action { $$ = newAst('a', $1, NULL); }
;

else: ELSE FOB action FCB { $$ = newAst('e', $3, NULL); }
;
condition: move IS CLEAR { $$ = newAst('c', $1, NULL); }
;

action: move base { $$ = newAst('m', $1, $2); }
| operation OB CB SEMICOLON{$$ = newAst('o', $1, NULL);}
;

move: UP { $$ = newAst('u', NULL, NULL); }
| DOWN { $$ = newAst('d', NULL, NULL); }
| RIGHT { $$ = newAst('r', NULL, NULL); }
| LEFT { $$ = newAst('l', NULL, NULL); }
;

operation: TAKEORDER { $$ = newAst('t', NULL, NULL);}
| GIVETHEORDER { $$ = newAst('g', NULL, NULL);}
;

base: OB lenth CB SEMICOLON { $$ = newAst('b', $2, NULL); }
;

lenth: NUM { $$ = newNum($1); }

%%

int main(void){
    char *area = "Area.txt";
    FILE* areatext = fopen(area, "r");
    char buffer[256];
    int n = atoi(fgets(buffer, sizeof(buffer), areatext));
    int  i = 0;
  
    //Значения стенок в комнате
    while((fgets(buffer, sizeof(buffer), areatext))!=NULL)
            {
                // printf("%s", buffer);
                for(int j = 0; j < n * 2; j+=2){
                    ArrRoom[i][j/2] = buffer[j] - '0';
                }
                i++;
            }
            fclose(areatext);
    
    
    // Вывод комнаты
    for(int i = 0; i < n; i++){
        for(int j = 0; j < n; j++){
            printf("%i ", ArrRoom[i][j]);
        }
        printf("\n");
    }

    char *commandFileName = "command.txt";
    FILE* commandFile = fopen(commandFileName, "r");
    if (commandFile == NULL){
        fprintf(yyout, "%d. Can't open file %s", count, commandFileName);
        exit(1);
    }
    
    // printf("строка: %i\n", ArrRoom[2][3]);
    char *robot = "ArrRobot.txt";
    FILE* robotFile = fopen(robot, "r");
    if (robotFile == NULL){
        fprintf(yyout, "%d. Can't open file %s", count, robot);
        exit(1);
    }

    fseek(robotFile, 0, SEEK_SET);
    fscanf(robotFile, "%d ", &ArrRobot[0]);
    fscanf(robotFile, "%d", &ArrRobot[1]);
    printf("%i - size room, position (%d, %d), check result.txt\n", n, ArrRobot[0], ArrRobot[1]);
    char *resultFileName = "result.txt";
    FILE* resultFile = fopen(resultFileName, "w");

    yyin = commandFile;
    yyout = resultFile;

    
    yyparse();

    fclose(yyin);
    fclose(robotFile);
    fclose(yyout);
    
    return 0;
}




void yyerror(char *str){
    count++;
    fprintf(yyout ,"%d. error: %s in line\n", count, str);
    exit(1);
}


struct ast *newAst(int nodetype, struct ast *l, struct ast *r){
    struct ast *a = malloc(sizeof(struct ast));

    if (!a){
        yyerror("out of space");
        exit(0);
    }
    a->nodetype = nodetype;
    a->l = l;
    a->r = r;
    return a;
}

struct ast *newNum(int i){
    struct numval *a = malloc(sizeof(struct numval));

    if (!a){
        yyerror("out of space");
        exit(0);
    }
    a->nodetype = 'K';
    a->number = i;
    return (struct ast *)a;
}

struct ast *newFlow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el){
    struct flow *a = malloc(sizeof(struct flow));

    if(!a) {
        yyerror("out of space");
        exit(0);
    }
    a->nodetype = nodetype;
    a->cond = cond;
    a->tl = tl;
    a->el = el;
    return (struct ast *)a;
}

int eval(struct ast *a){
    // просто значение, котрое возвращает функция
    int val;    
    int operations;
 
    switch(a->nodetype){
        case 'K': val = ((struct numval *)a)->number; break;
        case 'a':
            eval(a->l); 
            break;
       
        case 'c': 
            Flag = eval(a->l); 
            val = inRoom(1);
            break;
        case 'e': 
            eval(a->l); 
            break;
        case 'm':
            Flag = eval(a->l); 
            eval(a->r); 
            break;
        case 'b': 
            count++;
            val = eval(a->l); 
            move(val);
            break;
        case 'o':
            count++;
            eval(a->l);
            break;   
        case 't': //take order
            take_order();
            break;
        case 'g'://give the order
            give_the_order();
            break;
        case 'l': // left
            val = 'l';
            break;
        case 'r': // right    
            val = 'r';
            break;                 
        case 'u': // up
            val = 'u';
            break;     
        case 'd': // down
            val = 'd';
            break;
        
        case 'I':
            if(eval(((struct flow *)a)->cond) == 'T') { // проверка условия ветки true
                if(((struct flow *)a)->tl) {
                    eval(((struct flow *)a)->tl);
                } 
                else{
                    val = 'F'; // значение по умолчанию
                }
            }
            else { // false
                if(((struct flow *)a)->el) {
                    eval(((struct flow *)a)->el);
                } 
                else {
                    val = 'F'; // значение по умолчанию
                }		
            }
            break;
        case 'W':
            val = 'F'; // значение по умолчанию

            if(((struct flow *)a)->tl) {
                while(eval(((struct flow *)a)->cond) == 'T'){
                    eval(((struct flow *)a)->tl);
                }
            }
            break;
    }
    return val;
}


// Проверка куда хочет идти робот, чтоб там было свободно
int inRoom(int step){
    for (int i = 1; i <= step; i++){
        switch(Flag){
            case 'l':
                if (ArrRoom[ArrRobot[0] ][ArrRobot[1]- i] == 1){
                    return 'F';
                }
                break;
            case 'r':
                if (ArrRoom[ArrRobot[0] ][ArrRobot[1]+ i] == 1){
                    return 'F';
                }
                break;
            case 'd':
                if (ArrRoom[ArrRobot[0] + i][ArrRobot[1] ] == 1){
                    return 'F';
                }
                break;
            case 'u':
                if (ArrRoom[ArrRobot[0] - i][ArrRobot[1]] == 1){
                    return 'F';
                }
                break;
        }
        
    }
    return 'T';
}

void printMove(){
    fprintf(yyout, "%d) Робот-официант перешёл на (%d,%d)\n", count, ArrRobot[0] , ArrRobot[1]);
}

void move(int step){
    switch(inRoom(step)){
        case 'T':
            switch(Flag){
                case 'l':
                    ArrRobot[1] -= step;
                    printMove();
                    break;
                case 'r':
                    ArrRobot[1] += step;
                    printMove();
                    break;
                case 'd':
                    ArrRobot[0] += step;
                    printMove();
                    break;
                case 'u':
                    ArrRobot[0] -= step;
                    printMove();
                    break;
            }
            break; 
        case 'F':
            switch(Flag){
                case 'l':
                    fprintf(yyout, "%d) Erorr: робот пытается пройти в координату (%d,%d) через стену\n", count, ArrRobot[0] , ArrRobot[1] - step);
                    exit(0);
                    break;
                case 'r':
                    fprintf(yyout, "%d) Erorr: робот пытается пройти в координату (%d,%d) через стену\n", count, ArrRobot[0] , ArrRobot[1] + step);
                    exit(0);
                    break;
                case 'd':
                    fprintf(yyout, "%d) Erorr: робот пытается пройти в координату (%d,%d) через стену\n", count, ArrRobot[0] + step , ArrRobot[1] );
                    exit(0);
                    break;
                case 'u':
                    fprintf(yyout, "%d) Erorr: робот пытается пройти в координату (%d,%d) через стену\n", count, ArrRobot[0] - step , ArrRobot[1] );
                    exit(0);
                    break;
            }
            break;
    }
}

int check_order(int number){
    if ( ArrRoom[ArrRobot[0]][ArrRobot[1]] == number ){
        return 'T';
    } else {
        return 'F';
    }
}

int take_order(){
    if (tray == 0 && check_order(2) == 'T'){
        tray = 1;
        fprintf(yyout, "%d) Робот-официант взял заказ\n", count);
    } else {
        fprintf(yyout, "%d) Робот-официант на (%d, %d) не может получить заказ\n", count, ArrRobot[0], ArrRobot[1]);
    }
}

int give_the_order(){
    if (tray == 1 && check_order(3) == 'T'){
        tray = 0;
        ArrRoom[ArrRobot[0]][ArrRobot[1]] = 0;
        fprintf(yyout, "%d) Робот-официант отдал заказ\n", count);
    } else {
        fprintf(yyout, "%d) Робот-официант на (%d, %d) не может отдать заказ\n", count, ArrRobot[0], ArrRobot[1]);
    }
}


void treeFree(struct ast *a){
    switch(a->nodetype){
        
        case 'm':
            treeFree(a->r);

        case 'c':
        case 'b':
        case 'a':
        case 'e':
        case 'o':
            treeFree(a->l);

       
        case 'K':
        case 'l':
        case 'r':
        case 'u':
        case 'd':
        case 'g':
        case 't':
        break;

        case 'I':
        case 'W':
            free( ((struct flow *)a)->cond);
            if( ((struct flow *)a)->tl) free( ((struct flow *)a)->tl);
            if( ((struct flow *)a)->el) free( ((struct flow *)a)->el);
            break;

        default: fprintf(yyout, "%d. internal error: free bad node %c\n", count, a->nodetype);
    }
}