-- 01 AND 02 TRIGGER PROCEDURES
CREATE OR REPLACE PROCEDURE PRC_CREATE_TRG01_TRIGGERS
(TABLE_NAME_IN VARCHAR2)
AS
V_SQL VARCHAR2(2000);
BEGIN
V_SQL := 'CREATE OR REPLACE TRIGGER trg01_' || TABLE_NAME_IN || ' BEFORE ';
V_SQL := V_SQL || ' INSERT OR UPDATE ON ' || TABLE_NAME_IN;
V_SQL := V_SQL || ' FOR EACH ROW ';
V_SQL := V_SQL || ' BEGIN';
V_SQL := V_SQL || ' IF inserting THEN ';
V_SQL := V_SQL || ' :new.' || TABLE_NAME_IN || '_crtd_id := user;';
V_SQL := V_SQL || ' :new.' || TABLE_NAME_IN || '_crtd_dt := sysdate;';
V_SQL := V_SQL || ' END IF;';
V_SQL := V_SQL || ' :new.' || TABLE_NAME_IN || '_updt_id := user;';
V_SQL := V_SQL || ' :new.' || TABLE_NAME_IN || '_updt_dt := sysdate;';
V_SQL := V_SQL || ' END;';
EXECUTE IMMEDIATE V_SQL;
END;
/
CREATE OR REPLACE PROCEDURE PRC_CREATE_TRG02_TRIGGERS
(TABLE_NAME_IN VARCHAR2,
COLUMN_NAME_IN VARCHAR2)
AS
V_SQL VARCHAR2(2000);
BEGIN
V_SQL := 'CREATE OR REPLACE TRIGGER trg02_' || TABLE_NAME_IN || ' BEFORE ';
V_SQL := V_SQL || ' INSERT OR UPDATE ON ' || TABLE_NAME_IN;
V_SQL := V_SQL || ' FOR EACH ROW ';
V_SQL := V_SQL || ' BEGIN';
V_SQL := V_SQL || ' IF inserting THEN ';
V_SQL := V_SQL || ' IF :NEW.' || COLUMN_NAME_IN || ' IS NULL THEN ';
V_SQL := V_SQL || ' :NEW.' || COLUMN_NAME_IN || ' := SYS_GUID();';
V_SQL := V_SQL || ' END IF;';
V_SQL := V_SQL || ' END IF;';
V_SQL := V_SQL || ' IF UPDATING THEN';
V_SQL := V_SQL || ' :NEW.' || COLUMN_NAME_IN || ' := :OLD.' ||
COLUMN_NAME_IN || ';';
V_SQL := V_SQL || ' END IF;';
V_SQL := V_SQL || ' END;';
EXECUTE IMMEDIATE V_SQL;
END;
/
create or replace PROCEDURE prc_create_triggers as
CURSOR C_TABLES IS
SELECT * FROM USER_TABLES;
FUNCTION GET_PK(TABLE_NAME_IN VARCHAR2)
RETURN VARCHAR2
AS
V_KEY_COL VARCHAR2(200);
BEGIN
SELECT UCC.COLUMN_NAME
INTO V_KEY_COL
FROM SYS.user_constraints UC
INNER JOIN user_cons_columns UCC
ON UC.OWNER = UCC.OWNER
AND UC.CONSTRAINT_NAME = UCC.CONSTRAINT_NAME
WHERE CONSTRAINT_TYPE = 'P'
AND UC.TABLE_NAME = TABLE_NAME_IN;
RETURN V_KEY_COL;
END;
BEGIN
FOR R_TABLE IN C_TABLES
LOOP
PRC_CREATE_TRG01_TRIGGERS(R_TABLE.TABLE_NAME);
PRC_CREATE_TRG02_TRIGGERS(R_TABLE.TABLE_NAME, GET_PK(R_TABLE.TABLE_NAME));
END LOOP;
END;
/


