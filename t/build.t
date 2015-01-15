#!/usr/bin/env perl6

use Test;
use CSS::Grammar::Test;
use CSS::Specification::Build;

sub pipe($input-path, $code, $output-path?) {
    my $output;

    my $*IN = open $input-path, :r;
    my $*OUT = $output-path
        ?? open $output-path, :w
        !! class {
            method print(*@args) {
                $output ~= @args.join;
            }
            multi method write(Buf $b){$output ~= $b.decode}
        }

    $code();

    return $output-path // $output;
}

use lib 't';

my $base-name = 'CSS::Aural::Spec';
my $grammar-name = $base-name ~ '::Grammar';
my $actions-name = $base-name ~ '::Actions';
my $interface-name = $base-name ~ '::Interface';

pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'grammar', $grammar-name );
}, 't/CSS/Aural/Spec/Grammar.pm');
lives_ok {EVAL "use $grammar-name"}, 'grammar compilation';

pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'actions', $actions-name );
}, 't/CSS/Aural/Spec/Actions.pm');
lives_ok {EVAL "use $actions-name"}, 'actions compilation';

my $aural-interface-code = pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'interface', $interface-name );
}, 't/CSS/Aural/Spec/Interface.pm');
lives_ok {EVAL "use $interface-name"}, 'interface compilation';

dies_ok {EVAL 'use CSS::Aural::BadGrammar'}, 'grammar composition, unimplemented interface - dies';

my $aural-class;
lives_ok {EVAL "use CSS::Aural::Grammar; \$aural-class = CSS::Aural::Grammar"}, 'grammar composition - lives';

my $actions;
lives_ok {EVAL "use CSS::Aural::Actions; \$actions = CSS::Aural::Actions.new"}, 'class composition - lives';

for ('.aural-test { stress: 42; speech-rate: fast; volume: inherit; voice-family: female; }' =>
     {ast => { :stylesheet[
               {ruleset => {
                   declarations => [
                       { :ident<stress>, :expr[{ :num(42) }] },
                       { :ident<speech-rate>, :expr[{ :keyw<fast> }] },
                       { :ident<volume>, :expr[{ :keyw<inherit> }] },
                       { :ident<voice-family>, :expr[{ :keyw<female> }] },
                       ],
                       selectors => [{selector => [{simple-selector => [{class => "aural-test"}]}]}]
                }
               }]}
      },
     '.boxed-test { border-color: #aaa }' => {ast =>  { :stylesheet[{ruleset => 
                                                        {selectors => [:selector[{simple-selector => [{:class<boxed-test>}]}]],
                                                         declarations => [{
                                                             :ident<border-color>,
                                                             :expr[{ :rgb[ :num(170), :num(170), :num(170) ]}]}],
                                                  }}]}
     },
    ) {
    my ($input, $expected) = .kv;

    CSS::Grammar::Test::parse-tests($aural-class, $input, 
                                    :$actions, :$expected);
}
done;
