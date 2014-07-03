#!/usr/bin/env perl6

use Test;

use CSS::Grammar::Test;

use CSS::Specification;
use CSS::Specification::Actions;

my $actions = CSS::Specification::Actions.new;

for (
    'terms' => {input => 'thin?',
                ast => "[ thin & <keyw> ]?",
    },
    'terms' => {input => '35 | 7 | 42?',
                ast => "[ [ 35 | 7 ] & <number> | [ 42 & <number> ]? ]",
    },
    'terms' => {'input' => "<single-animation-direction> [, <'single-animation-direction'> ]*",
                ast => "<single-animation-direction> [ ',' <expr-single-animation-direction> ]*",
    },
    # precedence tests taken from: https://developer.mozilla.org/en-US/docs/CSS/Value_definition_syntax
    'terms' => {input => 'bold thin && <length>',
                ast => "[:my @*SEEN; bold & <keyw> thin & <keyw> <!seen(0)> | <length> <!seen(1)> ]**2",
    },
    'terms' => {input => 'bold || thin && <length>',
                ast => "[:my @*SEEN; bold & <keyw> <!seen(0)> | [:my @*SEEN; thin & <keyw> <!seen(0)> | <length> <!seen(1)> ]**2 <!seen(1)> ]+",
    },
    'property-spec' => {'input' => "'content'\tnormal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit",
                        ast => {"props" => ["content"],
                                "perl6" => "[ [ normal | none ] \& <keyw> | [ [ <string> | <uri> | <counter> | <attr> | [ open\\-quote | close\\-quote | no\\-open\\-quote | no\\-close\\-quote ] \& <keyw> ] ]+ | inherit & <keyw> ]",
                                "synopsis" => "normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit"},
    },
    # css1 spec with property name and '*' junk
    property-spec => {input => "'width' *\t<length> | <percentage> | auto",
                      ast => Mu,
    },
    ) {

    my $rule = .key;
    my $test = .value;
    my $input = $test<input>;

    CSS::Grammar::Test::parse-tests( CSS::Specification, $input,
                                     :rule($rule),
                                     :actions($actions),
                                     :suite<spec>,
                                     :expected($test) );
}

done;
