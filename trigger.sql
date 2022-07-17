CREATE OR REPLACE TRIGGER before_ddl 
AFTER ALTER ON SAPSR3.schema DECLARE n_JOB NUMBER;
-- job id 
c_TEXT VARCHAR2 (1000);
-- text of sql clause 
sql_TEXT ORA_NAME_LIST_T;
-- sql text list 
i PLS_INTEGER;
-- sql text list index 
v_CUBE VARCHAR2 (100) := 'X_CUBE';
-- name of the cube 
BEGIN -- set nls parameters to process text data 
EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LENGTH_SEMANTICS = ''BYTE''';
-- get the text of DDL-sql clause 
i := ora_sql_txt (sql_TEXT);
FOR l IN 1..i LOOP c_TEXT := c_TEXT || sql_TEXT (l);
END LOOP;
-- delete the end of file character 
c_TEXT := SUBSTR (
  c_TEXT, 
  1, 
  LENGTH (c_TEXT) - 1
);
IF (
  (
    SYS.DBMS_STANDARD.DICTIONARY_OBJ_OWNER = 'SAPSR3'
  ) 
  AND (
    SYS.DBMS_STANDARD.DICTIONARY_OBJ_TYPE = 'TABLE'
  ) 
  AND (
    SYS.DBMS_STANDARD.DICTIONARY_OBJ_NAME = '/BIC/F' || v_CUBE
  ) 
  AND UPPER (c_TEXT) LIKE '%PARTITION% %REBUILD%'
) THEN -- set the full specification of fact table name in sql text clause 
c_TEXT := REPLACE (
  c_TEXT, '"/BIC/F' || v_CUBE || '"', 'SAPSR3."/BIC/F' || v_CUBE || '" '
);
-- remove the "REBUILD" keyword 
c_TEXT := REPLACE (c_TEXT, 'REBUILD');
-- run the DDL-statement in a database job 
-- after 1 seconds to set the local indexes unusable 
SYS.DBMS_JOB.submit (
  job => n_JOB, 
  next_date => SYSDATE + 1 / (24 * 60 * 60), 
  what => 'BEGIN EXECUTE IMMEDIATE ''' || c_TEXT || '''; END;'
);
END IF;
END;
