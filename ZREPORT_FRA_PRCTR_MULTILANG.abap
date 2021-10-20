*&---------------------------------------------------------------------*
*& Report ZREPORT_FRA_PRCTR_MULTILANG
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zreport_fra_prctr_multilang.

INCLUDE: zprctr_multilang_fra_data,
         zprctr_multilang_fra_sel,
         zprctr_multilang_fra_form.

INITIALIZATION.
  PERFORM f_init.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_l_path.
  PERFORM f_local_path USING p_l_path.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_log.
  PERFORM f_local_path USING p_log.

START-OF-SELECTION.
  PERFORM f_upload_local.
  PERFORM f_table.
  PERFORM f_download_logs.
