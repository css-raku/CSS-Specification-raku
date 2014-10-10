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

dies_ok {EVAL slurp 'use CSS::Aural::BadGrammar'}, 'grammar composition, unimplemented interface - dies';

my $aural-class;
lives_ok {EVAL "use CSS::Aural::Grammar; \$aural-class = CSS::Aural::Grammar"}, 'grammar composition - lives';

my $aural-actions;
lives_ok {EVAL "use CSS::Aural::Actions; \$aural-actions = CSS::Aural::Actions.new"}, 'class composition - lives';

my %expected = ast => [{ruleset => {
    declarations => {
        speech-rate => {expr => [{keyw => "fast"}]},
        stress => {expr => [{number => 42}]}},
    selectors => [{selector => [{simple-selector => [{class => "yay-it-works"}]}]}]
  }
}];

CSS::Grammar::Test::parse-tests($aural-class, '.yay-it-works { stress: 42; speech-rate: fast }',
                                :actions($aural-actions), :%expected);

done;
