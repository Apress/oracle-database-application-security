-- Encryption
alter system set wallet_root='/etc/oracle/wallet/orclcdb' scope=spfile;
shutdown immediate
startup
ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=FILE" scope=BOTH;
create user c##sec_admin identified by SecretPassword;
grant syskm, connect to c##sec_admin;
conn c##sec_admin as syskm

sqlplus c##sec_admin as syskm
administer key management set key
using tag '23Dec2018'
identified by SecretPassword
with backup using 'bk1';

select * from v$encryption_wallet;

select tag,
 activation_time,
 creator,
 key_use,
 keystore_type,
 backed_up,
 activating_pdbname
from V$ENCRYPTION_KEYS;

select encryptionalg,
                   masterkey_activated,
                   masterkeyid,
                   con_id
from v$database_key_info

select encryptionalg,
                   masterkey_activated,
                   masterkeyid,
                   con_id
from v$database_key_info;

alter table t rekey;

alter table t rekey using 'aes256';

select file_name from sys.dba_data_files
where tablespace_name = 'ENC_DAT';

alter tablespace enc_dat
encryption rekey
file_name_convert=('/media/sf_work/oradat/enc_dat01_enc.dbf',
                   '/media/sf_work/oradat/enc_dat01_enc_201901.dbf');

administer key management
alter keystore password
identified by SecretPassword
set NewSecretPassword
with backup using 'bk1';
keystore altered.

create table people (id number primary key,
 fname varchar2(35) not null encrypt using 'aes256',
 lname varchar2(35) not null encrypt using 'aes256',
 country_code varchar2(4) not null,
 phone varchar2(12) not null encrypt using 'aes256',
 email varchar2(35) not null encrypt using 'aes256',
 addr1 varchar2(65) not null encrypt using 'aes256',
 addr2 varchar2(65) not null encrypt using 'aes256',
 city varchar2(65) not null encrypt using 'aes256',
 state varchar2(65) not null encrypt using 'aes256',
 zip varchar2(5) not null encrypt using 'aes256',
 zip_4 varchar2(4) not null encrypt using 'aes256');

create table t (id number primary key,
email varchar2(35) encrypt using 'aes256' salt);

create table t (id number primary key,
email varchar2(35) encrypt using 'aes256' no salt);

alter table hr.employees
modify ssn encrypt using 'aes256' no salt;

alter tablespace enc_dat encryption 
online encrypt
file_name_convert=('enc_dat01.dbf','enc_dat01_enc.dbf');

alter tablespace enc_idx encryption 
online encrypt
file_name_convert=('enc_idx01.dbf','enc_idx01_enc.dbf');

create table t (id number primary key,
object_name varchar2(128)) tablespace enc_dat;

insert into t (select t_seq.nextval,
object_name from sys.dba_objects);

create index t_idx on
t(object_name) tablespace idx;

alter table t move tablespace enc_dat;

strings idx01.dbf | grep DBA

alter index t_idx rebuild tablespace enc_idx;


create table t (id number primary key,
n1 number encrypt using 'aes256');

create sequence t_seq;

insert into t (
select t_seq.nextval,
sys.dbms_random.value(0,50000)
from dual
connect by level <= 1000000);

commit;

set timing on
select avg(n1) from t;


select tablespace_name, encrypted
from sys.dba_tablespaces
 where encrypted = 'YES';

create table t (id number primary key,
n1 number) tablespace enc_dat;


insert into t (
select t_seq.nextval,
sys.dbms_random.value(0,50000)
from dual
connect by level <= 1000000);

commit;

select avg(n1) from t;


alter table hr.employees add (ssn varchar2(11));

update hr.employees
 set ssn = ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9)) ||
 '-' ||
 ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9)) ||
 '-' ||
 ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9)) ||
 ceil(sys.dbms_random.value(0,9));

commit;

create table employees_ext
(employee_id,
 first_name,
 last_name,
 email encrypt using 'AES256' identified by SecretPassword,
 ssn encrypt using 'AES256' identified by SecretPassword)
 organization external
 (type oracle_datapump
 default directory "DATA_PUMP_DIR"
 location('employees_ext.dat')
 )
REJECT LIMIT UNLIMITED
as select employee_id,
 first_name,
 last_name,
 email,
 ssn
from hr.employees;

create table employees_ext
(employee_id,
first_name,
last_name,
email encrypt using 'AES256' identified by SecretPassword,
ssn encrypt)
organization external
(type oracle_datapump
default directory "DATA_PUMP_DIR"
 location('employees_ext.dat')
 )
 REJECT LIMIT UNLIMITED
 as select employee_id,
 first_name,
 last_name,
 email,
 ssn
 from hr.employees;

alter table hr.employees
move online tablespace enc_dat;

create table employees_unenc
(employee_id,
first_name,
last_name,
email,
ssn)
organization external
(type oracle_datapump
default directory "DATA_PUMP_DIR"
 location('employees_unenc.dat')
 )
 REJECT LIMIT UNLIMITED
 as select employee_id,
 first_name,
 last_name,
 email,
 ssn
 from hr.employees;

STARTUP MOUNT;
CREATE TEMPORARY TABLESPACE TEMP_ENC
TEMPFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/temp_enc_01.dbf'
SIZE 100M AUTOEXTEND ON
ENCRYPTION ENCRYPT;

ALTER DATABASE DEFAULT TEMPORARY TABLESPACE TEMP_ENC
DROP TABLESPACE TEMP;

ALTER DATABASE OPEN;

ALTER TABLESPACE SYSTEM ENCRYPTION ONLINE ENCRYPT 
FILE_NAME_CONVERT=('system01.dbf','system01_enc.dbf');
ALTER TABLESPACE SYSAUX ENCRYPTION ONLINE ENCRYPT
FILE_NAME_CONVERT=('sysaux01.dbf','sysaux01_enc.dbf');
ALTER TABLESPACE UNDOTBS1 ENCRYPTION ONLINE ENCRYPT
FILE_NAME_CONVERT=('undotbs01.dbf','undotbs01_enc.dbf')

create table t (id number primary key,
object_name varchar2(255)) tablespace dat;

insert into t (
select t_seq.nextval,
object_name
 from dba_objects);

commit;

create index t_idx on t(object_name)
 2* tablespace idx;

alter table t
 2 modify (object_name encrypt no salt);

CONFIGURE ENCRYPTION FOR DATABASE ON;
CONFIGURE ENCRYPTION ALGORITHM 'AES256'

select algorithm_name, is_default
from v$rman_encryption_algorithms;