*&---------------------------------------------------------------------*
*& Include          ZPRCTR_MULTILANG_FRA_FORM
*&---------------------------------------------------------------------*
FORM f_init.

  FREE: gt_import.

ENDFORM.

FORM f_local_path USING pv_path.

  DATA: lt_filebin  TYPE filetable,
        ls_filestr  TYPE file_table,
        lv_rc       TYPE i,
        lv_fullpath TYPE filename.

  FREE: lt_filebin.

  CLEAR: ls_filestr,
         lv_rc,
         lv_fullpath.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    CHANGING
      file_table = lt_filebin
      rc         = lv_rc.
  IF sy-subrc EQ 0.
    READ TABLE lt_filebin INTO ls_filestr INDEX 1.
    lv_fullpath = ls_filestr-filename.
  ENDIF.

  pv_path = lv_fullpath.

ENDFORM.

FORM f_upload_local.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = p_l_path
      filetype                = 'ASC'
      has_field_separator     = abap_true
      codepage                = '4110'
    TABLES
      data_tab                = gt_import
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.

FORM f_table.

  DATA: lv_prctr TYPE bapi0015id2-profit_ctr,
        lv_kokrs TYPE bapi0015id2-co_area,
        lv_datab TYPE bapi0015_3-date,
        lv_datbi TYPE bapi0015_3-date,
        ls_lang  TYPE bapi0015_10,
        ls_basic TYPE bapi0015_4.

  CLEAR: lv_prctr,
         lv_kokrs,
         lv_datab,
         lv_datbi,
         ls_lang,
         ls_basic.

  SORT gt_import BY kokrs prctr spras.

  LOOP AT gt_import ASSIGNING FIELD-SYMBOL(<fs_import>).

    lv_prctr = <fs_import>-prctr.
    lv_kokrs = <fs_import>-kokrs.
    lv_datab = <fs_import>-datab.
    lv_datbi = <fs_import>-datbi.
    ls_lang-langu = <fs_import>-spras.
    ls_basic-prctr_name = <fs_import>-ktext.
    ls_basic-long_text = <fs_import>-ltext.

    PERFORM f_bapi USING lv_prctr
                         lv_kokrs
                         lv_datab
                         lv_datbi
                         ls_lang
                         ls_basic.

    CLEAR: lv_prctr,
           lv_kokrs,
           lv_datab,
           lv_datbi,
           ls_lang,
           ls_basic.

  ENDLOOP.

ENDFORM.

FORM f_bapi USING pv_prctr TYPE bapi0015id2-profit_ctr
                  pv_kokrs TYPE bapi0015id2-co_area
                  pv_datab TYPE bapi0015_3-date
                  pv_datbi TYPE bapi0015_3-date
                  ps_lang  TYPE bapi0015_10
                  ps_basic TYPE bapi0015_4.

  DATA: ls_basicx   TYPE bapi0015_4x,
        ls_return   TYPE bapiret2,
        lt_preco    TYPE STANDARD TABLE OF bapiret2,
        ls_commit   TYPE bapiret2,
        ls_rollback TYPE bapiret2,
        lv_subrc_a  TYPE sy-subrc,
        lv_subrc_e  TYPE sy-subrc,
        lv_subrc_x  TYPE sy-subrc.

  CLEAR: ls_return,
         ls_commit,
         ls_rollback,
         lv_subrc_a,
         lv_subrc_e,
         lv_subrc_x.

  FREE: lt_preco.

  ls_basicx-prctr_name = abap_true.
  ls_basicx-long_text = abap_true.

  CALL FUNCTION 'BAPI_PS_INITIALIZATION'.

  CALL FUNCTION 'BAPI_PROFITCENTER_CHANGE'
    EXPORTING
      profitcenter    = pv_prctr
      controllingarea = pv_kokrs
      validfrom       = pv_datab
      validto         = pv_datbi
      basicdata       = ps_basic
      language        = ps_lang
      basicdatax      = ls_basicx
    IMPORTING
      return          = ls_return.

  IF ls_return-type EQ c_msg_a
  OR ls_return-type EQ c_msg_e
  OR ls_return-type EQ c_msg_x.

    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
      IMPORTING
        return = ls_rollback.

  ELSE.

    CALL FUNCTION 'BAPI_PS_PRECOMMIT'
      TABLES
        et_return = lt_preco.

    READ TABLE lt_preco
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_e
    BINARY SEARCH.
    lv_subrc_e = sy-subrc.
    READ TABLE lt_preco
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_x
    BINARY SEARCH.
    lv_subrc_x = sy-subrc.
    READ TABLE lt_preco
    TRANSPORTING NO FIELDS
    WITH KEY type = c_msg_a
    BINARY SEARCH.
    lv_subrc_a = sy-subrc.
    IF lv_subrc_e EQ 0
    OR lv_subrc_x EQ 0
    OR lv_subrc_a EQ 0.

      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
        IMPORTING
          return = ls_rollback.

    ELSE.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait   = abap_true
        IMPORTING
          return = ls_commit.
    ENDIF.
  ENDIF.

  APPEND ls_return TO gt_logs.
  APPEND LINES OF lt_preco TO gt_logs.

  CLEAR: ls_return,
         ls_commit,
         ls_rollback.

  FREE: lt_preco.

ENDFORM.

FORM f_download_logs.

  PERFORM f_heading.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = p_log
      filetype                = 'ASC'
      write_field_separator   = abap_true
    TABLES
      data_tab                = gt_logs
      fieldnames              = gt_heading
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  MESSAGE TEXT-002 TYPE c_msg_i.

ENDFORM.

FORM f_heading.

  DATA ls_heading TYPE ts_heading.

  ls_heading-text = TEXT-003. "type
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-004. "id
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-005. "number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-006. "message
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-007. "log number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-008. "log message number
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-009. "message v1
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-010. "message v2
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-011. "message v3
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-012. "message v4
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-013. "parameter
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-014. "row
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-015. "field
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

  ls_heading-text = TEXT-016. "system
  APPEND ls_heading TO gt_heading.
  CLEAR ls_heading.

ENDFORM.
