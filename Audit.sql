  sys.dbms_audit_mgmt.set_audit_trail_property(
    audit_trail_type           => dbms_audit_mgmt.audit_trail_unified,
    audit_trail_property       => dbms_audit_mgmt.audit_trail_write_mode,
    audit_trail_property_value => dbms_audit_mgmt.audit_trail_immediate_write
  );
end;
/

create audit policy tool_connect_pol
actions logon
when ‘instr(upper(sys_context,(‘’userenv’’, ‘’CLIENT_PROGRAM_NAME’’)),’’<APP_NAME>’’) = 0’
evaluate per session;

-- enable the audit policy
audit policy tool_connect_pol;

create audit policy hr_upd_del_employees_pol
actions update on hr.employees, delete on hr.employees
when 'instr(sys_context (''userenv'', ''authentication_method''),''SSL'') = 0' 
evaluate per session;
-- enable the audit policy
audit policy hr_upd_del_employees_pol;

begin
  sys.dbms_fga.add_policy(
     object_schema      => 'hr',
     object_name        => 'employees',
     policy_name        => 'upper_salary_check',
     audit_condition    => 'salary > 150000',
     audit_column       => 'salary',
     handler_schema     => NULL,
     handler_module     => NULL,
     enable             => TRUE,
     statement_types    => 'SELECT',
     audit_column_opts  => SYS.DBMS_FGA.ANY_COLUMNS
     );
end;
/
/*This is redundant, when we created the policy, we enabled it with the enable parameter. So you don’t need to use sys.dbms_fga.enable_policy procedure unless you have disabled it. */
begin
  sys.dbms_fga.enable_policy(
    object_schema   => 'hr',
    object_name     => 'employees',
    policy_name     => 'upper_salary_check',
    enable          => TRUE
  );
end;
/
/* Let’s query the table and check the audit trail to see if it works. This will return all the rows, so we know it will trigger an audit event.*/
select * hr.employees;

/* check the audit trail for the audit. Note, if you look above, you’ll see that the policy name is lower case; however, we query for a policy name in upper case. */
select * from unified_audit_trail
where fga_policy_name = 'UPPER_SALARY_CHECK';

select * from unified_audit_trail
where utl.timestamp_to_date(event_timestamp) >= trunc(sysdate-1);


create audit policy aud_logon_pol
actions logon;
-- enable the logon policy
audit policy aud_logon_pol;

select os_username, dbusername, terminal, userhost, action_name, return_code, count(*)
from unified_audit_trail
where utl.timestamp_to_date(event_timestamp) > trunc(sysdate-1)
  and action_name = 'LOGON'
  and return_code = 0
group by os_username, dbusername, terminal, userhost, action_name, return_code
order by dbusername, os_username
/

create or replace package utl as
function timestamp_to_date(ts_value timestamp) return date;
end utl;

create or replace package body utl as
function timestamp_to_date(ts_value timestamp) return date is
begin
  return to_date(to_char(ts_value,'MONDDRRRR'),'MONDDRRRR');
end timestamp_to_date;
end utl;

select os_username, dbusername, terminal, userhost, count(*)
from unified_audit_trail
where utl.timestamp_to_date(event_timestamp) > trunc(sysdate-1)
  and action_name = 'LOGON'
  and return_code != 0
group by os_username, dbusername, terminal, userhost
/

select * from unified_audit_trail
where utl.timestamp_to_date(event_timestamp) >= trunc(sysdate-1)
  and unified_audit_policies = 'ORA_LOGON_FAILURES';

select current_user, os_username, dbusername, count(*) from unified_audit_trail
where unified_audit_policies = 'ORA_LOGON_FAILURES'
and trunc(event_timestamp) >= trunc(sysdate-1)
group by current_user, os_username, dbusername;

DECLARE
    -- get the list of users with default passwords.
    CURSOR users_with_defpwd_cur IS
        SELECT username
        FROM sys.dba_users_with_defpwd;
    stmt     VARCHAR2(2000);    -- the base sql statement
    passwd   VARCHAR2(32);      -- the impossible_password.

    FUNCTION impossible_password RETURN VARCHAR2 AS
    -- will create a 30 character password wrapped in double quotes.
    passwd           VARCHAR2(32);        -- this is the password we are returning.
                                          -- we need 32 characters because we are
                                          -- wrapping the password in double quotes.
    p_invalid_char_3 VARCHAR2(1) := '"';  -- invalid password character 3 is '"'
    p_invalid_char_4 VARCHAR2(1) := ';';  -- invalid password character 4 is ';'
    BEGIN 
        passwd := SYS.dbms_random.STRING('p',30); -- get 30 printable characters. 
        -- find all the invalid characters and replace them with a random integer
        -- between 0 and 9.
        passwd := REPLACE(passwd, p_invalid_char_3, ceil(SYS.dbms_random.VALUE(-1,9)));
        passwd := REPLACE(passwd, p_invalid_char_4, ceil(SYS.dbms_random.VALUE(-1,9)));
        -- before we pass back the password, we need to put a double quote 
        -- on either side of it. This is because sometimes we are going to 
        -- get a strange character that will cause oracle to cough up a hairball.
        passwd := '"' || passwd || '"';
        RETURN passwd;
    END;
