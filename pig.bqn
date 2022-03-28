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
ToUTF8 ← ∾ ∘ (CpToUTF8¨ ∘ -⟜@)
! 226‿138‿145‿240‿157‿149‿168‿47‿240‿157‿149‿169 ≡ ToUTF8 "⊑𝕨/𝕩"    # [*"⊑𝕨/𝕩".encode('utf-8')]

# https://github.com/dzaima/CBQN/blob/master/docs/system.md#term
SendUTF8 ← {
    "sending more than 512 bytes" ! 510 ≥ ≠𝕩
    Logln ">>> "∾𝕩
    •term.OutRaw 𝕩∾cr‿lf
    •term.Flush @
}
Send ← SendUTF8∘ToUTF8

Parse ← { 𝕊 in: 
    in ↓˜↩ - ⊑⊐⟜0 ⌽ (cr⊸= ∨ lf⊸=) in    # remove line endings
    spc‿cln ← in⊸=¨ " :"
    cln ↩ ¬ ⟨1⟩⊒ 0 » spc ∧ 0«cln    # keep only when followed by spaces
    wds ← (×≠¨)⊸/ in ⊔˜ (⊢ -˜ ¬ ∧ +`) cln∨ spc∧ ¬∨`cln    # strips colons too!
    wds ∾⟜⟨""⟩⍟(¯1 ⊑ cln)↩    # if the colon is at the end, add an empty argument
    src ← ""
    { 𝕊: src ↩ 1 ↓ ⊑wds ⋄ wds ↓˜↩ 1} ⍟ ⊢ (':'=⊑in)
    ⟨src, ⊑ wds, 1 ↓ wds⟩    # src‿name‿args
}
! "pig"‿"PRIVMSG"‿("#a"‿":  bee sus") ≡ Parse ":pig PRIVMSG  #a  ::  bee sus"∾cr‿lf
! ""‿"pig"‿("PRIVMSG"‿"#a"‿"among"‿"us") ≡ Parse "pig PRIVMSG  #a    among us"
! "irc.example.com"‿"CAP"‿("*"‿"LIST"‿"") ≡ Parse ":irc.example.com CAP * LIST :"∾(10/⋈cr)∾lf
! "AutoBotRobot"‿"PRIVMSG"‿("#b"‿"<9DrakeBot> :tada: Congratulations to") ≡ {
    Parse ":AutoBotRobot PRIVMSG #b :<9DrakeBot> :tada: Congratulations to"
}

SplitCommand ← ⊑∘⊐⟜' ' ⊸ (↑ ⋈ 1⊸+⊸↓)

Choose ← {
    𝕊 ·‿"STARTPLZ"‿·:
        # this is not actually an irc command. it is sent by the shell file to tell this file to 
        # send the login commands and shit
        Send "NICK pig"
        Send "USER pig 0 * pig"
    ;
    𝕊 ·‿"001"‿·:
        Send "MODE pig +x"
        Send "JOIN #b"
        Send "PRIVMSG #b 🐖"
        # Send "WHOIS pig"
    ;
    𝕊 ·‿"PING"‿args:
        Send {0=≠args? "PONG" ; "PONG :"∾¯1⊑args}
        #Send "PRIVMSG #aa oink"
    ;
    𝕊 src‿"PRIVMSG"‿(chan‿msg):
    ∨´ pigs ← "pig " ⍷ " " ∾˜ msg?
        name‿args ← SplitCommand msg ↓˜ 4 + ⊑/pigs
        {src⇐src,chan⇐chan,args⇐args} ChooseCommand⎊({
            𝕨 Say "*vomits on ground*"
            Logln "!!! "∾𝕩
        }⟜•CurrentError) name
    ; @
}

Saylns ← {
    start ← ToUTF8 "PRIVMSG "∾𝕨.chan∾" :"
    bytes ← 400    # maximum bytes to send. might be adjusted to something better later
    utf ← CpToUTF8∘-⟜@¨ 𝕩
    lfs ← lf = 𝕩
    lines ← utf ⊔˜ lfs (¬∘⊣⊸∧ - ⊣) ⊑¨ {
        a‿b 𝕊 l‿x: {l ∨ bytes<b+x? ⟨a+1, l×x⟩; ⟨a, b+x⟩}
    }` lfs (⊣⋈·≠⊢)¨ utf    # this might be possible with a 2d array, maybe
    SendUTF8∘(start ∾ ∾)¨ lines
}

Say ← {Send "PRIVMSG "∾𝕨.chan∾" :"∾𝕩}

keyfm ← "`123456890-=~!@#$%^&*()_+qwertuiop[]QWERTIOP{}asdfghjkl;ASFGHKL:zxcvbm,./ZXVBM<>? '\"""
keyto ← "˜˘¨⁼⌜´˝∞¯•÷×¬⎉⚇⍟◶⊘⎊⍎⍕⟨⟩√⋆⌽𝕨∊↑∧⊔⊏⊐π←→↙𝕎⍷𝕣⍋⊑⊒⍳⊣⊢⍉𝕤↕𝕗𝕘⊸∘○⟜⋄↖𝕊𝔽𝔾«⌾»·⥊𝕩↓∨⌊≡∾≍≠⋈𝕏⍒⌈≢≤≥⇐‿↩\˙🐖"
# 🐖 will be used when no escape is found

susBQN ← •ReBQN {repl⇐"loose",scope⇐"none"}
susBQN¨ "rand←•rand"‿"math←•math"‿"Fmt←•Fmt"‿"Type←•Type"‿"UnixTime←•UnixTime"‿"Glyph←•Glyph"

Unescape ← {
    code ← 𝕩 (⊣ ↓ -⊸↓)˜ (⊑∘⊐⟜0 ⌊ ⊑∘⊐⟜0∘⌽) '`' = 𝕩   # removes as many ticks it can
    bsls ← ¬⊸∨` '\' ≠ code    # in \\ only the first backslash should be escaped
    (⊢ /˜ bsls ∧ '•'⊸≠) (keyto ⊏˜ keyfm ⊐⊢)⌾((»¬bsls)⊸/) code
}

Pick ← •rand.Range∘≠ ⊑ ⊢
ChooseCommand ← {
    cx 𝕊 "say":
        cx Say cx.args
    ;
    cx 𝕊 "do":
        cx Saylns {1 = =𝕩? ∧´ 2 = •Type¨ 𝕩? 𝕩; •Fmt 𝕩}∘SusBQN⎊("Error: "∾•CurrentError) Unescape cx.args
    ;
    cx 𝕊 "perform":
        cx ChooseCommand "unescape"
        cx ChooseCommand "do"
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
    cx 𝕊 "please":
        name‿args ← SplitCommand cx.args
        {src⇐ cx.src, chan⇐ cx.chan, args⇐ args} ChooseCommand name
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
    cx 𝕊 cmd:
        cx Say "oink"
}

Main ← {𝕊:
    Logln "starting..."

    { 𝕊:
        Log "... "
        (Choose∘Parse @˙ Logln) •GetLine @
    } •_while_ 1 @
}


Main⍟{𝕊:"run"≡⊑•args}⍟(1≤≠•args) @