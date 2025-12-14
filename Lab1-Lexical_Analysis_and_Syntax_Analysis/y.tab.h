/* A Bison parser, made by GNU Bison 2.7.  */

/* Bison interface for Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2012 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     IF = 258,
     ELSE = 259,
     FOR = 260,
     WHILE = 261,
     DO = 262,
     SWITCH = 263,
     CASE = 264,
     DEFAULT = 265,
     BREAK = 266,
     CONTINUE = 267,
     GOTO = 268,
     RETURN = 269,
     INT = 270,
     CHAR = 271,
     DOUBLE = 272,
     VOID = 273,
     FLOAT = 274,
     PRINTF = 275,
     ADDOP = 276,
     MULOP = 277,
     RELOP = 278,
     ASSIGNOP = 279,
     LOGICOP = 280,
     NOT = 281,
     LPAREN = 282,
     RPAREN = 283,
     LCURL = 284,
     RCURL = 285,
     LTHIRD = 286,
     RTHIRD = 287,
     COMMA = 288,
     SEMICOLON = 289,
     COLON = 290,
     ID = 291,
     CONST_INT = 292,
     CONST_FLOAT = 293,
     INCOP = 294,
     DECOP = 295
   };
#endif
/* Tokens.  */
#define IF 258
#define ELSE 259
#define FOR 260
#define WHILE 261
#define DO 262
#define SWITCH 263
#define CASE 264
#define DEFAULT 265
#define BREAK 266
#define CONTINUE 267
#define GOTO 268
#define RETURN 269
#define INT 270
#define CHAR 271
#define DOUBLE 272
#define VOID 273
#define FLOAT 274
#define PRINTF 275
#define ADDOP 276
#define MULOP 277
#define RELOP 278
#define ASSIGNOP 279
#define LOGICOP 280
#define NOT 281
#define LPAREN 282
#define RPAREN 283
#define LCURL 284
#define RCURL 285
#define LTHIRD 286
#define RTHIRD 287
#define COMMA 288
#define SEMICOLON 289
#define COLON 290
#define ID 291
#define CONST_INT 292
#define CONST_FLOAT 293
#define INCOP 294
#define DECOP 295



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
