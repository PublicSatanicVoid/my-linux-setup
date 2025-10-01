" Vim syntax file
" Language:	Spice circuit simulator input netlist
" Maintainer:	Noam Halevy <Noam.Halevy.motorola.com>
" Last Change:	2012 Jun 01
" 		(Dominique Pelle added @Spell)
"
" This is based on sh.vim by Lennart Schultz
" but greatly simplified

" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" spice syntax is case INsensitive
syn case ignore

syn keyword	spiceTodo	contained TODO

"syn match spiceComment  "^ \=\*.*$" contains=@Spell
syn match spiceComment  "^\s*\*.*$" contains=@Spell
syn match spiceComment  "\$.*$" contains=@Spell

" Numbers, all with engineering suffixes and optional units
"==========================================================
"floating point number, with dot, optional exponent
syn match spiceNumber  "\<[0-9]\+\.[0-9]*\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="
"floating point number, starting with a dot, optional exponent
syn match spiceNumber  "\.[0-9]\+\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="
"integer number with optional exponent
syn match spiceNumber  "\<[0-9]\+\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="

" Misc
"=====
syn match   spiceWrapLineOperator       "\\$"
syn match   spiceWrapLineOperator       "^+"

syn match   spiceStatement      "^ \=\.\I\+"

" Matching pairs of parentheses
"==========================================
"syn region  spiceParen transparent matchgroup=spiceOperator start="(" end=")" contains=ALLBUT,spiceParenError
"syn region  spiceSinglequote matchgroup=spiceOperator start=+'+ end=+'+


" R and C
" =======

syn region spiceRC start=/^\s*[RC]\S\+/ end=/\(\n\++.*\)\@!$/ contains=spiceRCname keepend extend

syn match spiceRCname /^\s*[RC]\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceRCnode1
hi def link spiceRCname Identifier

syn match spiceRCnode1 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceRCnode2
syn match spiceRCnode2 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceRCremainder
hi def link spiceRCnode1 Label
hi def link spiceRCnode2 Label

syn match spiceRCremainder /.*\(\n\++\s*\)\?/ contained nextgroup=spiceRCremainder
" hi def link spiceRCremainder Special


" MOSFET (4-terminal)
" ===================
syn region spiceM start=/^\s*M\S\+/ end=/\(\n\++.*\)\@!$/ contains=spiceMname keepend extend

syn match spiceMname /^\s*M\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMnode1
hi def link spiceMname Identifier

syn match spiceMnode1 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMnode2
syn match spiceMnode2 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMnode3
syn match spiceMnode3 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMnode4
syn match spiceMnode4 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMmodel
hi def link spiceMnode1 Label
hi def link spiceMnode2 Label
hi def link spiceMnode3 Label
hi def link spiceMnode4 Label

syn match spiceMmodel /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceMremainder
hi def link spiceMmodel Type

syn match spiceMremainder /.*\(\n\++\s*\)\?/ contained nextgroup=spiceMremainder


" Measure
" =======
syn region spiceDotMeas start=/^\s*\.meas\(ure\)\?/ end=/\(\n\++.*\)\@!$/ contains=spiceDotMeasKw

syn match spiceDotMeasKw /^\s*\.meas\(ure\)\?\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasTypeKw
hi def link spiceDotMeasKw Keyword

syn match spiceDotMeasTypeKw /\(tran\)\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasName
hi def link spiceDotMeasTypeKw Keyword

syn match spiceDotMeasName /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasSectionKw,spiceDotMeasVI,spiceDotMeasOptName
hi def link spiceDotMeasName Identifier

syn match spiceDotMeasSectionKw /\(trig\|targ\|find\|when\)\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasVI,spiceDotMeasOptName
hi def link spiceDotMeasSectionKw Keyword

syn match spiceDotMeasOptName /\S\+\ze=\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasOptVal
hi def link spiceDotMeasOptName Label

syn match spiceDotMeasVI /[VI](\S\+)\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasSectionKw,spiceDotMeasVI,spiceDotMeasOptName
hi def link spiceDotMeasVI Function

syn match spiceDotMeasOptVal /=\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotMeasSectionKw,spiceDotMeasVI,spiceDotMeasOptName




" Subcircuit
" ==========
syn region spiceDotSubckt start=/^\s*\.subckt/ end=/\(\n\++.*\)\@!$/ contains=spiceDotSubcktKw

syn match spiceDotSubcktKw /^\s*\.subckt\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotSubcktName
hi def link spiceDotSubcktKw Keyword

syn match spiceDotSubcktName /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotSubcktNode
hi def link spiceDotSubcktName Identifier

syn match spiceDotSubcktNode /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotSubcktNode
hi def link spiceDotSubcktNode Label


