% haskell-signatures.pl
%
% Written by Adrian Prantl, <adrian@llnl.gov> 2012, 2013.
%
% This program prints an algebraic datatype for use with Haskell and
% converters from/to ATerms for the grammar specified in the termite
% grammar spec (src/termite/termite_spec.pl)
%
% Yes it's ugly.
% It was originally written very quickly, and then grew from there.
%
%
% Before doing anything else, set up handling to halt if warnings or errors
% are encountered.
:- dynamic prolog_reported_problems/0.
% If the Prolog compiler encounters warnings or errors, record this fact in
% a global flag. We let message_hook fail because that signals Prolog to
% format output as usual (otherwise, we would have to worry about formatting
% error messages).
user:message_hook(_Term, warning, _Lines) :-
    assert(prolog_reported_problems), !, fail.
user:message_hook(_Term, error, _Lines) :-
    assert(prolog_reported_problems), !, fail.

:- getenv('PWD', CurDir),
    asserta(library_directory(CurDir)),
    prolog_load_context(directory, SrcDir),
    asserta(library_directory(SrcDir)),
    (getenv('TERMITE_LIB', TermitePath)
    ; (print_message(error, 'Please set the environment variable TERMITE_LIB'),
       halt(1))
    ),
    asserta(library_directory(TermitePath)).

% END BOILERPLATE
:-
    op(1200, xfx, ::=),      % grammar rule
    op(754,   fy, atoms),    % enumeration of terminal atoms
    op(754,   fy, functors), % enumeration of terminal functors...
    op(753,  xfy, with),     % ... with identical argument structure
    op(752,  xfx, where),    % semantic constraints
    op(751,  xf,    ?),      % optional occurrence of nonterminal

% Load in the grammar spec
    consult('PP_termite_spec.pl').

main :-
    writeln('{-|'),
    writeln('***********************************************************************'),
    writeln('WARNING: THIS FILE WAS AUTOMATICALLY GENERATED BY haskell-signatures.pl'),
    writeln('         DO NOT EDIT!'),
    writeln('***********************************************************************'),
    nl,
    writeln('Algebraic Datatypes for Minitermite terms.'),
    writeln('Generated from ${ROSE_SRCDIR}/projects/minitermite/src/termite/term_spec.pl'),
    nl,
    writeln('Please report bugs to adrian@llnl.gov, adrian@complang.tuwien.ac.at'),
    writeln('-}'),
    nl,
    writeln('{-# LANGUAGE DeriveDataTypeable #-}'),
    nl,
    writeln('module RuleGen.MTT where'),
    writeln('import ATerm.AbstractSyntax'),
    writeln('-- import ATerm.ReadWrite'),
    writeln('import ATerm.SimpPretty'),
    writeln('import Data.Data (Data(toConstr), Typeable)'),
    writeln('import Data.Function (on)'),
    nl,
    writeln('constrEqual :: Data a => a -> a -> Bool'),
    writeln('constrEqual  = (==) `on` toConstr'),
    nl,nl,nl,

    retractall(visited(_)),
    retractall(printed(_)),
    retractall(node(_)),
    retractall(node_type(_,_)),
    
    format('-- Minitermite term grammar as algebraic datatype~n', []),
    writeln('type Null = String'),
    once(print_types),
    nl, nl,

    write('data MTT = '),
    once(print_nodes),
    writeln('MTTOther String  deriving (Data, Typeable)'),
    nl,
    nl,

    writeln('{-|'),
    writeln('  Turn an aterm into an algebraic minitermite tree.'),
    writeln('-}'),
    writeln('prettyprint :: ShATerm -> ATermTable -> String'),
    writeln('prettyprint aterm att = show aterm -- render $ writeATermSDoc att'),
    writeln('atermToMTT :: ShATerm      -- ^ Aterm structure'),
    writeln('           -> ATermTable   -- ^ Table of aterm identifiers'),
    writeln('           -> MTT          -- ^ Minitermite tree created from Aterm structure'),
    writeln('atermToMTT term t = MTTProject $ atermProjectToMTT term t'),
    writeln('atermNumberToMTT (ShAInt i _) _ = INT i'),
    writeln('atermNumberToMTT _            _ = error "unhandled node"'),
    writeln('atermNumberOrStringToMTT (ShAInt i _)      _ = Num i'),
    writeln('atermNumberOrStringToMTT (ShAAppl str _ _) _ = Str str'),
    writeln('atermNumberOrStringToMTT _                 _ = error "unhandled node"'),
    writeln('atermNameToMTT (ShAAppl str _ _) _ = str'),
    writeln('atermMaybeToMTT f (ShAAppl "null" _ _) _ = Nothing'),
    writeln('atermMaybeToMTT f a                    t = Just $ f a t'),
    writeln('atermNullToMTT (ShAAppl "null" _ _) _ = "null"'),
    writeln('atermNullToMTT _                    _ = error "unhandled node"'),
    writeln('getList (ShAList l _) _ = l'),
    writeln('getList _    _ = error "unhandled node"'),
    writeln('instance Show Number where'),
    writeln('    show (INT i)    = show i'),
    writeln('    show (DOUBLE d) = show d'),
    writeln('instance Show NumberOrString where'),
    writeln('    show (Num i) = show i'),
    writeln('    show (Str s) = show s'),
    
    nl,nl.