create or replace procedure TRANSFORM_LOOKUP
(source_table_name_in varchar2,
 source_column_name_in varchar2,
 target_table_name_in varchar2,
 target_column_name_in varchar2,
 TARGET_DATA_TYPE_IN VARCHAR2)
 as
    V_SQL VARCHAR2(2000);
    new_fk_column_name VARCHAR2(2000);
 begin

    -- CREATE NEW TABLE
    V_SQL := 'CREATE TABLE ' || target_table_name_in;
    V_SQL := V_SQL || '( ';
    V_SQL := V_SQL || target_table_name_in || '_ID VARCHAR2(38)';
    V_SQL := V_SQL || ', ' || target_column_name_in || ' ' || TARGET_DATA_TYPE_IN || ' NOT NULL ';
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_ID VARCHAR2(40) NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_DT DATE NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_ID VARCHAR2(40) NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_DT DATE NOT NULL ' ;
    
    V_SQL := V_SQL || ', CONSTRAINT ' || target_table_name_in || '_PK PRIMARY KEY ';
    V_SQL := V_SQL || '(' || target_table_name_in || '_ID) ENABLE ) ';
    
    EXECUTE IMMEDIATE V_SQL;
    
    -- CREATE 02 TRIGGERS IN NEW TABLE
    PRC_CREATE_TRG02_TRIGGERS(target_table_name_in, target_table_name_in || '_ID');
    
    -- INSERT ROWS INTO NEW TABLE
    V_SQL := 'INSERT INTO ' || target_table_name_in;
    V_SQL := V_SQL || '(';
    V_SQL := V_SQL || target_column_name_in;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_ID';
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_DT';
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_ID';
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_DT';
    V_SQL := V_SQL || ')';
    V_SQL := V_SQL || 'SELECT DISTINCT ';
    V_SQL := V_SQL || source_column_name_in;
    V_SQL := V_SQL || ', ''SYSTEM''';
    V_SQL := V_SQL || ', TO_DATE(''01-JAN-25'',''DD-MON-YY'')';
    V_SQL := V_SQL || ', ''SYSTEM''';
    V_SQL := V_SQL || ', TO_DATE(''01-JAN-25'',''DD-MON-YY'')';
    V_SQL := V_SQL || ' FROM ';
    V_SQL := V_SQL || source_table_name_in;
    V_SQL := V_SQL || ' WHERE ';
    V_SQL := V_SQL || source_column_name_in || ' IS NOT NULL';
    
    
    EXECUTE IMMEDIATE V_SQL;
    
    -- SAVE NAME OF NEW FK COLUMN GOING INTO ORIGINAL TABLE (source_table_name_in)
    new_fk_column_name := source_table_name_in || '_' || target_table_name_in || '_ID';
    
    -- ADD new_fk_column_name TO ORIGINAL TABLE
    V_SQL := 'ALTER TABLE ' || source_table_name_in;
    V_SQL := V_SQL || ' ADD (' || new_fk_column_name || ' VARCHAR2(38))';
    
    EXECUTE IMMEDIATE V_SQL;
    
    
    -- UPDATE NEW FK COLUMN IN ORIGINAL TABLE TO NEW TABLE PK VALUES
    V_SQL := 'UPDATE ' || source_table_name_in || ' s SET s.' || new_fk_column_name || ' = ( ';
    V_SQL := V_SQL || ' SELECT t.' || target_table_name_in || '_ID';
    V_SQL := V_SQL || ' FROM ' || target_table_name_in || ' t';
    V_SQL := V_SQL || ' WHERE t.' || target_column_name_in || ' = s.' || source_column_name_in;
    V_SQL := V_SQL || ' )';
    V_SQL := V_SQL || ' WHERE s.' || source_column_name_in || ' IS NOT NULL';
    V_SQL := V_SQL || ' AND EXISTS (';
    V_SQL := V_SQL || ' SELECT 1 FROM ' || target_table_name_in || ' t_exists';
    V_SQL := V_SQL || ' WHERE t_exists.' || target_column_name_in || ' = s.' || source_column_name_in;
    V_SQL := V_SQL || ' )';
    
    EXECUTE IMMEDIATE V_SQL;
        
    -- DROP ORIGINAL TABLE'S ORIGINAL COLUMN (source_column_name_in)
    V_SQL := 'ALTER TABLE ' || source_table_name_in;
    V_SQL := V_SQL || ' DROP COLUMN ' || source_column_name_in;
    
    EXECUTE IMMEDIATE V_SQL;
    
    -- ADD FOREIGN KEY CONSTRAINT TO ORIGINAL TABLE 
    V_SQL := 'ALTER TABLE ' || source_table_name_in;
    V_SQL := V_SQL || ' ADD CONSTRAINT ' || source_table_name_in || '_' || target_table_name_in || '_FK FOREIGN KEY';
    V_SQL := V_SQL || '(';
    V_SQL := V_SQL || new_fk_column_name;
    V_SQL := V_SQL || ')';
    V_SQL := V_SQL || ' REFERENCES ' || target_table_name_in;
    V_SQL := V_SQL || '(';
    V_SQL := V_SQL || target_table_name_in || '_ID';
    V_SQL := V_SQL || ')';
    V_SQL := V_SQL || ' ENABLE';

    EXECUTE IMMEDIATE V_SQL;
    
    -- CREATE 01 TRIGGERS IN NEW TABLE
    PRC_CREATE_TRG01_TRIGGERS(target_table_name_in);
    
 end;
