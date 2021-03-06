---
title: Using FSLexYacc, the F# lexer and parser
description: How to set up your project to work with the lexing and parsing F# tools.
date: 2020-06-08
tags:
    - F#
    - dotnet
    - FSLexYacc
    - lexer
    - parser
---

Lately I've been playing around with F# and specifically with using it for lexing and parsing. I've had to dig around a bit to get all the information needed to understand how to get a simple project up and running so I thought compiling that information would be a good idea. 

This is going to be a tutorial that will help you setup a simple F# console application that will read the user's input and will try to evaluate it based on the basic math syntax that we will declare. 

It should be able to evaluate input like: 
1. `1 + 1` 
2. `(1 + -2) - (6 / 3)`

Pretty advanced stuff, I know :D

If you don't feel like typing everything and just want to download the [code][6] and start tinkering then try the following:

```
npm install -g github-files-fetcher
github-files-fetcher -url="https://github.com/ThanosPapathanasiou/personal-blog/tree/master/code-examples/lexing-and-parsing"
code lexing-and-parsing
```

Otherwise, here's a step by step instruction to help you get up and running.

#### Setting up a project to work with FsLexYacc
---

Let's start with a brand new F# console app:

``` bash
mkdir lexing-and-parsing
cd lexing-and-parsing
dotnet new console -lang=F#
dotnet run
```

That should give us the default console output:

```
Hello world from F#
```

In order to use the F# lexer and parser we'll need to add the `FsLexYacc` nuget package as a reference. So our next step is to run:

``` bash
dotnet add package FsLexYacc
```

The way lexing and parsing works in F# is by generating F# code from two files, a .fsl one that contains the rules for the lexer and a .fsy one that contains the rules for the parser.

Lets create them:

``` bash
echo '' > Lexer.fsl
echo '' > Parser.fsy
``` 

Next we'll need to edit the .fsproj file and add these two lines in the ```<PropertyGroup>```

``` xml
    <FsLexToolExe>fslex.dll</FsLexToolExe>
    <FsYaccToolExe>fsyacc.dll</FsYaccToolExe>
```

and these ones in the ```<ItemGroup>```

``` xml
    <FsYacc Include="Parser.fsy">
      <OtherFlags>--module Parser</OtherFlags>
    </FsYacc>

    <FsLex Include="Lexer.fsl">
      <OtherFlags>--module Lexer --unicode</OtherFlags>
    </FsLex>

    <Compile Include="Parser.fsi" />
    <Compile Include="Parser.fs" />
    <Compile Include="Lexer.fs" />
```

What these changes do is basically tell the F# compiler that it has the fslex and fsyacc tools at it's disposal and it will have to run the transformation of the  `Lexer.fsl` and `Parser.fsy` files ***before*** the compilation starts. We can even specify the module name that the generated code is part of. I chose to keep it simple with Lexer and Parser.

You will notice also that we are including three files (`Parser.fsi`, `Parser.fs` and `Lexer.fs`) that don't exist as references in our project. These files will be generated from our .fsl and .fsy files by the lexer and parser tools as the output of the transformation I mention above.

At this point our project is setup to use the lexer and parser however since we don't have anything in the `Lexer.fsl` and `Parser.fsy` files the compilation will fail.

So lets add something!

#### Basic lexing
---

Lexing is the process of taking raw text and converting it into a sequense of tokens. A token is a string with an assigned meaning. 

In our case we'll try to create a lexer and parser that will do something basic, evaluate simple mathematic operations. i.e. 1 + 1 should return 2, -1 + 2 = 1, (1 + 2) - (4 + 1) = -2 etc

So, our lexer should identify these tokens:

- Number
- Operator
- Left Parenthesis
- Right Parenthesis
- End of input

This is the finished Lexer.fsl that tokenizes according to the above rules.

``` fslex
{
open FSharp.Text.Lexing
open Parser

let lexeme lexbuf = LexBuffer<_>.LexemeString lexbuf
}

let digit = ['0'-'9']
let operator = ['+' '-' '*' '/']
let whitespace = [' ' '\t']

rule tokenize = parse
| whitespace        { tokenize lexbuf }
| ['-']?digit+      { Number ( System.Int32.Parse( lexeme lexbuf ) ) }
| operator          { OP ( lexeme lexbuf ) }
| '('               { LPAREN }
| ')'               { RPAREN }
| eof               { EOF }
| _                 { lexeme lexbuf |> sprintf "Parsing error: %s" |> failwith }
```

Let's go through it and I'll explain it bit by bit. 

First bit:

```
{
open FSharp.Text.Lexing
open Parser

let lexeme lexbuf = LexBuffer<_>.LexemeString lexbuf
}
```