main:- writeln('** Internal Error!').

fst((A:_), A).

print_nodes :-
    node_type(Node, Type-_),
    haskellized_atom(Node, NodeH),
    haskellized_atom(Type, TypeH),
    format('MTT~w ~w ~n         | ', [NodeH, TypeH]),
    fail.
print_nodes.

print_aterm_mtt(_:(C-Ch, Args)) :-
    format('    (ShAAppl "~w" [', [Ch]),
    argchain(0, Args),
    writeln('] t) ->'),
    aterm_constructor(C, Ch),
    maplistn(print_aterm_mtt1, 0, Args), nl.

aterm_constructor(null, _) :- !,
    format('      "null" ').
aterm_constructor(C, Ch) :-
    node_type(C, _), !,
    format('      ~w', [Ch]).
aterm_constructor(_, Ch) :-
    format('      ~w ', [Ch]).


print_aterm_mtt1(N, [A]) :- !,
    spellout(A, AH),
    format('~n        (map (\\x -> aterm~wToMTT (getShATerm x t) t)~n', [AH]),
    format('            (getList (getShATerm '), argchain1(N,[A]), format(' t) t))').

print_aterm_mtt1(N, A?) :- !,
    spellout(A, AH),
    format('\n        (atermMaybeToMTT aterm~wToMTT (getShATerm ', [AH]),
    argchain1(N,A), write(' t) t)').

print_aterm_mtt1(N, A) :-
    spellout(A, AH),
    format('\n        (aterm~wToMTT (getShATerm ', [AH]), argchain1(N,A), write(' t) t)').

spellout(A, AH) :- atom(A), haskellized_atom(A, AH).
spellout({A}, AH) :- atom(A), haskellized_atom(A, AH).
spellout(N, 'Number') :- number(N).
spellout(V, 'Todo') :- var(V).
spellout(_, error) :- gtrace.


% print aa:ab:...
argchain(_, []).
argchain(N,[A]) :- argchain1(N,A).
argchain(N,[A|[B|Args]]) :-
   argchain1(N,A), write(','),
   N1 is N+1, 
   argchain(N1, [B|Args]). 

argchain1(N,{A}) :- !, format('a~d_~w', [N,A]).
argchain1(N,[A]) :- !, format('a~d_~ws', [N,A]).
argchain1(N,A?)  :- !, format('a~d_~w', [N,A]).
argchain1(N,A)   :-    format('a~d_~w', [N,A]).


% instance (show VarRef) =
%    show (VarRef p1 p2) =
%        "Var_ref("++show p1++","++show p2++")"
%
% ATerm -> MTT
% use aterm lib ...
whitespace(' ').
ws_indent(Indent, Atom, Ws) :-
    atom_length(Atom, L), L1 is L+Indent, length(Xs, L1),
    maplist(whitespace,Xs), atom_chars(Ws, Xs).

decl(({V} where atom(V)), type) :- !.
decl({_}, type) :- !.
decl(A, type) :- atom(A), !.
decl(_, data).


print_types :-
    ( Nonterminal ::= _Rhs ),
    print_types(Nonterminal),
    fail.
print_types.

print_types(Nonterminal) :-
    ( Nonterminal ::= Rhs ), %(Nonterminal='expression'->gtrace;true),
    ( printed(Nonterminal)
    ; assert(printed(Nonterminal)),
      haskellized_atom(Nonterminal, Type),
      decl(Rhs, Decl),
      (print_type(Type-[], Rhs, O)
      -> true
      ;  format('** ERROR: could not convert ~w~n', [Nonterminal]), fail),
      
      format('-- -----------------------------------------------------------------~n'),
      format('-- ~w ::= ~w~n', [Nonterminal,Rhs]),
      format('-- -----------------------------------------------------------------~n'),
      format('~w ~w = ', [Decl, Type]),
      include(types, O, Ot), maplist(write_snd, Ot),
      (Decl=data
      -> writeln(' deriving (Data, Typeable)')
      ;  nl),
      include(shows, O, Os),
      (Os=[]->true
      ; format('instance Show ~w where ~n', [Type]),
        maplist(write_snd, Os), nl
      ),
      include(convs, O, Oc), maplist(write_snd, Oc),
      (hardcoded(Type)
      -> true
      ;  format('aterm~wToMTT aterm att = error $ "expected a <~w> term, found: "~n',
		[Type, Nonterminal]),
         format('    ++ prettyprint aterm att~n~n', [])
      ),
      nl, nl
    ),
    fail.
