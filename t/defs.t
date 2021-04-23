use v6;
use Test;
use CSS::Grammar::Test;
use CSS::Grammar::CSS3;
use CSS::Grammar::Actions;
use CSS::Specification::Defs;
use CSS::Specification::Defs::Actions;

class CSS3Defs
    is CSS::Specification::Defs
    is CSS::Grammar::CSS3 {};

class CSS3Defs::Actions
    is CSS::Specification::Defs::Actions
    is CSS::Grammar::Actions {};

for <0% 10%> {
    nok($_ ~~ /^<CSS3Defs::number>/, "not number: $_");
    ok($_ ~~ /^<CSS3Defs::percentage>/, "percentage: $_");
    ok($_ ~~ /^<CSS3Defs::length>/, "length: $_");
    nok($_ ~~ /^<CSS3Defs::angle>/, "not angle: $_");
}

for <0deg> {
    nok($_ ~~ /^<CSS3Defs::number>/, "not number: $_");
    nok($_ ~~ /^<CSS3Defs::percentage>/, "not percentage: $_");
    nok($_ ~~ /^<CSS3Defs::length>/, "not length: $_");
    ok($_ ~~ /^<CSS3Defs::angle>/, "angle: $_");
}

for <0> {
    ok($_ ~~ /^<CSS3Defs::number>/, "number: $_");
    nok($_ ~~ /^<CSS3Defs::percentage>/, "not percentage: $_");
    ok($_ ~~ /^<CSS3Defs::length>/, "length: $_");
    ok($_ ~~ /^<CSS3Defs::angle>/, "angle: $_");
}

for '1' {
    ok($_ ~~ /^<CSS3Defs::number>/, "number: $_");
    nok($_ ~~ /^<CSS3Defs::percentage>/, "not percentage: $_");
    nok($_ ~~ /^<CSS3Defs::length>/, "not length: $_");
    nok($_ ~~ /^<CSS3Defs::angle>/, "angle: $_");
}

my $actions = CSS3Defs::Actions.new;

for :number<123.45>        => :num(123.45),
    :integer<123>          => :int(123),
    :uri("url(foo.jpg)")   => :url<foo.jpg>,
    :keyw<Abc>             => :keyw<abc>,
    :identifier<Foo>       => :ident<Foo>,
    :identifiers("Aaa bb") => :ident("Aaa bb") {

    my ($in, $ast) = .kv;
    my ($rule, $input) = $in.kv;

    my %expected = :$ast;

    &CSS::Grammar::Test::parse-tests(CSS3Defs, $input,
                                     :$actions,
                                     :$rule,
                                     :suite('css3 terms'),
                                     :%expected);
}

done-testing;
