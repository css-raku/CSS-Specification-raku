unit grammar Test::CSS::Aural::Spec::Grammar;
#| <angle> | [[ left-side | far-left | left | center-left | center | center-right | right | far-right | right-side ] || behind ] | leftwards | rightwards
rule decl:sym<azimuth> {;
:i (azimuth) ":" <val(/ <expr=.expr-azimuth> /, &?ROUTINE.WHY)> }
rule expr-azimuth { :i <angle> | [[:my @S;
; [[["left-side" | "far-left" | left | "center-left" | center | "center-right" | right | "far-right" | "right-side" ]& <keyw>]]<!{
    @S[0]++
}>| [behind & <keyw>]<!{
    @S[1]++
}>]+] | [[leftwards | rightwards ]& <keyw>]  }
#| <uri> | none
rule decl:sym<cue-after> {;
:i ("cue-after") ":" <val(/ <expr=.expr-cue-after> /, &?ROUTINE.WHY)> }
rule expr-cue-after { :i <uri> | [none & <keyw>]  }
#| <uri> | none
rule decl:sym<cue-before> {;
:i ("cue-before") ":" <val(/ <expr=.expr-cue-before> /, &?ROUTINE.WHY)> }
rule expr-cue-before { :i <uri> | [none & <keyw>]  }
#| [ 'cue-before' || 'cue-after' ]
rule decl:sym<cue> {;
:i (cue) ":" <val(/ <expr=.expr-cue> /, &?ROUTINE.WHY)> }
rule expr-cue { :i [[:my @S;
; <expr-cue-before><!{
    @S[0]++
}>| <expr-cue-after><!{
    @S[1]++
}>]+] }
#| <angle> | below | level | above | higher | lower
rule decl:sym<elevation> {;
:i (elevation) ":" <val(/ <expr=.expr-elevation> /, &?ROUTINE.WHY)> }
rule expr-elevation { :i <angle> | [[below | level | above | higher | lower ]& <keyw>]  }
#| [ [<time> | <percentage>]{1,2} ]
rule decl:sym<pause> {;
:i (pause) ":" <val(/ <expr=.expr-pause> /, &?ROUTINE.WHY)> }
rule expr-pause { :i [[<time> | <percentage> ]** 1..2] }
#| <time> | <percentage>
rule decl:sym<pause-after> {;
:i ("pause-after") ":" <val(/ <expr=.expr-pause-after> /, &?ROUTINE.WHY)> }
rule expr-pause-after { :i <time> | <percentage>  }
#| <time> | <percentage>
rule decl:sym<pause-before> {;
:i ("pause-before") ":" <val(/ <expr=.expr-pause-before> /, &?ROUTINE.WHY)> }
rule expr-pause-before { :i <time> | <percentage>  }
#| <number>
rule decl:sym<pitch-range> {;
:i ("pitch-range") ":" <val(/ <expr=.expr-pitch-range> /, &?ROUTINE.WHY)> }
rule expr-pitch-range { :i <number> }
#| <frequency> | x-low | low | medium | high | x-high
rule decl:sym<pitch> {;
:i (pitch) ":" <val(/ <expr=.expr-pitch> /, &?ROUTINE.WHY)> }
rule expr-pitch { :i <frequency> | [["x-low" | low | medium | high | "x-high" ]& <keyw>]  }
#| <uri> [ mix || repeat ]? | auto | none
rule decl:sym<play-during> {;
:i ("play-during") ":" <val(/ <expr=.expr-play-during> /, &?ROUTINE.WHY)> }
rule expr-play-during { :i <uri> [[:my @S;
; [mix & <keyw>]<!{
    @S[0]++
}>| [repeat & <keyw>]<!{
    @S[1]++
}>]+]?  | [[auto | none ]& <keyw>]  }
#| <number>
rule decl:sym<richness> {;
:i (richness) ":" <val(/ <expr=.expr-richness> /, &?ROUTINE.WHY)> }
rule expr-richness { :i <number> }
#| normal | none | spell-out
rule decl:sym<speak> {;
:i (speak) ":" <val(/ <expr=.expr-speak> /, &?ROUTINE.WHY)> }
rule expr-speak { :i [[normal | none | "spell-out" ]& <keyw>] }
#| once | always
rule decl:sym<speak-header> {;
:i ("speak-header") ":" <val(/ <expr=.expr-speak-header> /, &?ROUTINE.WHY)> }
rule expr-speak-header { :i [[once | always ]& <keyw>] }
#| digits | continuous
rule decl:sym<speak-numeral> {;
:i ("speak-numeral") ":" <val(/ <expr=.expr-speak-numeral> /, &?ROUTINE.WHY)> }
rule expr-speak-numeral { :i [[digits | continuous ]& <keyw>] }
#| code | none
rule decl:sym<speak-punctuation> {;
:i ("speak-punctuation") ":" <val(/ <expr=.expr-speak-punctuation> /, &?ROUTINE.WHY)> }
rule expr-speak-punctuation { :i [[code | none ]& <keyw>] }
#| <number> | x-slow | slow | medium | fast | x-fast | faster | slower
rule decl:sym<speech-rate> {;
:i ("speech-rate") ":" <val(/ <expr=.expr-speech-rate> /, &?ROUTINE.WHY)> }
rule expr-speech-rate { :i <number> | [["x-slow" | slow | medium | fast | "x-fast" | faster | slower ]& <keyw>]  }
#| <number>
rule decl:sym<stress> {;
:i (stress) ":" <val(/ <expr=.expr-stress> /, &?ROUTINE.WHY)> }
rule expr-stress { :i <number> }
#| [<generic-voice> | <specific-voice> ]#
rule decl:sym<voice-family> {;
:i ("voice-family") ":" <val(/ <expr=.expr-voice-family> /, &?ROUTINE.WHY)> }
rule expr-voice-family { :i [<generic-voice> | <specific-voice> ]+% <op(",")> }
#| male | female | child
rule generic-voice {;
:i [[male | female | child ]& <keyw>] }
#| <identifier> | <string>
rule specific-voice {;
:i <identifier> | <string>  }
#| <number> | <percentage> | silent | x-soft | soft | medium | loud | x-loud
rule decl:sym<volume> {;
:i (volume) ":" <val(/ <expr=.expr-volume> /, &?ROUTINE.WHY)> }
rule expr-volume { :i <number> | <percentage> | [[silent | "x-soft" | soft | medium | loud | "x-loud" ]& <keyw>]  }
#| [ <color> | transparent ]{1,4}
rule decl:sym<border-color> {;
:i ("border-color") ":" <val(/ <expr=.expr-border-color> /, &?ROUTINE.WHY)> }
rule expr-border-color { :i [<color> | [transparent & <keyw>] ]** 1..4 }
#| <color> | transparent
rule decl:sym<border-top-color> {;
:i ("border-top-color") ":" <val(/ <expr=.expr-border-top-color> /, &?ROUTINE.WHY)> }
rule expr-border-top-color { :i <color> | [transparent & <keyw>]  }
#| <color> | transparent
rule decl:sym<border-right-color> {;
:i ("border-right-color") ":" <val(/ <expr=.expr-border-right-color> /, &?ROUTINE.WHY)> }
rule expr-border-right-color { :i <color> | [transparent & <keyw>]  }
#| <color> | transparent
rule decl:sym<border-bottom-color> {;
:i ("border-bottom-color") ":" <val(/ <expr=.expr-border-bottom-color> /, &?ROUTINE.WHY)> }
rule expr-border-bottom-color { :i <color> | [transparent & <keyw>]  }
#| <color> | transparent
rule decl:sym<border-left-color> {;
:i ("border-left-color") ":" <val(/ <expr=.expr-border-left-color> /, &?ROUTINE.WHY)> }
rule expr-border-left-color { :i <color> | [transparent & <keyw>]  }