print_types(_).

hardcoded('Number').
hardcoded('NumberOrString').
hardcoded('Name').

write_snd(_-A) :- write(A).
types(t-_).
shows(s-_).
convs(c-_).

print_type(S-_,Var,[t-OT,c-OC]) :-
    var(Var), !,
    format(atom(OT), 'String {- UNKNOWN -}', []),
    format(atom(OC), 'aterm~wToMTT (ShAAppl s _ _) _ = s~n~n',[S]).

print_type(_,[Var],[t-O])             :- var(Var), !, format(atom(O), '[String] {- UNKNOWNS -} ', []).
print_type(N,{T},O)		      :- atom(T),  !, print_atoms(N,[T],O).
print_type(N,{T},O)		      :- !, print_type(N,T,O).
print_type(_,{_} where Variants,[t-O]):- !, with_output_to(atom(O), print_variants(Variants)).
print_type(_,[T],[t-O])		      :- !, haskellized_atom(T,S), format(atom(O), '[~w] ', [S]).
print_type(_,T?,[t-O])		      :- !, haskellized_atom(T,S), format(atom(O),'(Maybe ~w) ',[S]).
print_type(T,atoms Atoms,O)	      :- !, print_atoms(T,Atoms, O).
print_type(N,functors Fs with Args,O) :- !, print_functors(N,Args, Fs, O).
print_type(_,T,[t-OT]) :-
    atom(T), !,
    haskellized_atom(T,S),
    format(atom(OT), '~w ', [S]).

print_type(Type, A|B, O) :- !,
    extra_constructor(Type, A, O1),
    print_type(Type, A, O2),
    Type = T-_,
    ws_indent(6, T, Ws),
    format(atom(O3), '~n~w| ', [Ws]),
    extra_constructor(Type, B, O4),
    print_type(Type, B, O5),
    flatten([O1,O2,t-O3,O4,O5],O).

% functors
print_type(Type, Nonterminal, [s-OS|[c-OC|OT]]) :-
    Nonterminal =.. [Constructor|Args], !,
    print_types(Nonterminal),
    haskellized_atom(Constructor, ConstructorH),
    assert(node_type(Constructor, Type)),
    format(atom(O1),'~w ', [ConstructorH]),
    maplist(print_type(Type), Args, Os),
    flatten(Os, Os1),
    include(types, Os1, Os2),
    flatten([t-O1|Os2], OT),
    with_output_to(atom(OS), print_show(Constructor, ConstructorH, Args)),
    with_output_to(atom(OC), print_conv(Type, Constructor, ConstructorH, Args)).

print_show(Constructor, ConstructorH, Args) :-
    write('    show ('),
    print_ws(ConstructorH),
    print_show_arg(0, Args), !,
    (  Args = [A|As]
    -> format(') = ~n        "~w(" ++ (show p0_', [Constructor]),
       print_ws(A), write(') '),
       print_show_arg1(1, As), !,
       format('++ ")"~n~n')
    ;  format(') = "~w"~n', [])).


print_conv(Type-NTs, C, Ch, Args) :-
    format('aterm~wToMTT (ShAAppl "~w" [', [Type, C]),
    argchain(0,Args),
    format('] _) t =~n'),
    constructor_chain([Ch|NTs], Constructors),
    format('    ~w', [Constructors]),
    maplistn(print_aterm_mtt1, 0, Args), nl.

% chain a list of constructor allocations with the $ operator
constructor_chain(Cs, Atom) :-
    reverse(Cs, CsR),
    atomic_list_concat(CsR, ' $ ', Atom).


% succeed if Lhs is a nonterminal symbol in the grammar and bind Rhs accordingly
nonterminal(Lhs, Rhs) :-
    (Lhs ::= Rhs),
    functor(Rhs, F, _),
    F \= Lhs.
 
% if Type turns out to be a nonterminal, recursively list all
% terminals that could be of Type
extra_constructor(Type-NTs, A, [Ot|[s-OS|Oc]]) :-
% 	(A='declaration_statement'->gtrace;true),
    nonterminal(A, Rhs), !,
    haskellized_atom(A, AH),
    RecType = Type-[AH|NTs],
    print_type(RecType, Rhs, O),
    retractall(node_type(_, RecType)), % offset an unwanted side-effect of print_type
    include(convs, O, Oc),
    format(atom(OS), '    show (~w ~w) = show ~w~n',[AH,A,A]),
    print_type(Type-NTs, A, [Ot]).

