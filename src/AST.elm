{-
  Abstract Syntax Trees for Haskelite, a small subset of Haskell
  Pedro Vasconcelos, 2021
-}
module AST exposing (..)

import Dict exposing (Dict)
import Maybe

type alias Name
    = String

-- * expressions
type Expr
    = App Expr (List Expr)    -- non-empty list of arguments
    | Lam (List Name) Expr    -- non-empty list of variables
    | Var Name
    | Number Int
    | Boolean Bool
    | Cons Expr Expr                -- (x:xs)
    | ListLit (List Expr)           -- [1,2,3]
    | TupleLit (List Expr)          -- (1,2,3)
    | EnumFrom Expr                 -- [1..]
    | EnumFromThen Expr Expr        -- [1,3..]
    | EnumFromTo Expr Expr          -- [1..10]
    | EnumFromThenTo Expr Expr Expr -- [1,3..10]
    | InfixOp Name Expr Expr        --  operators +, * etc
    | IfThenElse Expr Expr Expr
    | Fail String                 -- runtime errors
--  | Hole Expr                -- hole to highlight reduced expressions

-- * declarations      
type Decl
    = TypeSig Name String 
    | Equation Name (List Pattern) Expr 

-- * patterns      
type Pattern
    = VarP Name
    | BooleanP Bool
    | NumberP Int
    | ListP (List Pattern)
    | ConsP Pattern Pattern
    | TupleP (List Pattern)

-- variable substitutions
type alias Subst = Dict Name Expr


-- perform variable substitution
applySubst : Subst -> Expr -> Expr
applySubst s e
    = case e of
          Number _ ->  e
                       
          Boolean _ -> e
                       
          Var x ->
              case Dict.get x s of
                  Nothing -> e
                  Just e1 -> e1
                             
          Lam xs e1 ->
              let
                  s1 = List.foldr Dict.remove s xs
              in
                  Lam xs (applySubst s1 e1)
                      
          App e1 args ->
              App (applySubst s e1) <| List.map (applySubst s) args
                  
          Cons e1 e2 ->
              Cons (applySubst s e1) (applySubst s e2)
                  
          InfixOp op e1 e2 ->
              InfixOp op (applySubst s e1) (applySubst s e2)
                  
          ListLit l ->
              ListLit (List.map (applySubst s) l)
                  
          TupleLit l ->
              TupleLit (List.map (applySubst s) l)

          EnumFrom e1  ->
              EnumFrom (applySubst s e1)
                  
          EnumFromThen e1 e2 ->
              EnumFromThen (applySubst s e1) (applySubst s e2)

          EnumFromTo e1 e2 ->
              EnumFromTo (applySubst s e1) (applySubst s e2)

          EnumFromThenTo e1 e2 e3 ->
              EnumFromThenTo (applySubst s e1) (applySubst s e2) (applySubst s e3)
                  

          IfThenElse e1 e2 e3 ->
              IfThenElse (applySubst s e1) (applySubst s e2) (applySubst s e3)

          Fail _ -> e

--          Hole e1 ->
--              applySubst s e1


removeHoles : Expr -> Expr
removeHoles e 
   = case e of
         Number _ ->  e
                       
         Boolean _ -> e
                       
         Var x ->
             e
                             
         Lam xs e1 ->
              Lam xs (removeHoles e1)
                      
         App e1 args ->
              App (removeHoles e1) <| List.map removeHoles args
                  
         Cons e1 e2 ->
              Cons (removeHoles e1) (removeHoles e2)
                  
         InfixOp op e1 e2 ->
              InfixOp op (removeHoles e1) (removeHoles e2)
                  
         ListLit l ->
              ListLit (List.map removeHoles l)
                  
         TupleLit l ->
              TupleLit (List.map removeHoles l)

         EnumFrom e1  ->
              EnumFrom (removeHoles e1)
                  
         EnumFromThen e1 e2 ->
              EnumFromThen (removeHoles e1) (removeHoles e2)

         EnumFromTo e1 e2 ->
              EnumFromTo (removeHoles e1) (removeHoles e2)

         EnumFromThenTo e1 e2 e3 ->
              EnumFromThenTo (removeHoles e1) (removeHoles e2) (removeHoles e3)
                  

         IfThenElse e1 e2 e3 ->
              IfThenElse (removeHoles e1) (removeHoles e2) (removeHoles e3)

         Fail _ -> e

--         Hole e1 ->
--              e1
