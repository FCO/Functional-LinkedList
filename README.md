[![Actions Status](https://github.com/FCO/Functional-LinkedList/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Functional-LinkedList/actions)

NAME
====

Functional::LinkedList - Functional data structure linked list.

SYNOPSIS
========

```raku
my @linked := Functional::LinkedList.new: 1, 2, 3;

say @linked;           # 1 -> 2 -> 3 -> (LinkedList[Any])
say @linked.push: 10;  # (1 -> 2 -> 3 -> 10 -> (LinkedList[Any]) 10)
say @linked;           # 1 -> 2 -> 3 -> (LinkedList[Any])

my @linked2 := Functional::LinkedList.new: :!both, 1, 2, 3;

say @linked2;          # 1 -> 2 -> 3 -> (LinkedList[Any])
say @linked2.push: 10; # 1 -> 2 -> 3 -> 10 -> (LinkedList[Any])
say @linked2;          # 1 -> 2 -> 3 -> (LinkedList[Any])

my @mutated := @linked.mutate: {
   .say;               # 1 -> 2 -> 3 -> (LinkedList[Any])
   say .push: 10;      # 10
   .say;               # 1 -> 2 -> 3 -> 10 -> (LinkedList[Any])
}

say @linked;           # 1 -> 2 -> 3 -> (LinkedList[Any]
say @mutated;          # 1 -> 2 -> 3 -> 10 -> (LinkedList[Any])
```

DESCRIPTION
===========

Functional::LinkedList is a implementation of a functional data structure linked list. It's immutable and thread-safe.

It has a `mutate` method that topicalise the object and will always topicalise the new generated list. And that's gives the impression of mutating and makes it easier to interact with those objects.

AUTHOR
======

Fernando Corrêa de Oliveira <fco@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