% otherwise print the conversion function for this terminal symbol    
% extra type constructor for rhs nonterminals
extra_constructor(Type-NTs, A, [t-Type,t-AH,s-OS,c-OC]) :-
    atom(A), !,
    print_type(Type-NTs, A, [t-AH]),
    format(atom(OS), '    show (~w~w~w) = show ~w~n',[Type,AH,A,A]),
    sub_atom(AH, 0, _, 1, AH0), % get rid of trailing space
    build_constructor(Type, NTs, AH0, Constructors),
    format(atom(OC), 'aterm~wToMTT a@(ShAAppl "~w" _ _) t =~n    ~w $ aterm~wToMTT a t~n~n',
	   [Type,A,Constructors,AH0]).
extra_constructor(_, _, []).

build_constructor(BaseType, NTs, Type, Constructors) :-
    (NTs = [NT1|_]
    ->  atom_concat(NT1, Type,  Constructor), NTs1 = [Constructor|NTs]
    ;   atom_concat(BaseType, Type, Constructor), NTs1 = [Constructor]),
    constructor_chain(NTs1, Constructors).


print_variants(_;_) :-
    write('Num Integer | Str String ').
print_variants(atom(_)) :- write('String ').
print_variants(number(_)) :- write('INT Integer | DOUBLE Double ').
print_variants(_) :- gtrace.


print_atoms(_,[], []).
print_atoms(Type-NTs,[A|[B|As]], O) :- !,
    haskellized_atom(A, AH),
    format(atom(OT), '~w | ', [AH]),
    format(atom(OS), '    show ~w = "~w"~n',[AH,A]),
    constructor_chain([AH|NTs], Constructors),
    format(atom(OC), 'aterm~wToMTT (ShAAppl "~w" _ _) t = ~w~n', [Type,A,Constructors]),
    print_atoms(Type-NTs,[B|As],O1),
    append([t-OT,s-OS,c-OC],O1,O).
print_atoms(Type-NTs,[A], [t-OT,s-OS,c-OC]) :-
    haskellized_atom(A, AH),
    format(atom(OT), '~w ', [AH]),
    format(atom(OS), '    show ~w = "~w"~n',[AH,A]),
    constructor_chain([AH|NTs], Constructors),
    format(atom(OC), 'aterm~wToMTT (ShAAppl "~w" _ _) t = ~w~n~n', [Type,A,Constructors]).

print_functors(_, _, [], '').
print_functors(N, Args, [F|[G|Fs]], O) :- !,
    listify(Args, Args1),
    T =.. [F|Args1],
    print_type(N,T,O1),
    O2 = '\n      | ',
    print_functors(N, Args, [G|Fs], O3),
    append(O1, [t-O2|O3], O).
print_functors(N, Args, [F], O) :-
    listify(Args, Args1),
    T =.. [F|Args1],
    print_type(N,T,O1),
    append(O1,[t-' '], O).


listify((A,As), [A|As1]) :- !,
    listify(As, As1).
listify(A, [A]).


print_ws({A}) :- format('~w ', [A]).
print_ws(A?)  :- format('~w ', [A]).
print_ws([A]) :- format('~w ', [A]).
print_ws(A)   :- format('~w ', [A]).

print_show_arg(_,[]).
print_show_arg(N, [A|As]) :-
    format('p~d_',[N]),
    print_ws(A),
    N1 is N+1,
    print_show_arg(N1, As).
print_show_arg1(_,[]).
print_show_arg1(N,[A|As]) :-
    format('~n          ++ ", " ++ (show p~d_',[N]), print_ws(A), write(') '),
    N1 is N+1,
    print_show_arg1(N1, As).

% pass through until we reach an underscore
haskellized1([], []).
haskellized1(['_'|Cs], Cs1) :-
   haskellized(Cs, Cs1).
haskellized1([C|Cs], [C|Cs1]) :-
   haskellized1(Cs, Cs1).
% captialize the first letter
haskellized([], []).
haskellized([C|Cs], [C1|Cs1]) :-
   char_type(C1, to_upper(C)),
   haskellized1(Cs, Cs1).

haskellized_atom(::, 'GlobalScope') :- !.
haskellized_atom(A, A1) :-
   (atom(A) ; gtrace),
   atom_chars(A, Cs),
   haskellized(Cs, Cs1),
   atom_chars(A1, Cs1), !.


%% maplistn/3:
% like map f (zip [i..] xs)
maplistn(_, _, []).
maplistn(F, I, [X|Xs]) :-
    call(F, I, X),
    I1 is I+1,
    maplistn(F, I1, Xs).

% Finish error handling (see top of source file) by halting with an error
% condition of Prolog generated any warnings or errors.
:- (prolog_reported_problems -> halt(1) ; true).
