#! /usr/bin/env bqn

cr‿lf ← @+13‿10
Log ← •term.ErrRaw
Logln ← Log ∾⟜lf

# Codepoint to UTF-8
cpToUTF8 ← {
    Cnt ← 128 + 64⊸|    # make continuation byte
    Shr ← ⌊ ⊢ ÷ ⋆˜⟜2    # 𝕩 >> 𝕨
    {
        𝕩 < 2⋆ 7? ⟨             𝕩                                  ⟩ ;
        𝕩 < 2⋆11? ⟨192 +  6 Shr 𝕩,                            Cnt 𝕩⟩ ;
        𝕩 < 2⋆16? ⟨224 + 12 Shr 𝕩,               Cnt 6 Shr 𝕩, Cnt 𝕩⟩ ;
                  ⟨240 + 18 Shr 𝕩, Cnt 12 Shr 𝕩, Cnt 6 Shr 𝕩, Cnt 𝕩⟩
    }
}
ToUTF8 ← ∾ · CpToUTF8¨ -⟜@
! 226‿138‿145‿240‿157‿149‿168‿47‿240‿157‿149‿169 ≡ ToUTF8 "⊑𝕨/𝕩"    # [*"⊑𝕨/𝕩".encode('utf-8')]

# https://github.com/dzaima/CBQN/blob/master/docs/system.md#term
SendUTF8 ← {
    "sending more than 512 bytes" ! 510 ≥ ≠𝕩
    Logln (Time@)∾">>> "∾𝕩
    •term.OutRaw 𝕩∾cr‿lf
    •term.Flush @
}
Send ← SendUTF8∘ToUTF8

