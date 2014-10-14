use v6;

grammar CSS::Specification::_Base {

    token seen($opt) {
           <?{@*SEEN[$opt]++}>
    }


    token usage($doco) {
        :my $*USAGE;
        <any-args> {$*USAGE = ~$doco}
    }

}