I mentioned earlier that Lexer.fsl isn't written in F# but a custom language. That is true for the rest of this file but not for the bits between the { and } 

Here we using F# to open the [FSharp.Text.Lexing][3] namespace that we need to access the input buffer `LexBuffer` that allows us have a look into what part is being tokenized.

We are also opening our own Parser module (the one that will be autogenerated by Parser.fsy). We need that because the definition of the tokens that we want to output is there.

Finally, we are declaring a small helping function that returns the matching characters of a token as a string. i.e. the characters 1, 2, 3 would be returned as "123" 

Second bit:
```
let digit = ['0'-'9']
let operator = ['+' '-' '*' '/']
let whitespace = [' ' '\t']

rule tokenize = parse
| whitespace        { tokenize lexbuf }
| ['-']?digit+      { lexeme lexbuf |> System.Int32.Parse |> Number  }
| operator          { lexeme lexbuf |> OP }
| '('               { LPAREN }
| ')'               { RPAREN }
| eof               { EOF }
| _                 { lexeme lexbuf |> sprintf "Parsing error: %s" |> failwith }
```

In this part the actual tokenization process happens. 

First, for readability, we define what a digit, operator and whitespace are.
Then we have the actual tokenization function `rule tokenize = parse` followed by all the cases we support (with the final one `_` handling all the undesired states by just returning an error). These cases are matching against a kind of regular expression.

This is what it does

1. In case of whitespace, ignore it. (get the next token)
2. In case of multiple digits even with a - in front then get that string ( `lexeme lexbuf` ) then parse it into a System.Int32 and then return that int32 as a Number token. (this Number token will be defined in our Parser.fsy file)
3. In case of a string matching any of our operators then get that string and return the OP symbol
4. In case of a left parenthesis then return the LPAREN symbol
5. In case of a right parenthesis then return the RPAREN symbol
6. When we reach the end of the input given then return the EOF symbol
7. In case we get a character that doesn't match any of the above rules then we raise an exception.

Remember: Everything between { and } is valid F# code, that's why we are able to use `|>` to cast to the Number and OP symbols. 

As an example, if we gave 
`(1 + 2) + -3` 
the symbols should be 
`LPAREN NUMBER(1) OP("+") NUMBER(2) RPAREN OP("+") NUMBER(-3) EOF`

That looks good, let's see how to do the parsing now!

#### Basic Parsing
---

Parsing is the process of reading a stream of tokens and attempting to match them to a set of rules with the end result being an abstract syntax tree. 

In layman's terms, lexing is the process of defining the alphabet (the actual characters allowed) of your language while parsing is the process of defining the syntax (i.e. subject - verb - object)

The syntax that we want to be able to understand is based upon basic math rules.

1. perform an operation between two numbers: `NUMBER OP NUMBER`
2. perform an operation between a number and another operation that uses parentheses: `NUMBER OP (NUMBER OP NUMBER)`

Here's the end result:
``` fsyacc
%{
let getOp op = 
    match op with 
    | "+" -> ( + )
    | "-" -> ( - )
    | "/" -> ( / )
    | "*" -> ( * )
    | _ -> failwith "unknown operator"
%}

%token <int> Number
%token <string> OP
%token EOF LPAREN RPAREN
%start parse
%type <int> parse
%%

parse: expr EOF        	     { $1 }

expr: Number                 { $1 }
    | expr OP expr           { $1 |> (getOp $2) <| $3 }
    | LPAREN expr RPAREN     { $2 }
```

Like with the lexing above, let's go through it bit by bit. 

The first part consists of the following F# code. 

``` fsharp
%{
let getOp op = 
    match op with 
    | "+" -> ( + )
    | "-" -> ( - )
    | "/" -> ( / )
    | "*" -> ( * )
    | _ -> failwith "unknown operator"
%}
```
Here, we are declaring an F# function that matches the operator symbols to actual F# mathematical functions and returns them. So it takes a `string` argument as input and returns a function of type: `Int->Int->Int` (i.e. it takes two `Int` arguments and returns a result of type `Int`)

Next, we have the token definitions. Notice that the Tokens `Number` and `OP` have .net types.

```
%token <int> Number
%token <string> OP
%token EOF LPAREN RPAREN
```

Right after that we specify to the parser what rule it should use as a start and what .net type the parsing operation will return:

```
%start parse
%type <int> parse
%%
```

Finally, we have the actual rules. These rules declare what syntax is valid in our *language*.

Let's go through them one at a time.

```
parse: expr EOF        	     { $1 }
```

We are parsing a single expression and we expect the EOF symbol right after. The part between the { and } is a sort of substitution. The `parse` rule expects an expression and an `EOF` symbol and we only care about the first argument, hence $1 (i.e. try to parse the `expr`)

