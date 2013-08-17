
" Adjusted by Niels Aan de Brugh for df_mode. All due to credits to the
" original author for an awesome theme!

set background=dark

hi clear

if exists("syntax_on")
  syntax reset
endif

let colors_name = "twilight_df"

let s:grey_blue = '#8a9597'
let s:light_grey_blue = '#a0a8b0'
let s:dark_grey_blue = '#34383c'
" More readable comments. Style and function go hand in hand.
" let s:mid_grey_blue = '#64686c'     " original value
" let s:mid_grey_blue = '#707579'     " lighter alternative
let s:mid_grey_blue = '#7d8286'
let s:beige = '#ceb67f'
let s:light_orange = '#ebc471'
let s:yellow = '#e3d796'
let s:violet = '#a999ac'
let s:green = '#a2a96f'
let s:lightgreen = '#c2c98f'
let s:red = '#d08356'
let s:cyan = '#74dad9'
let s:darkgrey = '#1a1a1a'
let s:grey = '#303030'
let s:lightgrey = '#605958'
let s:white = '#fffedc'

" This was never easier...
let g:df_mode_greenish = s:green
let g:df_mode_reddish = s:red
let g:df_mode_colors_based_on = g:colors_name

if version >= 700
  hi CursorLine guibg=#262626
  hi CursorColumn guibg=#262626
  hi MatchParen guifg=white guibg=#80a090 gui=bold

  "Tabpages
  hi TabLine guifg=#a09998 guibg=#202020 gui=underline
  hi TabLineFill guifg=#a09998 guibg=#202020 gui=underline
  hi TabLineSel guifg=#a09998 guibg=#404850 gui=underline

  "P-Menu (auto-completion)
  " hi Pmenu guifg=#605958 guibg=#303030 gui=underline
  " hi PmenuSel guifg=#a09998 guibg=#404040 gui=underline

  " Ugh, underline...
  hi Pmenu guifg=#605958 guibg=#303030
  hi PmenuSel guifg=#a09998 guibg=#404040
  "PmenuSbar
  "PmenuThumb
endif

hi Visual guibg=#404040

"hi Cursor guifg=NONE guibg=#586068
hi Cursor guibg=#b0d0f0


exe 'hi Normal         guifg='.s:white             .' guibg='.s:darkgrey
exe 'hi Underlined     guifg='.s:white             .' guibg=bg gui=underline'
" exe 'hi NonText        guifg='.s:lightgrey         .' guibg='.s:grey
hi NonText        guifg=bg
exe 'hi SpecialKey     guifg='.s:grey              .' guibg=bg'

"exe 'hi LineNr         guifg='.s:mid_grey_blue     .' guibg='.s:dark_grey_blue  .' gui=none'
exe 'hi LineNr         guifg='.s:mid_grey_blue     .' guibg=bg gui=none'
exe 'hi StatusLine     guifg='.s:white             .' guibg='.s:grey            .' gui=italic,underline'
exe 'hi StatusLineNC   guifg='.s:lightgrey         .' guibg='.s:grey            .' gui=italic,underline'
" exe 'hi VertSplit      guifg='.s:grey              .' guibg='.s:grey            .' gui=none'
hi VertSplit      guifg=bg  guibg=bg

exe 'hi Folded         guifg='.s:grey_blue         .' guibg='.s:dark_grey_blue  .' gui=none'
exe 'hi FoldColumn     guifg='.s:grey_blue         .' guibg='.s:dark_grey_blue  .' gui=none'
exe 'hi SignColumn     guifg='.s:grey_blue         .' guibg='.s:dark_grey_blue  .' gui=none'

exe 'hi Comment        guifg='.s:mid_grey_blue     .' guibg=bg gui=italic'
exe 'hi TODO           guifg='.s:grey_blue         .' guibg=bg gui=italic,bold'

exe 'hi Title          guifg='.s:red               .' guibg=bg gui=underline'

exe 'hi Constant       guifg='.s:red               .' guibg=bg gui=none'
exe 'hi String         guifg='.s:green             .' guibg=bg gui=none'
exe 'hi Special        guifg='.s:lightgreen        .' guibg=bg gui=none'

exe 'hi Identifier     guifg='.s:grey_blue         .' guibg=bg gui=none'
exe 'hi Statement      guifg='.s:beige             .' guibg=bg gui=none'
exe 'hi Conditional    guifg='.s:beige             .' guibg=bg gui=none'
exe 'hi Repeat         guifg='.s:beige             .' guibg=bg gui=none'
exe 'hi Structure      guifg='.s:beige             .' guibg=bg gui=none'
exe 'hi Function       guifg='.s:violet            .' guibg=bg gui=none'

exe 'hi PreProc        guifg='.s:grey_blue         .' guibg=bg gui=none'
exe 'hi Operator       guifg='.s:light_orange      .' guibg=bg gui=none'
exe 'hi Type           guifg='.s:yellow            .' guibg=bg gui=italic'

"hi Identifier guifg=#7587a6
" Type d: 'class'
"hi Structure guifg=#9B859D gui=underline
"hi Function guifg=#dad085
" dylan: method, library, ... d: if, return, ...
"hi Statement guifg=#7187a1 gui=NONE
" Keywords  d: import, module...
"hi PreProc guifg=#8fbfdc
"gui=underline
"hi Operator guifg=#a07020
"hi Repeat guifg=#906040 gui=underline
"hi Type guifg=#708090

"hi Type guifg=#f9ee98 gui=NONE

"hi NonText guifg=#808080 guibg=#303030

"hi Macro guifg=#a0b0c0 gui=underline

"Tabs, trailing spaces, etc (lcs)
"hi SpecialKey guifg=#808080 guibg=#343434

"hi TooLong guibg=#ff0000 guifg=#f8f8f8

hi Search guifg=#606000 guibg=#c0c000 gui=bold

hi Directory guifg=#dad085 gui=NONE
hi Error guibg=#602020

