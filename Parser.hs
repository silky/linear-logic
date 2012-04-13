module Parser where

import Syntax

import Text.ParserCombinators.Parsec


-- Grammar Rules --

term :: Parser [Term]
term = do spaces
          terms <- sepBy1 expr (optional (symbol "."))
          eof
          return terms

atom = identifier `as` Atom <?> "atomic formula"

atomish =  atom
       <|> parens expr

negation = atomish >>= negs

negs x = do
  n <- optionMaybe (symbol "^")
  case n of
    Just _  -> negs (Not x)
    Nothing -> return x


expr  = expr1 `chainr1` lolly
expr1 = expr2 `chainr1` add
expr2 = expr3 `chainr1` mul
expr3 = expt


mul    = tensor <|> par
tensor = symbol "*" `construct` (:*:)
par    = symbol "$" `construct` (:$:)

lolly  = symbol "-@" `construct` (:-@:)


add    = with <|> plus
with   = symbol "&" `construct` (:&:)
plus   = symbol "+" `construct` (:+:)


expt     = ofcourse <|> whynot <|> negation
ofcourse = symbol "!" >> expt `as` OfCourse
whynot   = symbol "?" >> expt `as` WhyNot


-- Useful Combinators --

despace p = do x <- p
               spaces
               return x

symbol s   = despace (string s)
identifier = despace (many1 letter)

parens p = do symbol "("
              inner <- p
              symbol ")"
              return inner


-- Utility Functions --

run :: Show a => Parser a -> String -> IO ()
run p input
        = case (parse p "" input) of
            Left err -> putStr "parse error at " >> print err
            Right x  -> print x

as :: Parser a -> (a -> b) -> Parser b
as = flip fmap

giving :: Parser b -> a -> Parser a
giving p x = p >> return x

construct :: Parser b -> (a -> a -> a) -> Parser (a -> a -> a)
construct p c = p >> return c