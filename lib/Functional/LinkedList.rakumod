use ValueClass;
unit value-class Functional::LinkedList does Positional;

my $both-default = True;

role Typed[::T = Any] {
  has T $.of
}

my $of = Any;
method ^parameterize(Mu:U \linked-list, ::T = Any) {
  $of = T;
  linked-list.^mixin(Typed[T]).^set_name: "LinkedList[{ $of.^name }]"
}

method mutate(&block) is export {
  my $*VALUE = self;
  block $*VALUE;
  $*VALUE
}

method iterator {
  class :: does Iterator {
    has $.list is required;
    method pull-one {
      return IterationEnd without $!list;
      my $value := $!list.value;
      $!list .= next;
      $value
    }
  }.new: :list(self)
}

my class NO-VALUE {}

has          $.value where $of = $of.WHAT;
has ::?CLASS $.next;
has UInt     $.size = 1 + ($!next andthen .size // 0);
has Bool     $.both = $both-default;

method of {Any}

multi method elems(::?CLASS:D:) { $!size }
multi method elems(::?CLASS:U:) { 0 }

multi method new(*@values, Bool :$both = $both-default, *% where *.not) {
  die X::TypeCheck.new: :operation("creating { $.^name }"), :expected($of), :got(@values) if @values && @values.are !~~ $of;
  my $obj = self.bless: :$both, :value(@values.tail // $of);
  for @values.reverse.skip -> $item {
    ($obj, $) = $obj.unshift: $item // $of
  }
  $obj
}

multi method AT-POS(::?CLASS:D: 0) {
  $!value
}

multi method AT-POS(::?CLASS:D: UInt $index) {
  $!next.AT-POS: $index - 1
}

method !mutable($node, $value, Bool :$both = self.defined ?? $!both !! $both-default, :$internal = False) {
  return $node, $value if $internal;
  do if $*VALUE !~~ Failure {
    $*VALUE = $($node);
    $value
  } else {
    return $node, $value if $both;
    $node
  }
}

multi method DELETE-POS(::?CLASS:D: Int $ where { $_ < 0 }) {
  NO-VALUE
}

multi method DELETE-POS(::?CLASS:D: 0, Bool :$both = $!both, Bool :$internal = False) {
  self!mutable: :$internal, :$both, $!next, $!value
}

multi method DELETE-POS(::?CLASS:D: UInt $index, Bool :$both = $!both, Bool :$internal = False) {
  my :($node, $value) := $!next.DELETE-POS: :internal, $index - 1;
  self!mutable: :$internal, :$both, self!replace($node), $value
}

multi method ASSIGN-POS(::?CLASS:D: Int $ where { $_ < 0 }, $, Bool :$both = $!both) {
  NO-VALUE
}

multi method ASSIGN-POS(0, $value where $of, Bool :$both = self.defined ?? $!both !! $both-default, Bool :$internal = False) {
  self!mutable: :$internal, :$both, $.new(:$value, |(:$!both with self), |(:$!next with self)), $value
}

multi method ASSIGN-POS(::?CLASS:U: UInt $index, $value where $of, Bool :$both = $both-default, Bool :$internal = False) {
  my :($node, $val) := $.new.ASSIGN-POS: :internal, $index - 1, $value;
  self!mutable: :$internal, :$both, self!replace($node), $val
}

multi method ASSIGN-POS(::?CLASS:D: UInt $index, $value where $of, Bool :$both = $!both, Bool :$internal = False) {
  my :($node, $val) := $!next.ASSIGN-POS: :internal, $index - 1, $value;
  self!mutable: :$internal, :$both, self!replace($node), $val
}

method BIND-POS(|c) { $.ASSIGN-POS: |c }

method !replace($_) {
  do if $_ !~~ NO-VALUE {
    $.new: next => .self, |(:$!both with self), |(:$!value with self)
  } else {
    self
  }
}

method unshift($value where $of) {
  self!mutable: $.new(:$value, :next(self), |(:$!both with self)), $value
}

method shift {
  self!mutable: self ?? $!next !! self, self ?? $!value !! $of
}

method push($value where $of) {
  self[$!size] = $value;
}

method pop {
  self[$!size - 1]:delete
}

multi method splice(Int $start, Inf, @data) {
  my :($next, \value) := $!next.splice: $start - 1, @data;
  self!mutable: $.new(:$!both, :$next, :$!value), value
}

multi method splice(Int $start, @data) {
  my :($next, \value) := $!next.splice: $start - 1, @data;
  self!mutable: $.new(:$!both, :$next, :$!value), value
}

multi method splice(::?CLASS:D: UInt $start where * > 0, $remove, @data) {
  my ($next, \value) = $!next.splice: :both, $start - 1, $remove, @data;
  self!mutable: $.bless(:$!value, :$next), value
}

multi method splice(0, Int $remove where * <= $.elems, @data) {
  my $next = self;
  my @removed;
  for ^$remove {
    @removed.push: $next.value;
    $next .= next
  }
  for @data.reverse -> $value {
    $next = $.bless: :$next, :$value
  }
  self!mutable: $next, $.WHAT.new: @removed
} 

multi method splice(0, Inf, @data) {
  self.splice: 0, @data
}

multi method splice(0, @data) {
  self.splice: 0, $.elems, @data
}

multi method gist(::?CLASS:U:) { "({ self.^shortname }{ "[{ $of.^name }]" })" }
multi method gist(::?CLASS:D:) { "$!value -> { quietly $!next.gist }" }

method WHICH { ValueObjAt.new: join "|", self.^shortname, |($!value.WHICH, $!next.WHERE with self) }

multi method Seq(::?CLASS:D:) { Seq.new: $.iterator }
multi method list(::?CLASS:D:) { $.Seq.list }

=begin pod

=head1 NAME

Functional::LinkedList - Functional data structure linked list.

=head1 SYNOPSIS

=begin code :lang<raku>

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

=end code

=head1 DESCRIPTION

Functional::LinkedList is a implementation of a functional data structure
linked list. It's immutable and thread-safe.

It has a C<mutate> method that topicalise the object and will always topicalise
the new generated list. And that's gives the impression of mutating and makes
it easier to interact with those objects.

=head1 AUTHOR

Fernando Corrêa de Oliveira <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
