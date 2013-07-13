#!/usr/bin/runhaskell

import Data.List
import Data.Function (on)
import Data.Char (intToDigit, digitToInt)

main :: IO ()
main = print(soln)

--[797,373,317,313,73,53,37,23,3137,3797,739397]

--turns out there are only a couple right truncatable primes {79}
--test them for left truncatability

--generating the right trunx is hard, so some rules:
--  no prime {other than 2 or 5} can end with 0,2,4,5,6, or 8
--     or it would be divisible by 2 or 5
--     therefore, all RTPs can be generated by adding 1,3,7 or 9 to a RTP
--
--  all right truncatable primes must start with a prime number (2,3,5 or 7)
--  
--  therefore, every right trunc consists entirely of (2,3,5 or 7)
--     followed by any combination (1,3,7, or 9)


soln = sum $ map undigits $ filter isLeftTrunc $ map digits rtPrimes
 where rtPrimes = concatMap untruncR [2,3,5,7]
 
       untruncR n = let rs = addRightPrimes n
                    in rs ++ (concatMap untruncR (rs))
       addRightPrimes n = filter isPrime [n*10+d | d<-[1,3,7,9]]

       isLeftTrunc []  = True
       isLeftTrunc [n] = isPrime $ undigits [n]
       isLeftTrunc (n:ns) | isPrime $ undigits ns = isLeftTrunc ns
                          | otherwise = False

       digits x = map digitToInt $ show x
       undigits xs = read $ map intToDigit xs :: Integer

       isPrime n = n>=2 && (not $ n `isMultAny` (primesUnder ((floorsqrt n)+1)))
       floorsqrt = floor . sqrt . fromIntegral
       
       primesUnder x = takeWhile (<x) primes
       
       primes = sieve [2..]
       sieve (x:xs) = x:(strain x (sieve xs))
       sieve [] = []

       strain x = filter $ not . (`isMult`x)
       
       isMult x n = 0 == x`mod`n
       isMultAny x = or . map (x`isMult`)








soln'' = take 10000 $ truncleft 3
--        take 11 $ lazyintersect
--        (interleave (interleave (interleave (truncleft 2)
--                                (truncleft 3))
--                    (truncleft 5))
--        (truncleft 7))
--        
--        (interleave (interleave (interleave (truncright 2)
--                                (truncright 3))
--                    (truncright 5))
--        (truncright 7))

 where truncleft n = let ls = lefty n
                     in ls ++ (concatMap truncleft (ls))
       lefty n = filter isPrime [undigits $ d:(digits n) | d<-[2,3,5,7]]
       
       truncright n = let rs = righty n
                     in rs ++ (concatMap truncright (rs))
       righty n = filter isPrime [undigits $ (digits n)++[d] | d<-[3,7]]
       
       interleave [] ys = ys
       interleave xs [] = xs
       interleave (x:xs) (y:ys) | x<y       = x:(interleave xs (y:ys))
                                | otherwise = y:(interleave (x:xs) ys)

       --xs and ys must increase
       lazyintersect [] _ = []
       lazyintersect _ [] = []
       lazyintersect (x:xs) ys | (search ys x) = x:(lazyintersect xs ys)
                               | otherwise     = lazyintersect xs ys
       search [] _ = False
       search (a:as) b | a==b = True
                       | a>b  = False
                       | a<b  = search as b

       digits x = map digitToInt $ show x
       undigits xs = toInteger $ fromInteger $ read $ map intToDigit xs

       isPrime n = n>=2 && (not $ n `isMultAny` (primesUnder ((floorsqrt n)+1)))
       floorsqrt = floor . sqrt . fromIntegral
       
       primesUnder x = takeWhile (<x) primes
       
       primes = sieve [2..]
       sieve (x:xs) = x:(strain x (sieve xs))
       sieve [] = []

       strain x = filter $ not . (`isMult`x)
       
       isMult x n = 0 == x`mod`n
       isMultAny x = or . map (x`isMult`)
 



soln' n = findTrunks n
 where findTrunks n = sieveCount n [2..n] []
       sieveCount lim (x:xs) acc
           | length acc == 11 = acc
           | x^2<lim          = sieveCount lim (strain x xs) (if trunxPrime x then (x:acc) else acc)
           | otherwise = acc ++ (filter trunxPrime (x:xs))
       sieveCount _ _ acc = acc
       
       strain x = filter $ not . (`isMult`x)
       
       isMult x n = 0 == x`mod`n
       isMultAny x = or . map (x`isMult`)
       
       trunx x = let xs=digits x
                 in (map undigits $ tr xs) ++ (map (undigits.reverse) $ tr $ reverse xs)
       tr [] = []
       tr (x:xs) = (x:xs):(tr xs)

       digits = map digitToInt . show
       undigits = toInteger . fromInteger . read . map intToDigit
       
       trunxPrime x = (x>7) && (and $ map isPrime $ trunx x)
       
       isPrime n = n>=2 && (not $ n `isMultAny` (primesUnder ((floorsqrt n)+1)))
       floorsqrt = floor . sqrt . fromIntegral
       
       primesUnder x = takeWhile (<x) primes
       
       primes = sieve [2..]
       sieve (x:xs) = x:(strain x (sieve xs))
       sieve [] = []
