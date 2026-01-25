
call plug#begin()
" プラグインの設定" call plug#begin() " ファイルを便利に開くためのプラグイン"
Plug 'scrooloose/nerdtree'
" ステータスバーを彩るプラグイン"
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()


" インサートモードの時にjを２回打つとノーマルモードになる"
inoremap <silent> jj <ESC>

"検索結果をハイライトする
set hlsearch

set number "行数を横に配置する
set laststatus=2 "ステータスバーを常に表示する

" タブの代わりに空白文字を挿入する
set expandtab
" タブ文字の表示幅
set tabstop=4
" Vimが挿入するインデントの幅
set shiftwidth=4
" 行頭の余白内で Tab を打ち込むと、'shiftwidth' の数だけインデントする
set smarttab
" 改行時に前の行のインデントを継続する
set autoindent
" 改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set smartindent

"----------------------------------------------------------
" keymapの説明
" 概要
" <mapキーワード> <置換前> <置換後>
"
" mapキーワードの種類
" noremap : ノーマルモードの際に使用するマップ
" inoremap: インサートモードの際に使用するマップ
"
" 種類
" :<CR>   -> Enter
" :<S>    -> Shift
" :<S-h>  -> Shift + h
" :<Esc>  -> エスケープを押す
" :<Left> -> カーソルを右に追加する
"----------------------------------------------------------


"----------------------------------------------------------
" shift + h or l で行初め、行終わりに移動する
"----------------------------------------------------------
noremap <S-h> 0
noremap <S-l> $


"----------------------------------------------------------
" 括弧の補完
"----------------------------------------------------------
inoremap { {}<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap < <><Left>
inoremap ' ''<Left>
inoremap " ""<Left>

inoremap {<CR> {<CR>}<Esc><S-o>
inoremap (<CR> (<CR>)<Esc><S-o>
inoremap [<CR> [<CR>]<Esc><S-o>
inoremap <<CR> <<CR>><Esc><S-o>

inoremap "" ""
inoremap '' ''
inoremap () ()
inoremap [] []
inoremap {} {}
inoremap <> <>

inoremap '<Esc> '<Esc>
inoremap "<Esc> "<Esc>
inoremap `<Esc> `<Esc>

