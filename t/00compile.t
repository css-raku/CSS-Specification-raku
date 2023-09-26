#!/usr/bin/env perl6

use Test;
use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Compiler;
use CSS::Specification::Compiler::Actions;

lives-ok {require CSS::Grammar:ver(v0.3.0..*) }, "CSS::Grammar version";

my CSS::Specification::Compiler::Actions $actions .= new;

for (
    'spec' => {
        input => 'thin',
        ast   => :keywords['thin'],
        deparse => 'thin & <keyw>',
    },
##    'spec' => {
##        input => 'thin?',
##        ast   => :occurs['?', :keyw<thin>],
##        deparse => '[ thin & <keyw> ]?',
##    },
    'spec' => {
        input => 'thick | thin',
        ast => :keywords[ 'thick', 'thin' ],
        deparse => '[thick | thin ]& <keyw>',
    },
##    'spec' => {
##        input => '35 | 7 | 42?',
##        ast => :alt[ :alt([:num(35), :num(7)]), :occurs["?", :num(42)]],
##        deparse => '[ [ 35 | 7 ] & <number> || [ 42 & <number> ]? ]',
##    },
##    'spec' => {input => "<rule-ref> [, [ 'css21-prop-ref' | <'css3-prop-ref'> ] ]*",
##                deparse => "<rule-ref> [ <op(',')> [ [ <expr-css21-prop-ref> || <expr-css3-prop-ref> ] ] ]*",
##    },
##    'spec' => {input => '<length>{4}',
##               deparse => '<length> ** 4',
##    },
##    'spec' => {input => '<length>#{1,4}',
##               deparse => "<length> ** 1..4% <op(',')>",
##    },
##    # precedence tests taken from: https://developer.mozilla.org/en-US/docs/CSS/Value_definition_syntax
##    'spec' => {input => 'bold thin && <length>',
##               deparse => ':my @*SEEN; [ bold & <keyw> thin & <keyw> <!seen(0)> | <length> <!seen(1)> ]**2',
##    },
##    'spec' => {input => 'bold || thin && <length>',
##               deparse => ':my @*SEEN; [ bold & <keyw> <!seen(2)> | [ thin & <keyw> <!seen(0)> | <length> <!seen(1)> ]**2 <!seen(3)> ]+',
##    },
##    'property-spec' => {input => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit	normal	:before and :after pseudo-elements	no",
##                        ast => {:props['content'],
##                                :default<normal>,
##                                :raku('[ [ normal | none ] & <keyw> || [ [ <string> || <uri> || <counter> || <attr> || [ open\\-quote | close\\-quote | no\\-open\\-quote | no\\-close\\-quote ] & <keyw> ] ]+ || inherit & <keyw> ]'),
##                                :synopsis('normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit'),
##                                :!inherit,
##                        },
##    },
##    # css1 spec with property name and '*' junk
##    property-spec => {input => "'width' *\t<length> | <percentage> | auto	auto	all elements but non-replaced inline elements, table rows, and row groups	no",
##                      ast => Mu,
##    },
    ) {

    my $rule := .key;
    my $expected := .value;
    my $input := $expected<input>;
    my $deparse := $expected<deparse>;

    my @*PROP-NAMES = [];

    my $parse = CSS::Grammar::Test::parse-tests(
        CSS::Specification, $input,
        :$rule,
        :$actions,
        :suite<spec>,
        :$expected
    );

    with $deparse {
        my $AST = CSS::Specification::Compiler::compile(|$parse.ast);
        is $AST.DEPARSE, $_, 'deparse';
    }
}

done-testing;
