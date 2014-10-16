use v6;

grammar CSS::Specification::_Base {

    proto rule proforma {*}

    token val($rx,$doc='',$boxed=False) {
        [$<boxed>=<?{$boxed}>]? [ <proforma> || <rx={$rx}>|| <usage($doc)> ]
    }

    token seen($opt) {
        <?{@*SEEN[$opt]++}>
    }

    token usage($doc) {
        :my $*USAGE;
        <any-args> {$*USAGE = ~$doc}
    }

}