IRCParse ← { 𝕊 in:
    in ¬∘(∧`⌾⌽∊⟜cr‿lf)⊸/↩
    cln←»⊸<∨`(»spc)∧⊑·‿spc←in⊸=¨": "
    2(↑∾⟜<↓)in⊔˜(-+¬×(¯1⊸∨⌾⊑(':'≠⊑in)⥊˜≢)+cln+⌾⊑⌾⌽·+`»⊸<) 0∾˜cln∨spc∧¬∨`cln
}
! "pig"‿"PRIVMSG"‿("#a"‿":  bee sus") ≡ IRCParse ":pig PRIVMSG  #a  ::  bee sus"∾cr‿lf
! ""‿"pig"‿("PRIVMSG"‿"#a"‿"among"‿"us") ≡ IRCParse "pig PRIVMSG  #a    among us"
! "irc.example.com"‿"CAP"‿("*"‿"LIST"‿"") ≡ IRCParse ":irc.example.com CAP * LIST :"∾(10/⋈cr)∾lf
! "AutoBotRobot"‿"PRIVMSG"‿("#b"‿"<9DrakeBot> :tada: Congratulations to") ≡ {
    IRCParse ":AutoBotRobot PRIVMSG #b :<9DrakeBot> :tada: Congratulations to"
}

alternatives ← "piglet"‿"hog"‿"swine"‿"pork"‿"shoat"‿"boar"‿"sow"‿"suid"‿"farrow"‿"boneen"
name ← "pig"
lastreq ← 0

OnMessage ← {
    # this is not actually an irc command. it is sent by the shell file to tell this file to send
    # the login commands and stuff
    𝕊 ·‿"STARTPLZ"‿·:
        Send¨ ("NICK "∾name)‿("USER "∾name∾" 0 * :"∾(@+29)∾"Sus domesticus")
    ;
    𝕊 ·‿"433"‿·: Send   "NICK "∾name↩Pick alternatives ;                # ERR_NICKNAMEINUSE
    𝕊 ·‿"001"‿·: Send¨ ("MODE "∾name∾" +x")‿"JOIN #b"‿"PRIVMSG #b 🐖" ; # RPL_WELCOME
    𝕊 ·‿"PING"‿args: Send args (⊢∾" :"∾¯1⊑⊣)⍟(0≠≠∘⊣) "PONG" ;
    𝕊 src‿"PRIVMSG"‿(chan‿msg):
    ∨´ pigs ← name⍷○(∾⟜' ')msg?
        name‿args ← ⊑∘⊐⟜' '⊸(↑⋈1⊸+⊸↓) msg ↓˜ 1+ (≠name) + ⊑/pigs
        {src⇐src,chan⇐chan,args⇐args} DelayedDoCommand⎊({
            𝕨 Say "*vomits on ground*" ⋄ Logln "!!! "∾𝕩
        }⟜•CurrentError) name
    ; @
}

# send lines of around `bytes` bytes, without splitting utf-8 sequence boundaries
Saylns ← {
    bytes ← 420    # maximum bytes to send
    utf ← CpToUTF8∘-⟜@¨ '␡'⍟((@+127)⊸=)¨ +⟜(('␀'-@)×' '⊸> ∧ lf⊸≠) 𝕩
    lines ← ∾¨ utf ⊔˜ bytes ⌊∘÷˜ 0 (10=⊑∘⊢)◶⟨+⟜≠,⌈⌾(÷⟜bytes)⊣⟩` utf
    lines (∾⟜⟨ToUTF8"etc"⟩ 10⊸↑)⍟(10<≠lines)↩
    SendUTF8∘(10⊸≠⊸/ (ToUTF8 ResponsePrefix 𝕨)∾⊢)¨ lines
}

ResponsePrefix ← "PRIVMSG "∾{𝕩.chan≡"pig"? ⊑∘⊐⟜'!'⊸↑ 𝕩.src; 𝕩.chan}∾" :"˙

Say ← Send ResponsePrefix⊸∾

susBQN ← •ReBQN {repl⇐"loose",scope⇐"none"}
# provide some builtins
SusBQN ∾ (⊢∾"←•"∾∾⟜lf)¨ "rand"‿"math"‿"Fmt"‿"Repr"‿"Type"‿"Glyph"‿"Decompose"‿"MakeRand"‿"ParseFloat"

keyfm ← "`123456890-=~!@#$%^&*()_+qwertuiop[]QWERTIOP{}asdfghjkl;ASFGHKL:zxcvbm,./ZXVBM<>? '\"""
keyto ← "˜˘¨⁼⌜´˝∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧⊔⊏⊐π←→↙𝕎⍷𝕣⍋⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↖𝕊𝔽𝔾«⌾»·⥊𝕩↓∨⌊≡∾≍≠⋈𝕏⍒⌈≢≤≥⇐‿↩\˙🐖"

Detick ← (⌊○(⊑⊐⟜0)⟜⌽ '`'⊸=)⊸(⊣↓-⊸↓)    # removes as many backticks as possible

Unescape ← (<`'\'⊸=)⊸{(¬𝕨)/(⊏⟜keyto keyfm⊸⊐)⌾((»𝕨)⊸/)𝕩}    # resolves BQN escapes

Pick ← (•rand.Range∘≠ ⊑ ⊢)⊘(•rand.Range⟜≠ ⊏ ⊢)

DelayedDoCommand ← {
    cx 𝕊 ·: 0.5 > (•MonoTime@) - lastreq? cx Say "wait!!!";
    𝕨 DoCommand 𝕩 ⋄ lastreq ↩ •MonoTime@
}

DoCommand ← {
    cx 𝕊 "say": cx Say cx.args;
    cx 𝕊 "do":
        code ← '#'⍟('⍝'⊸=)¨ '•'⊸≠⊸/ Unescape Detick cx.args
        ! ¬⊑'•'∊code    # this should NOT happen  # glad to know past me knew what an assertion was
        { ⊑"#" ∊ 𝕩? cx Say "nah" ⋄ "emetion triggered" ! 0 ;
            cx Saylns {1==𝕩? ∧´2=•Type¨𝕩? 𝕩; •Fmt𝕩}∘SusBQN⎊("Error: "∾•CurrentError) 𝕩
        } code
    ;
    cx 𝕊 "perform": cx⊸DoCommand¨ "unescape"‿"do";
    cx 𝕊 "rewrite": cx Saylns "```"(∾∾⊣) 1⊑•SH "vemf"‿"-r"‿"-e"‿(Detick cx.args) ;
    cx 𝕊 cmd: "act"≡3↑cmd ?
        cx Saylns (-lf=⊢´)⊸↓ 1⊑•SH "timeout"‿"10s"‿"vemf"‿"-f"‿("1"⍟(¬≠)3↓cmd)‿"-e"‿(Detick cx.args)
    ;
    cx 𝕊 cmd: "react"≡5↑cmd ? cx⊸DoCommand¨"rewrite"⋈2↓cmd ;
    cx 𝕊 "unescape": cx Saylns "```"(∾∾⊣) Unescape Detick cx.args ;
    cx 𝕊 "join": ¬∨´","∊cx.args? '#'=⊑cx.args? cx Say "omw" ⋄ Send "JOIN "∾cx.args ;
    cx 𝕊 "leave": cx Say "omw" ⋄ Send "PART "∾cx.chan ;
    cx 𝕊 "emete": "emetion triggered" ! 0 ;
    cx 𝕊 "please":
        name‿args ← ⊑∘⊐⟜' '⊸(↑⋈1⊸+⊸↓) cx.args
        {src⇐cx.src, chan⇐cx.chan, args⇐args} DoCommand name
        cx Say ∾ Pick¨ ⟨
            ⟨"my pleasure"
             "forget it"
             "not at all"
             "yw"
             "np"⟩ ∾ 2/⟨"you're welcome"
                        "no problem"
                        "it's nothing"
                        "it's a pleasure"
                        "no worries"⟩
            ⟨"!!"⟩ ∾ 2/"!"‿""
            " :D"‿" :>"‿" :]" ∾ 2/" c:"‿" :)"‿""
        ⟩
    ;
    cx 𝕊 "aysay":
        ltrs ← ∾ "Aa"⊸+¨↕26
        cx Saylns ∾{
            (∾∾"ay"∾˜"w"/˜2-≠)𝕩⊔˜∧` (0∾"qu"⍷𝕩)∨ 1⌾⊑⍟(('y'=⊑𝕩)∧·¬1⊑∾⟜0) ¬𝕩∊"aeiouy"
        }⍟(⊑1="a{"⍋⊢)¨ (+`·∨⟜» 1≠"a{"⍋⊢)⊸⊔ (32×1="A["⍋⊢)⊸+ cx.args
    ;
    cx 𝕊 "bee":
        Num ← {𝕤⋄ ⌊ 1024 ÷ 10+•rand.Range 256}
        cx Saylns ∾ {𝕏@}¨ (Num @) Pick ∾ ⟨
            3/⟨{𝕤⋄ "bee"∾(Num⊸/ "e")∾(Pick ""‿""‿"s")∾(Num⊸/ "!")∾Pick""‿" "‿" "}⟩
            3/⟨{𝕤⋄ "bzz"∾(Num⊸/ "z")∾(Pick ""‿"t")∾(Pick ""‿"!")∾Pick""‿" "‿" "}⟩
              ⟨{𝕤⋄ "c:"  ∾Pick""‿" "}⟩
              ⟨{𝕤⋄ "apio"∾Pick""‿" "}⟩
        ⟩
    ;
    cx 𝕊 "help": cx Say "i can "∾Pick ⟨
        "say","do","perform","rewrite","react","unescape","join","leave","emete","please"
        "aysay","bee","help","oink"⟩ ;
    cx 𝕊 cmd: cx Say "oink"
}
Time ← {𝕤⋄ ¯1↓1⊑•SH "date"‿"-u"‿"+%H:%M:%S"}

Main ← {𝕤
    Logln "starting..."
    {𝕤
        { Logln (Time@)∾"... "∾(@+8203)⊸≠⊸/ 𝕩 ⋄ OnMessage IRCParse 𝕩 } •GetLine @
    } •_while_ 1 @
}


Main⍟{𝕤⋄"run"≡⊑•args}⍟(1≤≠•args) @
