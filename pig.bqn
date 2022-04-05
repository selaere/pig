#! /usr/bin/env bqn

cr‿lf ← @+13‿10

fmtItalics ← @+29

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
    Logln ">>> "∾𝕩
    •term.OutRaw 𝕩∾cr‿lf
    •term.Flush @
}
Send ← SendUTF8∘ToUTF8

IRCParse ← { 𝕊 in: 
    in ↓˜↩ - ⊑⊐⟜0 ⌽ (cr⊸= ∨ lf⊸=) in    # remove line endings
    spc‿cln ← in⊸=¨ " :"
    cln ↩ ¬ ⟨1⟩⊒ 0 » spc ∧ 0«cln    # keep only when followed by spaces
    wds ← (×≠¨)⊸/ in ⊔˜ (⊢ -˜ ¬ ∧ +`) cln∨ spc∧ ¬∨`cln    # strips colons too!
    wds ∾⟜⟨""⟩⍟(¯1 ⊑ cln)↩    # if the colon is at the end, add an empty argument
    src ← ""
    {𝕊: src ↩ 1 ↓ ⊑wds
        wds ↓˜↩ 1}⍟⊢ ':' = ⊑in
    ⟨src, ⊑ wds, 1 ↓ wds⟩    # src‿name‿args
}
! "pig"‿"PRIVMSG"‿("#a"‿":  bee sus") ≡ IRCParse ":pig PRIVMSG  #a  ::  bee sus"∾cr‿lf
! ""‿"pig"‿("PRIVMSG"‿"#a"‿"among"‿"us") ≡ IRCParse "pig PRIVMSG  #a    among us"
! "irc.example.com"‿"CAP"‿("*"‿"LIST"‿"") ≡ IRCParse ":irc.example.com CAP * LIST :"∾(10/⋈cr)∾lf
! "AutoBotRobot"‿"PRIVMSG"‿("#b"‿"<9DrakeBot> :tada: Congratulations to") ≡ {
    IRCParse ":AutoBotRobot PRIVMSG #b :<9DrakeBot> :tada: Congratulations to"
}

alternatives ← "piglet"‿"hog"‿"swine"‿"pork"‿"shoat"‿"boar"‿"sow"‿"shoat"‿"suid"‿"farrow"‿"boneen"

name ← "pig"

ParseCommand ← ⊑∘⊐⟜' ' ⊸ (↑ ⋈ 1⊸+⊸↓)

OnMessage ← {
    𝕊 ·‿"STARTPLZ"‿·:
        # this is not actually an irc command. it is sent by the shell file to tell this file to 
        # send the login commands and shit
        Send "NICK "∾name
        Send "USER "∾name∾" 0 * :"∾fmtItalics∾"Sus domesticus"
    ;
    𝕊 ·‿"433"‿·:    # ERR_NICKNAMEINUSE
        name ↩ Pick alternatives
        Send "NICK "∾name
    ;
    𝕊 ·‿"001"‿·:    # RPL_WELCOME
        Send "MODE "∾name∾" +x"
        Send "JOIN #b"
        Send "PRIVMSG #b 🐖"
    ;
    𝕊 ·‿"PING"‿args:
        Send {0=≠args? "PONG" ; "PONG :"∾¯1⊑args}
    ;
    𝕊 src‿"PRIVMSG"‿(chan‿msg):
    ∨´ pigs ← (name∾" ") ⍷ " " ∾˜ msg?
        name‿args ← ParseCommand msg ↓˜ (1+≠name) + ⊑/pigs
        {src⇐src,chan⇐chan,args⇐args} DoCommand⎊({
            𝕨 Say "*vomits on ground*"
            Logln "!!! "∾𝕩
        }⟜•CurrentError) name
    ; @
}

# send lines of around `bytes` bytes, without splitting utf-8 sequence boundaries
Saylns ← {
    bytes ← 420    # maximum bytes to send
    utf ← CpToUTF8∘-⟜@¨ 𝕩 
    lines ← utf ⊔˜ bytes ⌊∘÷˜ 0 {⟨𝕨+≠𝕩, ⌈⌾(÷⟜bytes) 𝕨⟩ ⊑˜ 10=⊑𝕩}` utf
    SendUTF8∘(10⊸≠⊸/ (ToUTF8 ResponsePrefix 𝕨) ∾ ∾)¨ lines
}

ResponsePrefix ← " :"∾˜"PRIVMSG "∾{𝕩.chan≡"pig"? ⊑∘⊐⟜'!' ⊸ ↑ 𝕩.src; 𝕩.chan}

Say ← Send  ⊢ ∾˜ ResponsePrefix∘⊣

susBQN ← •ReBQN {repl⇐"loose",scope⇐"none"}
# provide some builtins
SusBQN ∾ (⊢ ∾ "←•" ∾ ∾⟜lf)¨ "rand"‿"math"‿"Fmt"‿"Repr"‿"Type"‿"Glyph"‿"Decompose"‿"MakeRand"‿"bit"

keyfm ← "`123456890-=~!@#$%^&*()_+qwertuiop[]QWERTIOP{}asdfghjkl;ASFGHKL:zxcvbm,./ZXVBM<>? '\"""
keyto ← "˜˘¨⁼⌜´˝∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧⊔⊏⊐π←→↙𝕎⍷𝕣⍋⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↖𝕊𝔽𝔾«⌾»·⥊𝕩↓∨⌊≡∾≍≠⋈𝕏⍒⌈≢≤≥⇐‿↩\˙🐖"
# 🐖 will be used when no escape is found

# resolves BQN escapes as in https://mlochbaum.github.io/BQN/keymap.html
Unescape ← {
    code ← 𝕩 (⊣ ↓ -⊸↓)˜ (⊑∘⊐⟜0 ⌊ ⊑∘⊐⟜0∘⌽) '`' = 𝕩   # removes as many ticks it can
    bsls ← ¬⊸∨` '\' ≠ code    # in \\ only the first backslash should be escaped
    bsls / (keyto ⊏˜ keyfm ⊐ ⊢)⌾((»¬bsls)⊸/) code
}

Pick ← •rand.Range∘≠ ⊑ ⊢

DoCommand ← {
    cx 𝕊 "say":
        cx Say cx.args
    ;
    cx 𝕊 "do":
        code ← '#'⍟('⍝'⊸=)¨ ('•'⊸≠ / ⊢) Unescape cx.args
        ! ¬⊑ '•' ∊ code    # this should NOT happen
        cx Saylns {1 = =𝕩? ∧´ 2 = •Type¨ 𝕩? 𝕩; •Fmt 𝕩}∘SusBQN⎊("Error: "∾•CurrentError) code
    ;
    cx 𝕊 "perform":
        cx DoCommand "unescape"
        cx DoCommand "do"
    ;
    cx 𝕊 "unescape":
        cx Saylns ("```"⊸∾∾⟜"```") Unescape cx.args
    ;
    cx 𝕊 "join": ¬ ∨´ " ," ∊ cx.args? '#' = ⊑ cx.args?
        cx Say "omw"
        Send "JOIN "∾cx.args
    ;
    cx 𝕊 "leave":
        cx Say "omw"
        Send "PART "∾cx.chan
    ;
    cx 𝕊 "emete":
        "emetion triggered" ! 0
    ;
    cx 𝕊 "please":
        name‿args ← ParseCommand cx.args
        {src⇐ cx.src, chan⇐ cx.chan, args⇐ args} DoCommand name
        cx Say ∾ Pick¨ ⟨
            ⟨"my pleasure"
             "forget it"
             "not at all"
             "yw"
             "np"⟩∾ 2/⟨"you're welcome"
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
        csnts ← "bcdfghjklmnpqrstvwxz"
        cx Saylns ∾ {
            0 = ≠𝕩? "";
            ¬⊑ 𝕩 ∊ ltrs? 𝕩;
            wd ← +⟜(32×'Z'⊸≥)¨ 𝕩
            t ← ⊑⊐⟜0 (0∾"qu"⍷wd)∨ 1⌾⊑⍟('y'=⊑wd) wd ∊ csnts
            (t↓wd) ∾ (t↑wd) ∾ ("w"/˜t=0) ∾ "ay"
        }¨ cx.args ⊔˜ +` (⊢ ∨ 1»⊢) ¬ ltrs ∊˜ cx.args
    ;
    cx 𝕊 "bee":
        Number ← {𝕊: ⌊ 1024 ÷ 10+•rand.Range 256}
        Repeat ← Number⊸/
        choices ← ∾ ⟨
            3/⟨{𝕊: "bee"∾(Repeat "e")∾(Pick ""‿""‿"s")∾(Repeat "!")}⟩
            3/⟨{𝕊: "bzz"∾(Repeat "z")∾(Pick ""‿"t")∾(Pick ""‿"!")}⟩
              ⟨"c:"⟩
              ⟨"apio"⟩
        ⟩
        cx Saylns {𝕊: 𝕩 ∾ ∾⟜' '⍟(7≥•rand.Range 10) (Pick choices){𝔽} 1 }⍟Number ⟨⟩
    ;
    cx 𝕊 cmd:
        cx Say "oink"
}

Main ← {𝕊:
    Logln "starting..."
    { 𝕊:
        Log "... "
        (OnMessage∘IRCParse @˙ Logln) •GetLine @
    } •_while_ 1 @
}


Main⍟{𝕊:"run"≡⊑•args}⍟(1≤≠•args) @