```
expr: Number                 { $1 }
    | expr OP expr           { $1 |> (getOp $2) <| $3 }
    | LPAREN expr RPAREN     { $2 }
```

This is a bit more complicated. You can see that an `expr` can be different things. The rule is also recursive. 

It basically states that an expression can be 
- a number
- an expression followed by an operator symbol and another expression
- a left parenthesis symbol followed by an expression followed by a right parenthesis symbol.

You can also notice that in the second case, we are calling the `getOp` function we declared earlier instead of just propagating the operator symbol. So in the generated code the `+` operator will not be a simple `string` type variable but an `Int->Int->Int` function.

Let's try and use the input from the lexing example.

The initial input was 
```
(1 + 2) + -3
``` 
and the symbols we got were:
```
LPAREN NUMBER(1) OP("+") NUMBER(2) RPAREN OP("+") NUMBER(-3) EOF
```

The symbols are matched against the `parse` rule and they give us this abstract syntax tree.

```
                   expr op expr
                  /     |      \
                 /    OP("+")   NUMBER(-3)
                /            
       LPAREN expr RPAREN    
               |                
          expr op expr         
         /     |      \         
NUMBER(1)    OP("+")   NUMBER(2) 
```

That would basically be translated and executed like this:

1. `NUMBER(1) OP("+") NUMBER(2)` translates to `1 |> (+) <| 2` and results in 3
2. the evaluation of that expression becomes the first argument for the next expression
3. `NUMBER(3) OP("+") NUMBER(-3)` translates to `3 |> (+) <| -3` and results in 0
4. the evaluation of that expression becomes the value that `parse` returns.

#### Tying it all together 
---

We have the lexer and parser all ready. If's finally the time to use them!

Open `Program.fs` and replace the code with this:

``` fsharp
open System
open FSharp.Text.Lexing
open Lexer
open Parser

let evaluate (input:string) =
  let lexbuf = LexBuffer<char>.FromString input
  let output = Parser.parse Lexer.tokenize lexbuf
  string output

[<EntryPoint>]
let main argv =

    printfn "Press Ctrl+c to Exit"

    while true do
        printf "Evaluate > "
        let input = Console.ReadLine()
        try
            let result = evaluate input
            printfn "%s" result
        with ex -> printfn "%s" (ex.ToString())

    0 // return an integer exit code
```

This is a very simple `main` function that will continue to loop until the user closes the program. It just takes the user's input and calls the `evaluate` function declared in the beginning of the program. 

The `evaluate` function does a couple interesting things.

First, it creates a lex buffer from the input string given by the user: `let lexbuf = LexBuffer<char>.FromString input`

Next, it uses that buffer and the `Lexer.tokenize` function we declared in the lexer as input to the `Parser.Parse` function we declared in our parser : `let output = Parser.parse Lexer.tokenize lexbuf`

Finally, it converts the output from `int` to `string`

That's it. Now we can open our terminal and type `dotnet run` and we should be greeted with: 

``` bash
Press Ctrl+c to Exit
Evaluate > 
```

Try entering: `(1 + 2) + -3` and see if it will evaluate to `0`. Try any number of complicated expressions and see if the result matches what you expect. Have a look at what happens if you use illegal characters. 

Try replacing the `expr` with this equivalent:

```
expr: Number                 { $1 }
    | OP expr expr           { (getOp $1) $2 $3 }
    | LPAREN expr RPAREN     { $2 }
```

After we recompile, suddenly our parser will be expecting that we use [polish notation!][5] 

If you want to understand this a bit better I would encourage you to start tinkering with the parser. Try coming up with your own rules!

As always,

Happy coding!

` `  
` `  

---
###### Some interesting sites to have a look

If you want to have a look at the final project, instead of typing it you can get it [here][6]

If you want to get into parsing and lexing and expand your understanding a bit more you can have a look at these sites:

1. [F# programming wikibooks][1]
2. [OCaml's lexyacc examples][2] (F#'s lexyacc is basically identical to the OCaml one)

If you want to understand a bit more about the abstract syntax trees then you can read wikipedia's entry on [Backus-Naur form][4]

[1]: https://en.wikibooks.org/wiki/F_Sharp_Programming/Lexing_and_Parsing
[2]: https://caml.inria.fr/pub/docs/manual-ocaml/lexyacc.html#s:lexyacc-example
[3]: http://fsprojects.github.io/FsLexYacc/reference/index.html
[4]: https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form
[5]: https://en.wikipedia.org/wiki/Polish_notation
[6]: https://github.com/ThanosPapathanasiou/personal-blog/tree/master/code-examples/lexing-and-parsing
     