/

CREATE OR REPLACE TYPE string_list_t AS TABLE OF VARCHAR2(128);
/

create or replace procedure TRANSFORM_CHILD
(source_table_name_in varchar2,
 source_column_names_in string_list_t,
 target_table_name_in varchar2,
 target_column_name_in varchar2,
 TARGET_DATA_TYPE_IN VARCHAR2)
 as
    V_SQL VARCHAR2(2000);
    new_fk_column_name VARCHAR2(2000);
    current_source_col VARCHAR2(2000);
 begin

    new_fk_column_name := target_table_name_in || '_' || source_table_name_in || '_ID';
    
    -- CREATE NEW TABLE
    V_SQL := 'CREATE TABLE ' || target_table_name_in;
    V_SQL := V_SQL || '( ';
    V_SQL := V_SQL || target_table_name_in || '_ID VARCHAR2(38)';
    V_SQL := V_SQL || ', ' || target_column_name_in || ' ' || TARGET_DATA_TYPE_IN || ' NOT NULL ';
    V_SQL := V_SQL || ', ' || new_fk_column_name || ' VARCHAR2(38) NOT NULL ';
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_ID VARCHAR2(40) NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_DT DATE NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_ID VARCHAR2(40) NOT NULL ' ;
    V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_DT DATE NOT NULL ' ;
    
    V_SQL := V_SQL || ', CONSTRAINT ' || target_table_name_in || '_PK PRIMARY KEY ';
    V_SQL := V_SQL || '(' || target_table_name_in || '_ID) ENABLE ) ';
        dbms_output.put_line(v_sql);
    EXECUTE IMMEDIATE V_SQL;
    
    -- CREATE 02 TRIGGERS IN NEW TABLE
    PRC_CREATE_TRG02_TRIGGERS(target_table_name_in, target_table_name_in || '_ID');
    
    FOR i IN 1 .. source_column_names_in.COUNT LOOP
        current_source_col := source_column_names_in(i);
    
        -- INSERT ROWS INTO NEW TABLE
        V_SQL := 'INSERT INTO ' || target_table_name_in;
        V_SQL := V_SQL || '(';
        V_SQL := V_SQL || target_column_name_in;
        V_SQL := V_SQL || ', ' || new_fk_column_name;
        V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_ID';
        V_SQL := V_SQL || ', ' || target_table_name_in || '_CRTD_DT';
        V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_ID';
        V_SQL := V_SQL || ', ' || target_table_name_in || '_UPDT_DT';
        V_SQL := V_SQL || ')';
        V_SQL := V_SQL || 'SELECT ';
        V_SQL := V_SQL || current_source_col;
        V_SQL := V_SQL || ', ' || source_table_name_in || '_ID';
        V_SQL := V_SQL || ', ''SYSTEM''';
        V_SQL := V_SQL || ', TO_DATE(''01-JAN-25'',''DD-MON-YY'')';
        V_SQL := V_SQL || ', ''SYSTEM''';
        V_SQL := V_SQL || ', TO_DATE(''01-JAN-25'',''DD-MON-YY'')';
        V_SQL := V_SQL || ' FROM ';
        V_SQL := V_SQL || source_table_name_in;
        V_SQL := V_SQL || ' WHERE ';
        V_SQL := V_SQL || current_source_col || ' IS NOT NULL';
        
            dbms_output.put_line(v_sql);
        EXECUTE IMMEDIATE V_SQL;
        
        -- DROP ORIGINAL TABLE'S ORIGINAL COLUMN (current_source_col)
        V_SQL := 'ALTER TABLE ' || source_table_name_in;
        V_SQL := V_SQL || ' DROP COLUMN ' || current_source_col;
        
            dbms_output.put_line(v_sql);
        EXECUTE IMMEDIATE V_SQL;
    END LOOP;
    
    
    -- ADD FOREIGN KEY CONSTRAINT TO NEW TABLE 
    V_SQL := 'ALTER TABLE ' || target_table_name_in;
    V_SQL := V_SQL || ' ADD CONSTRAINT ' || target_table_name_in || '_' || source_table_name_in || '_FK FOREIGN KEY';
    V_SQL := V_SQL || '(';
    V_SQL := V_SQL || new_fk_column_name;
    V_SQL := V_SQL || ')';
    V_SQL := V_SQL || ' REFERENCES ' || source_table_name_in;
    V_SQL := V_SQL || '(';
    V_SQL := V_SQL || source_table_name_in || '_ID';
    V_SQL := V_SQL || ')';
    V_SQL := V_SQL || ' ENABLE';

    dbms_output.put_line(v_sql);
    EXECUTE IMMEDIATE V_SQL;
    
    -- CREATE 01 TRIGGERS IN NEW TABLE
    PRC_CREATE_TRG01_TRIGGERS(target_table_name_in);
    
 end;
