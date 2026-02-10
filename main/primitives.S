# collection of primitive WORDS
# primitive words give core functionlity to skforth. They are stored in Flash memory and not editable
#
# WORD structure:
#
# WORD total byte size -> max 32 bytes
#
# offset 0   : link prev word (  4     )
# offset 4   : is_immediate   (  1     )
# offset 5   : name_len       (  1     )
# offset 6-7 : padding
# offset 8   : code addr      (  4     )
# offset 12  : name ascii     ( 20 max )

    .section .text
    .extern WORD_LEN
    .extern dictionary
    .extern here_dic
    .extern latest_word

init_prim_words: 
    
    ret


code_dup:
    