-- main procedure.
BEGIN
    FOR users_with_defpwd_rec IN users_with_defpwd_cur LOOP
        passwd := impossible_password;
        stmt := 'alter user ' || users_with_defpwd_rec.username || ' identified by ' || passwd;
        EXECUTE IMMEDIATE stmt;
    END LOOP;
EXCEPTION WHEN OTHERS THEN
    sys.dbms_output.put_line(sqlerrm);
    sys.dbms_output.put_line(stmt);
END;
/

select dbusername,
        os_username,
        role,
        object_privileges,
        system_privilege_used,
        object_schema,
        object_name
from unified_audit_trail
where event_timestamp >= trunc(sysdate-1);

select os_username, dbusername, userhost, terminal, client_program_name, action_name, sql_text
from unified_audit_trail
where lower(client_program_name) != 'forms.exe'
  and utl.timestamp_to_date(event_timestamp) > trunc(sysdate-1);

create table security_dat.table_access (
    owner varchar2(128) not null,
    table_name varchar2(128) not null,
    ip_address varchar2(15) not null,
    created_by varchar2(128) not null,
    last_update_date date not null
);

insert into security_dat.table_access values (
'HR', 'EMPLOYEES', '127.0.0.1', 'RLOCKARD', SYSDATE);
commit;

-- create the role and grant the necessary privileges.
create role sec_table_access_role;
grant select on security_dat.table_access to security_api;
grant select on security_dat.table_access to sec_table_access_role;
grant sec_table_access_role to security_api with delegate option;
grant select on security_dat.table_access to security_api;

create or replace editionable package security_api.pkg_table_access_check 
authid current_user
as
  function f_check_access(p_owner      varchar2,
                          p_table_name varchar2) return boolean;
end pkg_table_access_check;
/

-- connect to the security_api schema only through the proxy user rlockard. Again, setting up a proxy user and schema only account will be covered in detail in the secure coding chapter.
conn rlockard[security_api]@orclpdb1

-- now we are going to grant sec_table_access_role to the package pkg_table_access_check.
grant sec_table_access_role to package pkg_table_access_check;

create or replace package body security_api.pkg_table_access_check as
  function f_check_access(p_owner      varchar2,
                            p_table_name varchar2) return boolean is
  x integer; -- just a dumb variable to get the count
  begin
    -- if the ip address is not authorized then return false. 
    -- else return true.
    select count(*)
    into x
    from security_dat.table_access
    where owner      = p_owner
      and table_name = p_table_name
      and ip_address = sys_context('userenv', 'IP_ADDRESS');
    if x > 0 then
      return true;
    else
      return false;
    end if;
  -- if something goes wrong, by default we want to return false. This will 
  -- trigger an audit record.
  exception when others then
    return false;
  end f_check_access;
end pkg_table_access_check;
/

-- the security admin user will be executing the package.
grant execute on security_api.pkg_table_access_check to sec_admin;

create audit policy aud_hr_emp_access_pol
actions select on hr.employees, 
              update on hr.employees, 
              insert on hr.employees, 
              delete on hr.employees
when not 'security_api.table_access_check(' || '''' || 'hr' || '''' 
                                           || ',' || '''' 
                                           ||  'employees' || '''' 
                                           || ')'
evaluate per access;
-- Enable the policy.
audit policy aud_hr_emp_access_pol;

select action_name 
from sys.audit_actions;

find $ORACLE_HOME/lib/ | xargs sha256sum > lib_keep_file.txt
find $ORACLE_HOME/bin/ | xargs sha256sum > bin_keep_file.txt
find $ORACLE_HOME/dbs/ | xargs sha256sum > dbs_keep_file.txt
find $ORACLE_HOME/rdbms/admin/ | xargs sha256sum > rdbms_admin_keep_file.txt
find $ORACLE_HOME -name "*.ora" | xargs sha256sum > config_keep_file.txt

find $ORACLE_HOME -name "*.ora" | xargs sha256sum > config_20190123.txt