/

BEGIN
    TRANSFORM_LOOKUP('AWARD', 'PROPOSAL_NO', 'PROPOSAL', 'PROPOSAL_NO', 'VARCHAR2(30 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'STATUS', 'STATUS', 'STATUS_VALUE', 'CHAR(1 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'BAA', 'BAA', 'BAA_VALUE', 'VARCHAR2(50 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'TOPIC', 'TOPIC', 'TOPIC_VALUE', 'VARCHAR2(60 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'COLOROFMONEY', 'MONEY', 'COLOR', 'VARCHAR2(3 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'PROGRAMELEMENT', 'PROGRAM', 'ELEMENT', 'VARCHAR2(25 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'ONR', 'ONR', 'ONR_VALUE', 'VARCHAR2(12 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'DFAS', 'DFAS', 'DFAS_VALUE', 'VARCHAR2(12 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'DUNS', 'DUNS', 'DUNS_VALUE', 'VARCHAR2(12 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'CAGE', 'CAGE', 'CAGE_VALUE', 'VARCHAR2(12 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'INSTITUTION', 'INSTITUTION', 'INSTITUTION_NAME', 'VARCHAR2(255 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'CAPABILITYCOMPONENT', 'CAPABILITY', 'CAPABILITYCOMPONENT', 'VARCHAR2(255 BYTE)');
    TRANSFORM_LOOKUP('AWARD', 'FUNDINGENTITY', 'FUNDING', 'ENTITY', 'CHAR(3 BYTE)');
END;
/

DECLARE
    l_alias_columns string_list_t;
    l_opt1_columns string_list_t;
    l_opt2_columns string_list_t;
    l_patron_columns string_list_t;
    l_cofund_directs string_list_t;
    l_dod_columns string_list_t;
    
BEGIN
    l_alias_columns := string_list_t('ALIAS1', 'ALIAS2', 'ALIAS3', 'ALIAS4');
    TRANSFORM_CHILD('AWARD', l_alias_columns, 'ALIAS', 'ALIAS_NAME', 'VARCHAR2(20 BYTE)');
    
    l_opt1_columns := string_list_t('OPT1START', 'OPT1END');
    TRANSFORM_CHILD('AWARD', l_opt1_columns, 'OPT1', 'OPT1_DATE', 'DATE');
    
    l_opt2_columns := string_list_t('OPT2START', 'OPT2END');
    TRANSFORM_CHILD('AWARD', l_opt2_columns, 'OPT2', 'OPT2_DATE', 'DATE');
    
    l_patron_columns := string_list_t('PATRONTWO', 'PATRONTHREE');
    TRANSFORM_CHILD('AWARD', l_patron_columns, 'PATRONS', 'PATRON', 'VARCHAR2(4 BYTE)');
    
    l_cofund_directs := string_list_t('COFUNDDIRECTORATE1', 'COFUNDDIRECTORATE2');
    TRANSFORM_CHILD('AWARD', l_cofund_directs, 'COFUNDDIRECTORATES', 'COFUNDDIRECTORATE', 'VARCHAR2(4 BYTE)');
    
    l_dod_columns := string_list_t('DODPRIORITY1', 'DODPRIORITY2', 'DODPRIORITY3');
    TRANSFORM_CHILD('AWARD', l_dod_columns, 'DOD_VALUES', 'DOD_VALUE', 'VARCHAR2(100 BYTE)');
    
END;
/

commit;


-- Disable triggers before the update
ALTER TRIGGER TRG01_INSTITUTION DISABLE;
ALTER TRIGGER TRG02_INSTITUTION DISABLE;

-- Add the new columns to the INSTITUTION table
ALTER TABLE INSTITUTION
ADD TAXID VARCHAR2(20 BYTE);

ALTER TABLE INSTITUTION
ADD CITY VARCHAR2(50 BYTE);

ALTER TABLE INSTITUTION
ADD STATE VARCHAR2(5 BYTE);

ALTER TABLE INSTITUTION
ADD THRUSTAREA BOOLEAN;

ALTER TABLE INSTITUTION
ADD ENTERPRISE CHAR(2 BYTE);

ALTER TABLE INSTITUTION
ADD TAXONOMY VARCHAR2(200 BYTE);

-- Update the INSTITUTION table with data from the Award table.
UPDATE INSTITUTION i
SET TAXID = (SELECT a.TAXID FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID),
    CITY = (SELECT a.CITY FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID),
    STATE = (SELECT a.STATE FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID),
    THRUSTAREA = (SELECT a.THRUSTAREA FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID),
    ENTERPRISE = (SELECT a.ENTERPRISE FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID),
    TAXONOMY = (SELECT a.TAXONOMY FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID)
WHERE EXISTS (SELECT 1 FROM Award a WHERE a.AWARD_INSTITUTION_ID = i.INSTITUTION_ID);

-- Drop the columns from the AWARD table
ALTER TABLE AWARD
DROP COLUMN TAXID;

ALTER TABLE AWARD
DROP COLUMN CITY;

ALTER TABLE AWARD
DROP COLUMN STATE;

ALTER TABLE AWARD
DROP COLUMN THRUSTAREA;

ALTER TABLE AWARD
DROP COLUMN ENTERPRISE;

ALTER TABLE AWARD
DROP COLUMN TAXONOMY;

-- Enable triggers after the update
ALTER TRIGGER TRG01_INSTITUTION ENABLE;
ALTER TRIGGER TRG02_INSTITUTION ENABLE;


commit;


CREATE TABLE ENTITY (
    ENTITY_ID VARCHAR2(38 BYTE) PRIMARY KEY,
    
    ENTITY_AWARD_ID VARCHAR2(38 BYTE) NOT NULL,
    ENTITY_PATRONS_ID VARCHAR2(38 BYTE) NOT NULL,
    ENTITY_COFUNDDIRECTORATES_ID VARCHAR2(38 BYTE) NOT NULL,
    ENTITY_COFUNDED CHAR(3 BYTE) NOT NULL,
    ENTITY_CRTD_ID VARCHAR2(40 BYTE) NOT NULL,
    ENTITY_CRTD_DT DATE NOT NULL,
    ENTITY_UPDT_ID VARCHAR2(40 BYTE) NOT NULL,
    ENTITY_UPDT_DT DATE NOT NULL,

    CONSTRAINT FK_AWARD FOREIGN KEY (ENTITY_AWARD_ID)
        REFERENCES AWARD (AWARD_ID),

    CONSTRAINT FK_PATRONS FOREIGN KEY (ENTITY_PATRONS_ID)
        REFERENCES PATRONS (PATRONS_ID),

    CONSTRAINT FK_COFUND FOREIGN KEY (ENTITY_COFUNDDIRECTORATES_ID)
        REFERENCES COFUNDDIRECTORATES (COFUNDDIRECTORATES_ID)
);
begin
PRC_CREATE_TRG02_TRIGGERS('entity', 'entity_id');
end;
/
INSERT INTO ENTITY (
    ENTITY_AWARD_ID,
    ENTITY_PATRONS_ID,
    ENTITY_COFUNDDIRECTORATES_ID,
    ENTITY_COFUNDED,
    ENTITY_CRTD_ID, ENTITY_CRTD_DT, ENTITY_UPDT_ID, ENTITY_UPDT_DT
)
SELECT
    P.PATRONS_AWARD_ID,
    P.PATRONS_ID,
    C.COFUNDDIRECTORATES_ID,
    A.COFUNDED,
    'SYSTEM',
    TO_DATE('01-JAN-25', 'DD-MON-YY'),
    'SYSTEM',
    TO_DATE('01-JAN-25', 'DD-MON-YY')
FROM
    PATRONS P
JOIN
    COFUNDDIRECTORATES C ON P.PATRONS_AWARD_ID = C.COFUNDDIRECTORATES_AWARD_ID
JOIN
    AWARD A ON P.PATRONS_AWARD_ID = A.AWARD_ID;

begin
PRC_CREATE_TRG01_TRIGGERS('entity');
end;
/

ALTER TABLE AWARD
DROP COLUMN COFUNDED;


commit;


BEGIN
    TRANSFORM_LOOKUP('AWARD', 'FK_TERMS_CONDITIONS', 'TERMS_CONDITIONS', 'TERMS_CONDITIONS_OLD_PK', 'NUMBER');
END;
/
ALTER TABLE TERMS_CONDITIONS
DROP COLUMN TERMS_CONDITIONS_OLD_PK;

ALTER TABLE AWARD
DROP COLUMN FK_BAA;

ALTER TABLE AWARD
DROP COLUMN PK_AWARD;
BEGIN
    PRC_CREATE_TRIGGERS();
END;
/

commit;