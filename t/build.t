#!/usr/bin/env perl6

use Test;
use CSS::Grammar::Test;
use CSS::Specification::Build;

sub pipe($input-path, $code) {
    my $output;

    my $*IN = open $input-path, :r;
    my $*OUT = class {
        method print(*@args) {
            $output ~= @args.join;
        }
        multi method write(Buf $b){$output ~= $b.decode}
    }
    $code();
    return $output;
}

my $base-name = 'CSS::Aural::Spec';
my $grammar-name = $base-name ~ '::Grammar';
my $actions-name = $base-name ~ '::Actions';
my $interface-name = $base-name ~ '::Interface';

my $aural-grammar-code = pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'grammar', $grammar-name );
});
ok $aural-grammar-code, 'grammar generation';
lives_ok {EVAL $aural-grammar-code}, 'grammar compilation';

my $aural-actions-code = pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'actions', $actions-name );
});
ok $aural-actions-code, 'actions generation';
lives_ok {EVAL $aural-actions-code}, 'actions compilation';

my $aural-interface-code = pipe( 'examples/css21-aural.txt', {
    CSS::Specification::Build::generate( 'interface', $interface-name );
});
ok $aural-interface-code, 'interface generation';
lives_ok {EVAL $aural-interface-code}, 'interface compilation';

# compose some classess

use CSS::Grammar::CSS21;
use CSS::Grammar::Actions;

dies_ok {EVAL q:to"--END--"}, 'grammar composition, unimplemented interface - dies';
grammar CSS::Aural::CrappyGrammar
    is CSS::Aural::Spec::Grammar 
    is CSS::Grammar::CSS21
    does CSS::Aural::Spec::Interface {
}
--END--

my $aural-class;

lives_ok {EVAL q:to"--END--"}, 'grammar composition - lives';
grammar CSS::Aural::Grammar
    is CSS::Aural::Spec::Grammar 
    is CSS::Grammar::CSS21
    does CSS::Aural::Spec::Interface {

    rule module-declaration:sym<test> { <.ws>? <decl> <prio>? <any-arg>* <end-decl> }
    proto rule decl {*}

    token keyw        {<ident>}             # keyword (case insensitive)
    token identifier  {<name>}              # identifier (case sensitive)
    token number      {<num> <!before ['%'|\w]>}
    token uri         {<url>}

    rule generic-voice  {:i [ male | female | child ] & <keyw> }
    rule specific-voice {:i <identifier> | <string> }
}

$aural-class = CSS::Aural::Grammar;
--END--

my $aural-actions;

lives_ok {EVAL q:to"--END--"}, 'class composition - lives';
our class CSS::Aural::Actions
    is CSS::Aural::Spec::Actions 
    is CSS::Grammar::Actions
    does CSS::Aural::Spec::Interface {

    method module-declaration:sym<test>($/)  { make $<decl>.ast; }
    method keyw($/)        { make $<ident>.ast }
    method identifier($/)  { make $<name>.ast }
    method number($/)      { make $<num>.ast }
    method uri($/)         { make $<url>.ast }

    method generic-voice($/) { make $.list($/) }
    method specific-voice($/) { make $.list($/) }

    method decl($/, $_synopsis) {
	my $property = (~$0).trim.lc;
        my @expr = @( $.list($<expr>) );
        my %ast = property => $property, expr => @expr;

        return %ast;
    }

}

$aural-actions = CSS::Aural::Actions.new;
--END--

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