syn region spiceDotEnds start=/^\s*\.ends/ end=/\(\n\++.*\)\@!$/ contains=spiceDotEndsKw

syn match spiceDotEndsKw /^\s*\.ends\s*\(\n\++\s*\)\?/ contained nextgroup=spiceDotEndsName
hi def link spiceDotEndsKw Keyword

syn match spiceDotEndsName /\S\+/ contained
hi def link spiceDotEndsName Identifier


syn region spiceX start=/^\s*X\S\+/ end=/\(\n\++.*\)\@!$/ contains=spiceXname keepend extend

syn match spiceXname /^\s*X\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceXnode
hi def link spiceXname Identifier

syn match spiceXnode /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceXnode,spiceXclass
hi def link spiceXnode Label

syn match spiceXclass /\S\+\ze\s*\(\S\+=\S\+\s*\)*\(\n\++\)\@!$/ contained
hi def link spiceXclass Type


" Voltage Source
" ==============
syn region spiceV start=/^\s*[VBG]\S\+/ end=/\(\n\++.*\)\@!$/ contains=spiceVname

syn match spiceVname /^\s*[VBG]\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceVnode1
hi def link spiceVname Identifier

syn match spiceVnode1 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceVnode2
syn match spiceVnode2 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceVremainder
hi def link spiceVnode1 Label
hi def link spiceVnode2 Label

syn match spiceVremainder /.*\(\n\++\s*\)\?/ contained nextgroup=spiceVremainder
" hi def link spiceVremainder Special


" Voltage Dependent Voltage Source
" ================================
syn region spiceE start=/^\s*E\S\+/ end=/\(\n\++.*\)\@!$/ contains=spiceEname

syn match spiceEname /^\s*E\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceEnode1
hi def link spiceEname Identifier

syn match spiceEnode1 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceEnode2
syn match spiceEnode2 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceEnode3
syn match spiceEnode3 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceEnode4
syn match spiceEnode4 /\S\+\s*\(\n\++\s*\)\?/ contained nextgroup=spiceEremainder
hi def link spiceEnode1 Label
hi def link spiceEnode2 Label
hi def link spiceEnode3 Label
hi def link spiceEnode4 Label

syn match spiceEremainder /.*\(\n\++\s*\)\?/ contained nextgroup=spiceEremainder
"hi def link spiceEremainder Special


" Misc Keywords
" =============
syn keyword spiceSourceKeywordsSimple DELAY VCR PWL PWLZ DC Z contained containedin=spiceVremainder,spiceEremainder
"hi def link spiceKeywordVsource Type
hi def link spiceSourceKeywordsSimple Keyword

syn match spiceSourceTd /\<TD\ze=\S\+\>/ contained containedin=spiceVremainder,spiceEremainder
hi def link spiceSourceTd Keyword

"syn keyword spiceMeasKeywordsSimple TRIG TARG PARAM
"hi def link spiceKeywordMeasure Type
"hi def link spiceMeasKeywordsSimple Keyword

syn match spiceMeasOpts /\<\(RISE\|FALL\|VAL\|PARAM\|TD\)\ze\s*\(=\|\s\)\s*\S\+/
hi def link spiceMeasOpts Label

syn keyword spiceMeasFlags TRAN TRIG TARG
hi def link spiceMeasFlags Keyword

syn match spiceTranOpts /\<\(POI\|SWEEP\)\ze\s*\(=\|\s\)\s*\S\+/
" Using Label because it's the name of the 'keyword argument' (as opposed to the value
" of it)
hi def link spiceTranOpts Label

syn match spiceCurlyParam /{\S\+}/ contained containedin=spiceMremainder,spiceRCremainder
hi def link spiceCurlyParam Special


syn match spiceVI /[VI](\S\+)/
"/\<\[VI\]\(\S+\)\>/
hi def link spiceVI Function


" Errors
"=======
"syn match spiceParenError ")"

" Syncs
" =====
syn sync minlines=50

" Define the default highlighting.
" Only when an item doesn't have highlighting yet

hi def link spiceTodo		Todo
hi def link spiceWrapLineOperator	spiceOperator
"hi def link spiceSinglequote	spiceExpr
hi def link spiceExpr		Function
"hi def link spiceParenError	Error
hi def link spiceStatement		Statement
hi def link spiceNumber		Number
hi def link spiceComment		Comment
hi def link spiceOperator		Operator


let b:current_syntax = "spice"

" insert the following to $VIM/syntax/scripts.vim
" to autodetect HSpice netlists and text listing output:
"
" " Spice netlists and text listings
" elseif getline(1) =~ 'spice\>' || getline("$") =~ '^\.end'
"   so <sfile>:p:h/spice.vim

" vim: ts=8
