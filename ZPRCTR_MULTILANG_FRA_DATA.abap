*&---------------------------------------------------------------------*
*& Include          ZPRCTR_MULTILANG_FRA_DATA
*&---------------------------------------------------------------------*
TYPES:

  BEGIN OF ts_import,
    kokrs TYPE cepc-kokrs,
    prctr TYPE cepc-prctr,
    datab TYPE cepc-datab,
    datbi TYPE cepc-datbi,
    spras TYPE cepct-spras,
    ktext TYPE cepct-ktext,
    ltext TYPE cepct-ltext,
  END OF ts_import,

  BEGIN OF ts_heading,
    text TYPE char30,
  END OF ts_heading.

DATA: gt_heading TYPE STANDARD TABLE OF ts_heading,
      gt_logs    TYPE STANDARD TABLE OF bapiret2,
      gt_import  TYPE STANDARD TABLE OF ts_import.

CONSTANTS: c_msg_e TYPE c VALUE 'E',
           c_msg_i TYPE c VALUE 'I',
           c_msg_x TYPE c VALUE 'X',
           c_msg_a TYPE c VALUE 'A'.
